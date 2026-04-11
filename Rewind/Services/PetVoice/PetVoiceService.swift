import Foundation
import AVFoundation

/// Handles real-time voice-to-voice conversations with Gemini Live API.
///
/// Uses a single AVAudioEngine that simultaneously:
///   - Taps the input node to stream mic audio → Gemini (16 kHz PCM)
///   - Plays Gemini's audio responses through a player node → speakers (24 kHz PCM)
///
/// The mic never stops while the session is active. VAD is handled server-side.
@MainActor
final class PetVoiceService: NSObject {

    static let shared = PetVoiceService()

    // MARK: - Callbacks

    /// Called when successfully connected to the proxy
    var onConnected: (() -> Void)?
    /// Called when disconnected
    var onDisconnected: (() -> Void)?
    /// Called with transcription text from Gemini
    var onTranscription: ((String) -> Void)?
    /// Called when Gemini finishes its turn (turnComplete)
    var onResponseComplete: (() -> Void)?
    /// Called with normalised mic RMS level [0...1] on every audio buffer — use for blob animation
    var onAudioLevel: ((Float) -> Void)?
    /// Called when first audio chunk arrives (pet starts speaking)
    var onPetStartedSpeaking: (() -> Void)?
    /// Called with any errors
    var onError: ((Error) -> Void)?

    // MARK: - Private Properties

    private let liveService = GeminiLiveService.shared

    /// Single engine — mic tap lives on inputNode, player lives here too
    private var audioEngine: AVAudioEngine?
    /// Player node for Gemini's audio responses
    private var audioPlayer: AVAudioPlayerNode?
    /// Converter from engine native format → 16kHz mono PCM for upload
    private var micConverter: AVAudioConverter?
    /// Target format for mic upload
    private var micTargetFormat: AVAudioFormat?

    private var isStreaming = false
    private var isPetSpeaking = false
    private var shouldSendMicAudio = true
    private var micSendToken = 0
    private var liveTranscriptBuffer = ""

    // Audio formats
    private let micSampleRate: Double = 16_000
    private let geminiOutputSampleRate: Double = 24_000
    private let channels: AVAudioChannelCount = 1

    private override init() {
        super.init()
    }

    // MARK: - Connection

    func connect() async throws {
        liveService.onConnected = { [weak self] in
            Task { @MainActor in
                guard let self, self.isStreaming else { return }
                self.onConnected?()
            }
        }
        liveService.onDisconnected = { [weak self] in
            Task { @MainActor in
                self?.isStreaming = false
                self?.onDisconnected?()
            }
        }
        liveService.onAudioData = { [weak self] audioData in
            Task { @MainActor in
                guard let self, self.isStreaming else { return }
                if !self.isPetSpeaking {
                    self.isPetSpeaking = true
                    self.shouldSendMicAudio = false
                    self.micSendToken &+= 1
                    self.liveTranscriptBuffer = ""
                    self.onPetStartedSpeaking?()
                }
                self.scheduleAudioChunk(audioData)
            }
        }
        liveService.onTextResponse = { [weak self] text in
            Task { @MainActor in
                guard let self, self.isStreaming else { return }
                self.liveTranscriptBuffer = self.mergeStreamingText(existing: self.liveTranscriptBuffer, fragment: text)
                self.onTranscription?(self.liveTranscriptBuffer)
            }
        }
        liveService.onError = { [weak self] error in
            Task { @MainActor in
                guard let self, self.isStreaming else { return }
                self.onError?(error)
            }
        }

        // Hook into serverContent turnComplete via a separate notification
        // GeminiLiveService already fires onTextResponse for text.
        // We subscribe to turnComplete via the response handler extension below.
        setupTurnCompleteCallback()

        try await liveService.connect()
    }

    func disconnect() {
        stopStreaming()
        liveService.disconnect()
        liveTranscriptBuffer = ""
        shouldSendMicAudio = true
        micSendToken &+= 1
    }

    // MARK: - Streaming

    /// Start continuous mic streaming + audio playback on a single engine.
    func startStreaming() async throws {
        guard !isStreaming else { return }

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Target format for mic → Gemini: 16kHz, mono, Int16
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: micSampleRate,
            channels: channels,
            interleaved: true
        ) else {
            throw PetVoiceError.unsupportedFormat
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw PetVoiceError.conversionFailed
        }

        micTargetFormat = targetFormat
        micConverter = converter

        // Attach a player node for Gemini's audio output
        let player = AVAudioPlayerNode()
        engine.attach(player)

        // Gemini outputs 24kHz mono Int16
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: geminiOutputSampleRate,
            channels: channels,
            interleaved: true
        ) else {
            throw PetVoiceError.playbackSetupFailed
        }

        // Connect player → mainMixerNode using Gemini's output format
        engine.connect(player, to: engine.mainMixerNode, format: outputFormat)

        // Install mic tap — runs on a background audio thread
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self, self.isStreaming else { return }
            self.processMicBuffer(buffer)
        }

        try engine.start()
        player.play()

        audioEngine = engine
        audioPlayer = player
        isStreaming = true

        print("🐾 [PetVoice] Engine started — single engine for mic + playback")
    }

    func stopStreaming() {
        guard isStreaming else { return }
        isStreaming = false
        isPetSpeaking = false
        shouldSendMicAudio = true
        micSendToken &+= 1
        liveTranscriptBuffer = ""
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioPlayer?.stop()
        audioEngine?.stop()
        audioEngine = nil
        audioPlayer = nil
        micConverter = nil
        micTargetFormat = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        print("🐾 [PetVoice] Engine stopped")
    }

    // MARK: - Text Chat

    func sendTextMessage(_ text: String) async throws {
        try await liveService.sendTextMessage(text)
    }

    // MARK: - Private — Mic Processing

    /// Converts mic buffer to 16kHz PCM and streams it to Gemini. Fires onAudioLevel.
    private func processMicBuffer(_ buffer: AVAudioPCMBuffer) {
        // Compute RMS for blob animation
        let level = rmsLevel(buffer)
        Task { @MainActor in
            self.onAudioLevel?(level)
        }

        guard shouldSendMicAudio else { return }
                let currentMicSendToken = micSendToken

        // Convert to 16kHz mono PCM16
        guard let converter = micConverter,
              let targetFormat = micTargetFormat,
              let converted = convertBuffer(buffer, using: converter, to: targetFormat) else { return }

        let pcmData = pcm16Data(from: converted)
        guard !pcmData.isEmpty else { return }

        Task {
            guard self.isStreaming,
                  self.shouldSendMicAudio,
                  self.micSendToken == currentMicSendToken else { return }
            do {
                try await self.liveService.sendAudioData(pcmData)
            } catch {
                print("🐾 [PetVoice] Send audio error: \(error)")
            }
        }
    }

    // MARK: - Private — Playback

    /// Schedules a raw PCM16 24kHz chunk onto the player node immediately.
    private func scheduleAudioChunk(_ data: Data) {
        guard let player = audioPlayer,
              let buffer = pcmBuffer(from: data) else { return }

        player.scheduleBuffer(buffer, completionCallbackType: .dataConsumed) { [weak self] _ in
            // Check if queue is now empty (pet finished speaking)
            Task { @MainActor in
                guard let self else { return }
                // Small delay — if no new audio arrives, consider the response done
                try? await Task.sleep(nanoseconds: 200_000_000)
                if self.isPetSpeaking {
                    self.isPetSpeaking = false
                    self.shouldSendMicAudio = true
                    self.micSendToken &+= 1
                    self.onResponseComplete?()
                }
            }
        }

        if !player.isPlaying {
            player.play()
        }
    }

    // MARK: - Private — Turn Complete

    private func setupTurnCompleteCallback() {
        GeminiLiveService.onTurnComplete = { [weak self] in
            Task { @MainActor in
                guard let self, self.isStreaming else { return }
                // Give a tiny grace period for any last audio to arrive
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard self.isStreaming else { return }
                self.isPetSpeaking = false
                self.shouldSendMicAudio = true
                self.micSendToken &+= 1
                self.onResponseComplete?()
            }
        }
    }

    private func mergeStreamingText(existing: String, fragment: String) -> String {
        guard !fragment.isEmpty else { return existing }
        guard !existing.isEmpty else { return fragment }

        if existing.hasPrefix(fragment) {
            return existing
        }

        if fragment.hasPrefix(existing) {
            return fragment
        }

        if existing.last?.isWhitespace == true || fragment.first?.isWhitespace == true {
            return existing + fragment
        }

        if existing.last?.isPunctuation == true || fragment.first?.isPunctuation == true {
            return existing + fragment
        }

        return existing + " " + fragment
    }

    // MARK: - Private — Audio Conversion

    private func rmsLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let length = Int(buffer.frameLength)
        guard length > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<length { sum += channelData[i] * channelData[i] }
        return min(sqrt(sum / Float(length)) * 8, 1.0)
    }

    private func convertBuffer(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter,
        to targetFormat: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard outputFrameCount > 0,
              let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCount) else { return nil }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        converter.convert(to: output, error: &error, withInputFrom: inputBlock)
        if let error { print("🐾 [PetVoice] Conversion error: \(error)"); return nil }
        return output
    }

    private func pcm16Data(from buffer: AVAudioPCMBuffer) -> Data {
        guard let channelData = buffer.int16ChannelData?[0] else { return Data() }
        let frameLength = Int(buffer.frameLength)
        let stride = buffer.stride
        var data = Data(capacity: frameLength * 2)
        for frame in 0..<frameLength {
            let sample = channelData.advanced(by: frame * stride).pointee
            withUnsafeBytes(of: sample.littleEndian) { data.append(contentsOf: $0) }
        }
        return data
    }

    private func pcmBuffer(from data: Data) -> AVAudioPCMBuffer? {
        let frameCount = data.count / 2  // Int16 = 2 bytes per sample
        guard frameCount > 0,
              let format = AVAudioFormat(
                  commonFormat: .pcmFormatInt16,
                  sampleRate: geminiOutputSampleRate,
                  channels: channels,
                  interleaved: true
              ),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        data.withUnsafeBytes { raw in
            if let src = raw.baseAddress {
                memcpy(buffer.int16ChannelData![0], src, data.count)
            }
        }
        return buffer
    }
}

// MARK: - Errors

enum PetVoiceError: LocalizedError {
    case unsupportedFormat
    case conversionFailed
    case playbackSetupFailed
    case notConnected

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: return "Unsupported audio format"
        case .conversionFailed: return "Audio conversion failed"
        case .playbackSetupFailed: return "Audio playback setup failed"
        case .notConnected: return "Not connected to Gemini"
        }
    }
}
