import Foundation
import AVFoundation

/// Gemini Live API service for real-time audio conversations
/// Uses WebSocket streaming for unlimited quota and instant responses
final class GeminiLiveService: NSObject {
    
    static let shared = GeminiLiveService()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var audioStreamTask: Task<Void, Never>?
    private var responseStreamTask: Task<Void, Never>?
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
    
    private override init() {
        super.init()
    }
    
    /// Connect to Gemini Live API
    func connect() async throws {
        guard let apiKey = GeminiLiveConfig.apiKey else {
            throw GeminiLiveError.missingAPIKey
        }
        
        let wsURL = GeminiLiveConfig.webSocketURL + "?key=" + apiKey
        guard let url = URL(string: wsURL) else {
            throw GeminiLiveError.invalidURL(wsURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        isStreaming = true
        
        // Send initial setup
        try await sendSetupMessage()
        
        // Start listening for responses
        startListeningForResponses()
        
        onConnected?()
    }
    
    /// Disconnect from Gemini Live API
    func disconnect() {
        isStreaming = false
        audioStreamTask?.cancel()
        responseStreamTask?.cancel()
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
            mediaChunk: GeminiMediaChunk(
                mimeType: "audio/pcm;rate=\(sampleRate)",
                data: audioData.base64EncodedString()
            )
        )
        
        let jsonData = try JSONEncoder.geminiLive.encode(message)
        try await webSocketTask.send(.string(String(data: jsonData, encoding: .utf8)!))
    }
    
    /// Send text message
    func sendTextMessage(_ text: String) async throws {
        guard isStreaming, let webSocketTask = webSocketTask else {
            throw GeminiLiveError.notConnected
        }
        
        let message = GeminiLiveMessage.clientContent(
            content: GeminiContent(
                parts: [GeminiPart(text: text)]
            )
        )
        
        let jsonData = try JSONEncoder.geminiLive.encode(message)
        try await webSocketTask.send(.string(String(data: jsonData, encoding: .utf8)!))
    }
    
    /// End current turn (triggers response)
    func endTurn() async throws {
        guard isStreaming, let webSocketTask = webSocketTask else {
            throw GeminiLiveError.notConnected
        }
        
        let message = GeminiLiveMessage.clientContent(
            content: GeminiContent(
                parts: [],
                role: "user"
            )
        )
        
        let jsonData = try JSONEncoder.geminiLive.encode(message)
        try await webSocketTask.send(.string(String(data: jsonData, encoding: .utf8)!))
    }
    
    // MARK: - Private
    
    private func sendSetupMessage() async throws {
        guard let webSocketTask = webSocketTask else { return }
        
        let systemInstruction = GeminiContent(
            parts: [GeminiPart(text: GeminiLiveConfig.systemPrompt)],
            role: "system"
        )
        
        let setup = GeminiLiveMessage.setup(
            setupContent: GeminiLiveSetupContent(
                model: "models/\(GeminiLiveConfig.modelName)",
                systemInstruction: systemInstruction,
                generationConfig: GeminiLiveGenerationConfig(
                    responseModalities: ["TEXT"]
                )
            )
        )
        
        let jsonData = try JSONEncoder.geminiLive.encode(setup)
        try await webSocketTask.send(.string(String(data: jsonData, encoding: .utf8)!))
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
            let response = try JSONDecoder.geminiLive.decode(GeminiLiveResponse.self, from: data)
            
            switch response {
            case .serverContent(let serverContent):
                if let text = serverContent.modelTurn?.parts.first?.text {
                    onTextResponse?(text)
                }
                
                if serverContent.turnComplete == true {
                    // Response is complete
                }
                
            case .toolCall:
                break
            case .toolCallCancellation:
                break
            case .setupComplete:
                break
            case .unknown:
                break
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
        Task { @MainActor in
            self.onDisconnected?()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("🐾 [LiveAPI] WebSocket connected")
    }
}

// MARK: - Errors
enum GeminiLiveError: LocalizedError {
    case missingAPIKey
    case invalidURL(String)
    case notConnected
    case unexpectedDataType
    case unknownMessageType
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing Gemini API key"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
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
        Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
    }
    
    static let modelName = "gemini-2.5-flash"
    static let webSocketURL = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent"
    
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
