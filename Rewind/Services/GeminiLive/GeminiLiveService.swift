import Foundation
import AVFoundation

/// Pet talking websocket client for real-time audio conversations.
/// The Gemini API key stays on the server; the app only connects to the talking service.
final class GeminiLiveService: NSObject {
    
    static let shared = GeminiLiveService()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var audioStreamTask: Task<Void, Never>?
    private var responseStreamTask: Task<Void, Never>?
    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var isStreaming = false
    
    // Audio configuration
    private let sampleRate: Double = 16000
    private let channels: UInt32 = 1
    private let bitsPerSample: UInt32 = 16
    
    // Callbacks
    var onTextResponse: ((String) -> Void)?
    var onAudioData: ((Data) -> Void)?
    var onError: ((Error) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    /// Fires when Gemini signals the end of its turn (server-side VAD turnComplete).
    /// PetVoiceService subscribes to this to know when the pet has finished speaking.
    static var onTurnComplete: (() -> Void)?
    
    private override init() {
        super.init()
    }
    
    /// Connect to Gemini Live API
    func connect() async throws {
        guard let wsURL = GeminiLiveConfig.webSocketURL(apiKey: GeminiLiveConfig.apiKey),
              let url = URL(string: wsURL) else {
            throw GeminiLiveError.invalidURL(GeminiLiveConfig.serviceURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        webSocketTask = session.webSocketTask(with: request)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connectContinuation = continuation
            isStreaming = true
            webSocketTask?.resume()
        }
    }
    
    /// Disconnect from Gemini Live API
    func disconnect() {
        isStreaming = false
        audioStreamTask?.cancel()
        responseStreamTask?.cancel()
        connectContinuation?.resume(throwing: GeminiLiveError.notConnected)
        connectContinuation = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        onDisconnected?()
    }
    
    /// Send audio data to Gemini
    func sendAudioData(_ audioData: Data) async throws {
        guard isStreaming, let webSocketTask = webSocketTask else {
            throw GeminiLiveError.notConnected
        }
        
        // Wrap audio in Gemini Live API format
        let message = GeminiLiveMessage.realtimeInput(
            input: GeminiRealtimeInput(
                audio: GeminiBlob(
                    mimeType: "audio/pcm;rate=\(Int(sampleRate))",
                    data: audioData.base64EncodedString()
                )
            )
        )
        
        let jsonData = try JSONEncoder.geminiLive.encode(message)
        guard let messageString = String(data: jsonData, encoding: .utf8) else {
            throw GeminiLiveError.connectionFailed
        }
        try await webSocketTask.send(.string(messageString))
    }
    
    /// Send text message
    func sendTextMessage(_ text: String) async throws {
        guard isStreaming, let webSocketTask = webSocketTask else {
            throw GeminiLiveError.notConnected
        }

        // Use correct format: clientContent with turns array
        let message: [String: Any] = [
            "clientContent": [
                "turns": [
                    ["role": "user", "parts": [["text": text]]]
                ],
                "turnComplete": true
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: message)
        let jsonStr = String(data: jsonData, encoding: .utf8)!
        try await webSocketTask.send(.string(jsonStr))
    }

    /// End current turn (triggers response)
    func endTurn() async throws {
        guard isStreaming, let webSocketTask = webSocketTask else {
            throw GeminiLiveError.notConnected
        }

        // Send empty turn with turnComplete
        let message: [String: Any] = [
            "clientContent": [
                "turns": [],
                "turnComplete": true
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: message)
        let jsonStr = String(data: jsonData, encoding: .utf8)!
        try await webSocketTask.send(.string(jsonStr))
    }
    
    // MARK: - Private
    
    private func sendSetupMessage() async throws {
        guard let webSocketTask = webSocketTask else { return }

        // BidiGenerateContentSetup proto spec — outer key is "setup", responseModalities
        // lives inside generationConfig. The relay server forwards this to Gemini v1beta.
        let setup: [String: Any] = [
            "setup": [
                "model": "models/\(GeminiLiveConfig.modelName)",
                "generationConfig": [
                    "responseModalities": ["AUDIO"]
                ],
                "systemInstruction": [
                    "parts": [["text": GeminiLiveConfig.systemPrompt]]
                ]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: setup)
        let jsonStr = String(data: jsonData, encoding: .utf8)!
        try await webSocketTask.send(.string(jsonStr))
    }
    
    private func startListeningForResponses() {
        responseStreamTask = Task { [weak self] in
            guard let self = self else { return }
            
            while self.isStreaming, !Task.isCancelled {
                do {
                    let message = try await self.receiveWebSocketMessage()
                    await self.handleResponseMessage(message)
                } catch {
                    if !Task.isCancelled {
                        self.onError?(error)
                    }
                    break
                }
            }
        }
    }
    
    private func receiveWebSocketMessage() async throws -> String {
        guard let webSocketTask = webSocketTask else {
            throw GeminiLiveError.notConnected
        }
        
        let message = try await webSocketTask.receive()
        
        switch message {
        case .string(let text):
            return text
        case .data:
            throw GeminiLiveError.unexpectedDataType
        @unknown default:
            throw GeminiLiveError.unknownMessageType
        }
    }
    
    @MainActor
    private func handleResponseMessage(_ message: String) async {
        guard let data = message.data(using: .utf8) else { return }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            // Check for setupComplete
            if json?["setupComplete"] != nil {
                print("🐾 [LiveAPI] Setup complete")
                if let continuation = self.connectContinuation {
                    self.connectContinuation = nil
                    continuation.resume()
                }
                self.onConnected?()
                return
            }

            // Check for serverContent
            if let serverContent = json?["serverContent"] as? [String: Any] {
                // Check for turnComplete (server-side VAD fired — pet finished speaking)
                if serverContent["turnComplete"] as? Bool == true {
                    print("🐾 [LiveAPI] Turn complete")
                    GeminiLiveService.onTurnComplete?()
                }

                // Check for generationComplete
                if serverContent["generationComplete"] as? Bool == true {
                    print("🐾 [LiveAPI] Generation complete")
                    return
                }

                // Check for modelTurn
                if let modelTurn = serverContent["modelTurn"] as? [String: Any],
                   let parts = modelTurn["parts"] as? [[String: Any]] {
                    for part in parts {
                        // Check for text (including thought)
                        if let text = part["text"] as? String {
                            let isThought = part["thought"] as? Bool ?? false
                            if !isThought {
                                onTextResponse?(text)
                            }
                        }

                        // Check for audio data
                        if let inlineData = part["inlineData"] as? [String: Any],
                           let mimeType = inlineData["mimeType"] as? String,
                           let audioData = inlineData["data"] as? String,
                           mimeType.hasPrefix("audio/"),
                           let audioBytes = Data(base64Encoded: audioData) {
                            onAudioData?(audioBytes)
                        }
                    }
                }
            }
        } catch {
            // Log but don't fail on parsing errors
            print("🐾 [LiveAPI] Failed to parse response: \(error)")
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension GeminiLiveService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isStreaming = false
        if let continuation = connectContinuation {
            connectContinuation = nil
            continuation.resume(throwing: GeminiLiveError.notConnected)
        }
        Task { @MainActor in
            self.onDisconnected?()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("🐾 [LiveAPI] WebSocket connected")
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.sendSetupMessage()
                self.startListeningForResponses()
            } catch {
                self.connectContinuation?.resume(throwing: error)
                self.connectContinuation = nil
                self.onError?(error)
            }
        }
    }
}

// MARK: - Errors
enum GeminiLiveError: LocalizedError {
    case missingAPIKey
    case invalidURL(String)
    case connectionFailed
    case notConnected
    case unexpectedDataType
    case unknownMessageType
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing Gemini API key"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .connectionFailed:
            return "Connection failed"
        case .notConnected:
            return "Not connected to Gemini"
        case .unexpectedDataType:
            return "Unexpected data type"
        case .unknownMessageType:
            return "Unknown message type"
        }
    }
}

// MARK: - Config
enum GeminiLiveConfig {
    static var apiKey: String? {
        normalizedInfoValue(for: "PET_TALKING_API_KEY") ?? "rewind-pet-2026-secure-key"
    }

    static var serviceURL: String {
        normalizedInfoValue(for: "PET_TALKING_SERVICE_URL") ?? "wss://api.rewind.shyamjaiswal.in/ws"
    }

    static func webSocketURL(apiKey: String?) -> String? {
        guard var components = URLComponents(string: serviceURL) else {
            return nil
        }

        if let apiKey, !apiKey.isEmpty {
            var queryItems = components.queryItems ?? []
            queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
            components.queryItems = queryItems
        }

        return components.string
    }

    private static func normalizedInfoValue(for key: String) -> String? {
        guard let rawValue = Bundle.main.infoDictionary?[key] as? String else {
            return nil
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else {
            return nil
        }
        return trimmed
    }

    // gemini-3.1-flash-live-preview is the current recommended live model (Apr 2026).
    // Fallback: gemini-2.5-flash-native-audio-preview-12-2025
    static let modelName = "gemini-3.1-flash-live-preview"
    
    static let systemPrompt = """
    You are a calm virtual companion in a wellness app. Be warm, empathetic, and conversational.
    Respond with 2-4 complete sentences. Always acknowledge feelings first, then offer gentle support.
    Never use medical terms or clinical language. Never use absolutes like "always" or "never".
    Make sure every sentence is complete and ends with proper punctuation.
    """
}

// MARK: - JSON Encoder/Decoder
extension JSONEncoder {
    static let geminiLive: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

extension JSONDecoder {
    static let geminiLive: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
