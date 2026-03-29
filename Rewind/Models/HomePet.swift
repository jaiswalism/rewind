import Foundation

struct HomePet: Codable, Identifiable {
    let id: String
    var name: String
    var type: String
    var level: Int
    var experience: Int
    var state: PenguinState?
    var memory: PenguinMemory?
    var customizations: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case id, name, type, level, experience, state, memory, customizations
    }
}

struct PenguinState: Codable {
    var energy: Double
    var mood: Double
    var trust: Double
}

struct PenguinMemory: Codable {
    var dominantEmotion: String?
    var weekAvgMood: Double?
    var talkPreference: String?

    enum CodingKeys: String, CodingKey {
        case dominantEmotion = "dominant_emotion"
        case weekAvgMood = "week_avg_mood"
        case talkPreference = "talk_preference"
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date

    var isFromUser: Bool {
        role == "user"
    }
}


// Helper for JSON dictionaries
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        }
    }
}
