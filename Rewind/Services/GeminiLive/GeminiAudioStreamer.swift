import Foundation
import AVFoundation

/// Handles audio capture and streaming to Gemini Live API
@MainActor
final class GeminiAudioStreamer {
    
    private let liveService: GeminiLiveService
    private var audioEngine: AVAudioEngine?
    private var isStreaming = false
    
    // Audio configuration
    private let sampleRate: Double = 16000
    private let channels: UInt32 = 1
    
    init(liveService: GeminiLiveService? = nil) {
        self.liveService = liveService ?? .shared
    }
    
    /// Start streaming audio from microphone
    func startStreaming() async throws {
        guard !isStreaming else { return }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // Create format for 16kHz mono
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: true
        ) else {
            throw GeminiAudioError.unsupportedFormat
        }
        
        // Create converter
        guard let converter = AVAudioConverter(from: format, to: targetFormat) else {
            throw GeminiAudioError.conversionFailed
        }
        
        let bufferSize: UInt32 = 1024
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self = self, self.isStreaming else { return }
            
            // Convert to 16kHz mono PCM
            guard let convertedBuffer = self.convertBuffer(buffer, using: converter, to: targetFormat) else {
                return
            }
            
            // Convert to PCM16 data
            let pcmData = self.convertToPCM16Data(convertedBuffer)
            
            // Send to Gemini Live API
            Task {
                do {
                    try await self.liveService.sendAudioData(pcmData)
                } catch {
                    print("🐾 [Audio] Failed to send audio: \(error)")
                }
            }
        }
        
        try engine.start()
        audioEngine = engine
        isStreaming = true
    }
    
    /// Stop streaming audio
    func stopStreaming() {
        isStreaming = false
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
    }
    
    // MARK: - Private
    
    private func convertBuffer(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter,
        to targetFormat: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let frameCount = buffer.frameLength
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(frameCount) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCount
        ) else {
            return nil
        }
        
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        converter.convert(
            to: outputBuffer,
            error: &error,
            withInputFrom: inputBlock
        )
        
        if let error = error {
            print("🐾 [Audio] Conversion error: \(error)")
            return nil
        }
        
        return outputBuffer
    }
    
    private func convertToPCM16Data(_ buffer: AVAudioPCMBuffer) -> Data {
        guard let channelData = buffer.int16ChannelData?[0] else {
            return Data()
        }
        
        let frameLength = Int(buffer.frameLength)
        let stride = buffer.stride
        var data = Data(capacity: frameLength * 2)
        
        for frame in 0..<frameLength {
            let sample = channelData.advanced(by: frame * stride).pointee
            data.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Data($0) })
        }
        
        return data
    }
}

// MARK: - Errors
enum GeminiAudioError: LocalizedError {
    case unsupportedFormat
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Unsupported audio format"
        case .conversionFailed:
            return "Audio conversion failed"
        }
    }
}
