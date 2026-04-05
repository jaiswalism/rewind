import SwiftUI
import AVFoundation
import Speech
import Combine

@MainActor
final class VoiceRecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var transcriptionText = ""
    @Published var statusLabel = "Ready"

    @Published var waveformHeights: [CGFloat] = Array(repeating: 8, count: 18)
    private var recordingURL: URL?
    private var audioFile: AVAudioFile?
    private var animationTimer: Timer?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    /// Matches Pet Talk: keep the session warm while this sheet is open so repeat record/stop is fast. Deactivate only in `tearDownAudioSession()` (sheet dismiss).
    private var audioSessionActivated = false

    /// Call from `onAppear` so the first tap only starts the engine + file (same idea as Pet Talk pre-opening the session).
    func warmUpAudioSession() {
        guard !audioSessionActivated else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            audioSessionActivated = true
            if let availableInputs = session.availableInputs, !availableInputs.isEmpty {
                let preferredInput = availableInputs.first { $0.portType == .builtInMic } ?? availableInputs.first
                if let input = preferredInput {
                    try session.setPreferredInput(input)
                }
            }
        } catch {
            audioSessionActivated = false
        }
    }

    func tearDownAudioSession() {
        stopRecording()
        recordingURL = nil
        transcriptionText = ""
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        audioSessionActivated = false
        statusLabel = "Ready"
    }

    func startRecording() {
        statusLabel = "Starting…"

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if isRecording {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioFile = nil

        let fileName = "voice_journal_\(Int(Date().timeIntervalSince1970)).m4a"
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent(fileName)

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            audioSessionActivated = true

            if let availableInputs = audioSession.availableInputs, !availableInputs.isEmpty {
                let preferredInput = availableInputs.first { $0.portType == .builtInMic } ?? availableInputs.first
                if let input = preferredInput {
                    try audioSession.setPreferredInput(input)
                }
            }

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
                statusLabel = "No microphone available"
                return
            }

            do {
                audioFile = try AVAudioFile(forWriting: fileURL, settings: recordingFormat.settings)
            } catch {
                statusLabel = "Could not create audio file"
                return
            }

            recordingURL = fileURL

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true

            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let recorder = self else { return }
                recorder.recognitionRequest?.append(buffer)
                do {
                    try recorder.audioFile?.write(from: buffer)
                } catch {
                    // Best-effort
                }
                recorder.updateWaveform(buffer: buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            transcriptionText = ""
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, _ in
                guard let recorder = self else { return }
                if let result = result {
                    Task { @MainActor in
                        recorder.transcriptionText = result.bestTranscription.formattedString
                    }
                }
            }

            isRecording = true
            statusLabel = "Listening..."
            startWaveformAnimation()
        } catch {
            audioFile = nil
            recordingURL = nil
            statusLabel = "Error: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if isRecording {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        audioFile = nil

        // Do not deactivate the session here — Pet Talk keeps it live between takes; full reactivation was causing 2–3s delay on the next start.

        isRecording = false
        statusLabel = "Ready"
        stopWaveformAnimation()
        resetWaveform()
    }
    
    private func updateWaveform(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataValue = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        
        let sum = channelDataValue.reduce(0) { $0 + $1 * $1 }
        let rms = sqrt(sum / Float(buffer.frameLength))
        var avgPower = 20 * log10(rms)
        
        if avgPower.isNaN || avgPower.isInfinite {
            avgPower = -160
        }
        
        Task { @MainActor in
            self.animateWaveform(power: avgPower)
        }
    }

    private func animateWaveform(power: Float) {
        let minDb: Float = -60
        let clampedPower = max(minDb, min(0, power))
        let normalized = CGFloat(clampedPower - minDb) / CGFloat(abs(minDb))
        let heightMultiplier = normalized * 85 + 8
        waveformHeights.removeFirst()
        let randomVariation = CGFloat.random(in: 0.7...1.3)
        let newHeight = max(8, min(100, heightMultiplier * randomVariation))
        waveformHeights.append(newHeight)
    }
    
    private func startWaveformAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            // Audio tap drives bars; timer kept for optional future use.
        }
    }
    
    private func stopWaveformAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func resetWaveform() {
        waveformHeights = Array(repeating: 8, count: 18)
    }
    
    func getRecordingURL() -> URL? {
        recordingURL
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { _ in }
            }
        }
    }
}

struct VoiceRecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = VoiceRecordingViewModel()
    
    @State private var isSaving = false
    
    // Callbacks
    var onSave: (String, URL?) -> Void = { _, _ in }
    
    private var bgColor: Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.10, blue: 0.30)
            : Color.white
    }
    
    private var accentBlue: Color {
        Color(red: 0.38, green: 0.38, blue: 1.0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Voice Journal")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Record and save your thoughts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary.opacity(0.72))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(UIColor.tertiarySystemFill))
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 14)
            .background(Color(UIColor.secondarySystemBackground))

            // Content
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("Say anything that's on your mind!")
                        .font(.system(size: 26, weight: .bold))
                        .lineLimit(3)
                        .foregroundColor(.primary)

                    if viewModel.isRecording {
                        HStack(alignment: .center, spacing: 3) {
                            ForEach(0..<viewModel.waveformHeights.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(accentBlue)
                                    .frame(width: 4, height: viewModel.waveformHeights[index])
                            }
                        }
                        .frame(height: 90)
                        .padding(.vertical, 16)
                    } else {
                        VStack(spacing: 0) {
                            Spacer()
                            Text("Ready to record")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(height: 90)
                        .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 16) {
                    // Mic Button
                    Button(action: toggleRecording) {
                        Image(systemName: viewModel.isRecording ? "pause.circle.fill" : "microphone.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(accentBlue)
                            .clipShape(Circle())
                    }
                    .disabled(isSaving)

                    // Status
                    Text(viewModel.statusLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)

                    // Action Buttons
                    HStack(spacing: 24) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary.opacity(0.78))
                                .frame(width: 56, height: 56)
                                .background(Color(UIColor.systemBackground))
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                        }
                        .disabled(isSaving)

                        Spacer()

                        Button(action: saveRecording) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(
                                            (isSaving || (viewModel.transcriptionText.isEmpty && viewModel.getRecordingURL() == nil))
                                                ? Color(UIColor.systemGray3)
                                                : accentBlue
                                        )
                                )
                                .clipShape(Circle())
                                .shadow(color: accentBlue.opacity(0.28), radius: 10, y: 4)
                        }
                        .disabled(isSaving || (viewModel.transcriptionText.isEmpty && viewModel.getRecordingURL() == nil))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .background(bgColor)
        .onAppear {
            viewModel.requestPermissions()
            viewModel.warmUpAudioSession()
        }
        .onDisappear {
            viewModel.tearDownAudioSession()
        }
    }
    
    // MARK: - Actions
    private func toggleRecording() {
        if viewModel.isRecording {
            viewModel.stopRecording()
        } else {
            viewModel.startRecording()
        }
    }
    
    private func saveRecording() {
        isSaving = true
        
        Task {
            if viewModel.isRecording {
                viewModel.stopRecording()
            }
            // Allow Speech framework to deliver the final transcription after endAudio.
            try? await Task.sleep(nanoseconds: 250_000_000)
            let transcript = viewModel.transcriptionText
            let url = viewModel.getRecordingURL()
            await MainActor.run {
                onSave(transcript, url)
                isSaving = false
                dismiss()
            }
        }
    }
}

#Preview {
    VoiceRecordingView()
}
