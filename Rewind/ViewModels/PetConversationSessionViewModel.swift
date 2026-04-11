import Foundation
import AVFoundation
import Combine

enum PetConversationMode: String, CaseIterable, Identifiable {
    case live
    case type

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: return "Live"
        case .type: return "Type"
        }
    }
}

enum PetConversationMessageRole: Equatable {
    case user
    case pet
}

struct PetConversationMessage: Identifiable, Equatable {
    let id = UUID()
    let role: PetConversationMessageRole
    let text: String
}

enum PetConversationState: Equatable {
    case idle
    case connecting
    case listening
    case responding
    case sending
    case error(String)
}

@MainActor
final class PetConversationSessionViewModel: NSObject, ObservableObject {

    @Published var mode: PetConversationMode = .live
    @Published var liveState: PetConversationState = .idle
    @Published var liveAudioLevel: Float = 0
    @Published var liveReplyText: String = ""
    @Published var typedMessage: String = ""
    @Published var typedState: PetConversationState = .idle
    @Published var typedMessages: [PetConversationMessage] = []

    private let petViewModel: PetViewModel
    private let voiceService = PetVoiceService.shared

    init(petViewModel: PetViewModel) {
        self.petViewModel = petViewModel
        super.init()
        configureVoiceCallbacks()
    }

    func openSession() {
        liveState = .idle
        liveAudioLevel = 0
        liveReplyText = ""
        typedMessage = ""
        typedMessages.removeAll()
        typedState = .idle
    }

    func closeSession() {
        stopLiveSession()
        typedMessage = ""
        typedState = .idle
        liveReplyText = ""
        liveAudioLevel = 0
    }

    func selectMode(_ newMode: PetConversationMode) {
        guard mode != newMode else { return }
        mode = newMode
        if newMode == .type {
            stopLiveSession()
        }
    }

    func toggleLiveSession() {
        switch liveState {
        case .connecting:
            return
        case .listening, .responding:
            stopLiveSession()
        default:
            Task { await startLiveSession() }
        }
    }

    func submitTypedMessage() {
        let message = typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        if case .sending = typedState { return }

        typedMessages.append(PetConversationMessage(role: .user, text: message))
        typedMessage = ""
        typedState = .sending

        Task {
            do {
                let response = try await petViewModel.sendMessage(message)
                await MainActor.run {
                    self.typedMessages.append(PetConversationMessage(role: .pet, text: response.response))
                    self.typedState = .idle
                }
            } catch {
                print("[PetConversation] Typed message failed: \(error)")
                await MainActor.run {
                    self.typedState = .error("Could not send your message right now.")
                    self.typedMessage = message
                }
            }
        }
    }

    var liveStatusText: String {
        switch liveState {
        case .idle: return "Ready for a live conversation"
        case .connecting: return "Connecting to live session..."
        case .listening: return "Listening live"
        case .responding: return "Pet is speaking"
        case .sending: return ""
        case .error(let message): return message
        }
    }

    var liveActionTitle: String {
        switch liveState {
        case .listening, .responding: return "Stop live"
        case .connecting: return "Connecting..."
        case .error: return "Retry live"
        default: return "Start live"
        }
    }

    var canSendTypedMessage: Bool {
        switch typedState {
        case .sending:
            return false
        default:
            return !typedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var typedStatusText: String {
        switch typedState {
        case .idle: return "Type a message and send it"
        case .sending: return "Sending to your pet..."
        case .error(let message): return message
        case .connecting, .listening, .responding:
            return ""
        }
    }

    private func startLiveSession() async {
        guard mode == .live else { return }
        guard liveState != .connecting, liveState != .listening, liveState != .responding else { return }

        liveState = .connecting
        liveReplyText = ""
        liveAudioLevel = 0

        guard await requestMicrophonePermission() else {
            liveState = .error("Microphone permission required")
            return
        }

        do {
            try await voiceService.connect()
            try await voiceService.startStreaming()
            liveState = .listening
        } catch {
            print("[PetConversation] Live session failed: \(error)")
            stopLiveSession()
            liveState = .error(userFacingLiveError(error))
        }
    }

    private func stopLiveSession() {
        voiceService.disconnect()
        liveAudioLevel = 0
        liveState = .idle
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func configureVoiceCallbacks() {
        voiceService.onConnected = { [weak self] in
            guard let self, self.mode == .live else { return }
            self.liveState = .listening
        }

        voiceService.onDisconnected = { [weak self] in
            guard let self else { return }
            self.liveAudioLevel = 0
            if case .error = self.liveState {
                return
            }
            self.liveState = .idle
        }

        voiceService.onTranscription = { [weak self] text in
            self?.liveReplyText = text
        }

        voiceService.onResponseComplete = { [weak self] in
            guard let self, self.mode == .live else { return }
            self.liveState = .listening
            self.liveAudioLevel = 0
        }

        voiceService.onAudioLevel = { [weak self] level in
            self?.liveAudioLevel = level
        }

        voiceService.onPetStartedSpeaking = { [weak self] in
            guard let self, self.mode == .live else { return }
            self.liveState = .responding
        }

        voiceService.onError = { [weak self] error in
            guard let self else { return }
            print("[PetConversation] Live service error: \(error)")
            self.liveState = .error(self.userFacingLiveError(error))
        }
    }

    private func userFacingLiveError(_ error: Error) -> String {
        if error is GeminiLiveError || error is PetVoiceError {
            return "Live conversation is unavailable right now."
        }
        return "Live conversation failed. Please try again."
    }
}
