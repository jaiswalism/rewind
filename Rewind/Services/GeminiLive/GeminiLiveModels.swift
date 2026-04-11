import Foundation

// MARK: - Gemini Live API Message Types

/// Outgoing messages from client to Gemini
enum GeminiLiveMessage: Codable {
    case setup(setupContent: GeminiLiveSetupContent)
    case clientContent(content: GeminiContent)
    case realtimeInput(input: GeminiRealtimeInput)
    case toolResponse(toolResponse: GeminiToolResponse)
    
    enum CodingKeys: String, CodingKey {
        case setup
        case clientContent
        case realtimeInput
        case toolResponse
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .setup(let setupContent):
            try container.encode(setupContent, forKey: .setup)
        case .clientContent(let content):
            try container.encode(content, forKey: .clientContent)
        case .realtimeInput(let input):
            try container.encode(input, forKey: .realtimeInput)
        case .toolResponse(let toolResponse):
            try container.encode(toolResponse, forKey: .toolResponse)
        }
    }
}

/// Incoming messages from Gemini to client
enum GeminiLiveResponse: Decodable {
    case serverContent(GeminiServerContent)
    case toolCall(GeminiToolCall)
    case toolCallCancellation(GeminiToolCallCancellation)
    case setupComplete
    case unknown
    
    enum CodingKeys: String, CodingKey {
        case serverContent
        case toolCall
        case toolCallCancellation
        case setupComplete
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let serverContent = try container.decodeIfPresent(GeminiServerContent.self, forKey: .serverContent) {
            self = .serverContent(serverContent)
        } else if let toolCall = try container.decodeIfPresent(GeminiToolCall.self, forKey: .toolCall) {
            self = .toolCall(toolCall)
        } else if let cancellation = try container.decodeIfPresent(GeminiToolCallCancellation.self, forKey: .toolCallCancellation) {
            self = .toolCallCancellation(cancellation)
        } else if container.contains(.setupComplete) {
            self = .setupComplete
        } else {
            self = .unknown
        }
    }
}

// MARK: - Setup Content
struct GeminiLiveSetupContent: Codable {
    let model: String
    let systemInstruction: GeminiContent?
    let generationConfig: GeminiLiveGenerationConfig?
}

struct GeminiLiveGenerationConfig: Codable {
    let responseModalities: [String]?
    
    init(responseModalities: [String]? = nil) {
        self.responseModalities = responseModalities
    }
}

// MARK: - Content & Parts
struct GeminiContent: Codable {
    let parts: [GeminiPart]
    let role: String?
    
    init(parts: [GeminiPart], role: String? = nil) {
        self.parts = parts
        self.role = role
    }
}

struct GeminiPart: Codable {
    let text: String?
    let inlineData: GeminiInlineData?
    
    init(text: String) {
        self.text = text
        self.inlineData = nil
    }
    
    init(inlineData: GeminiInlineData) {
        self.text = nil
        self.inlineData = inlineData
    }
}

struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String
}

// MARK: - Realtime Input
struct GeminiRealtimeInput: Codable {
    let audio: GeminiBlob
}

struct GeminiBlob: Codable {
    let mimeType: String
    let data: String
}

// MARK: - Server Content
struct GeminiServerContent: Decodable {
    let modelTurn: GeminiContent?
    let turnComplete: Bool?
    let interruptible: Bool?
    
    enum CodingKeys: String, CodingKey {
        case modelTurn
        case turnComplete
        case interruptible
    }
}

// MARK: - Tool Calls (for future use)
struct GeminiToolCall: Decodable {
    let toolCalls: [GeminiToolFunctionCall]?
}

struct GeminiToolFunctionCall: Decodable {
    let name: String?
    let args: [String: JSONValue]?
}

// MARK: - JSON Value Types

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if container.decodeNil() {
            self = .null
        } else {
            self = .null
        }
    }
}

struct GeminiToolResponse: Codable {
    let toolResponseId: String?
    let outputs: [GeminiToolOutput]?
}

struct GeminiToolOutput: Codable {
    let result: String?
}

struct GeminiToolCallCancellation: Decodable {
    let toolCallIds: [String]?
}
