import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Talk Session State

enum TalkSessionState: Equatable {
    case idle          // "Tap to talk"
    case listening     // mic active, recording
    case thinking      // sent to backend, waiting
    case responding    // TTS playing back
    case error(String)
}

// MARK: - View Model

@MainActor
final class PetTalkSessionViewModel: NSObject, ObservableObject {

    // MARK: Published

    @Published var sessionState: TalkSessionState = .idle
    @Published var transcription: String = ""
    @Published var petResponse: String = ""
    @Published var audioLevel: Float = 0          // 0-1, drives blob scale
    @Published var isSessionOpen: Bool = false

    // MARK: Private – speech infra

    private lazy var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private lazy var audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()

    // MARK: Private – permissions

    private var micPermissionGranted = false
    private var speechPermissionGranted = false

    // MARK: Injected

    private let petViewModel: PetViewModel

    // MARK: Init

    init(petViewModel: PetViewModel) {
        self.petViewModel = petViewModel
        super.init()
        speechSynthesizer.delegate = self
        setupAudioNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    func openSession() {
        isSessionOpen = true
        sessionState = .idle
        transcription = ""
        petResponse = ""
        requestPermissions()
    }

    func closeSession() {
        stopRecording()
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSessionOpen = false
        sessionState = .idle
        audioLevel = 0
    }

    func toggleMic() {
        switch sessionState {
        case .listening:
            stopRecording()
        case .idle:
            startRecording()
        default:
            break
        }
    }

    // MARK: - Permissions

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.speechPermissionGranted = status == .authorized
                self?.checkPermissionsReady()
            }
        }

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.micPermissionGranted = granted
                    self?.checkPermissionsReady()
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.micPermissionGranted = granted
                    self?.checkPermissionsReady()
                }
            }
        }
    }

    private func checkPermissionsReady() {
        if !micPermissionGranted || !speechPermissionGranted { return }
        // Nothing to do – user taps mic when ready
    }

    // MARK: - Recording

    private func startRecording() {
        guard verify() else { return }

        // Cancel stale task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement,
                                         options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            if let inputs = audioSession.availableInputs,
               let preferred = inputs.first(where: { $0.portType == .builtInMic }) ?? inputs.first {
                try audioSession.setPreferredInput(preferred)
            }
        } catch {
            sessionState = .error("Audio session error")
            return
        }

        // Recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else {
            sessionState = .error("Could not create recognition request")
            return
        }
        req.shouldReportPartialResults = true

        // Audio engine tap
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0 && format.channelCount > 0 else {
            sessionState = .error("No audio input available")
            return
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            req.append(buffer)
            self?.processAudioLevel(buffer: buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            sessionState = .error("Audio engine failed")
            inputNode.removeTap(onBus: 0)
            return
        }

        // Recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let result {
                    self.transcription = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }

        sessionState = .listening
        transcription = ""
        petResponse = ""
    }

    private func stopRecording() {
        guard sessionState == .listening else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        self.audioLevel = 0

        let captured = transcription
        if captured.isEmpty || captured == "Listening…" {
            sessionState = .idle
        } else {
            sendToBackend(text: captured)
        }
    }

    private func verify() -> Bool {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            sessionState = .error("Speech permission required")
            return false
        }
        let micOK: Bool
        if #available(iOS 17.0, *) {
            micOK = AVAudioApplication.shared.recordPermission == .granted
        } else {
            micOK = AVAudioSession.sharedInstance().recordPermission == .granted
        }
        guard micOK else {
            sessionState = .error("Microphone permission required")
            return false
        }
        guard let rec = speechRecognizer, rec.isAvailable else {
            sessionState = .error("Speech recognizer unavailable")
            return false
        }
        return true
    }

    // MARK: - Backend

    private func sendToBackend(text: String) {
        sessionState = .thinking
        Task {
            do {
                let (response, _, _) = try await petViewModel.sendMessage(text)
                await MainActor.run {
                    self.petResponse = response
                    self.sessionState = .responding
                    self.speak(response)
                }
            } catch {
                await MainActor.run {
                    self.petResponse = "Hmm, something went wrong."
                    self.sessionState = .idle
                }
            }
        }
    }

    // MARK: - TTS

    private func speak(_ text: String) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { /* non-fatal */ }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.2
        speechSynthesizer.speak(utterance)
    }

    // MARK: - Audio Level

    private func processAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<count { sum += abs(data[i]) }
        let level = min((sum / Float(count)) * 10, 1.0)
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = level
        }
    }

    // MARK: - Notifications

    private func setupAudioNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeVal),
              type == .began, sessionState == .listening else { return }
        DispatchQueue.main.async { self.stopRecording() }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension PetTalkSessionViewModel: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.sessionState = .idle
        }
    }
}
