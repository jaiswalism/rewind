import Foundation

struct Pet: Codable {
    let id: String
    let name: String
    let type: String 
    let color: String? 
    let mood: String?

    let experience: Int
    let level: Int
}

struct UpdatePetRequest: Codable {
    let name: String?
    let type: String?

    let color: String?
}

struct ChatRequest: Codable {
    let content: String
}

struct ChatResponse: Codable {
    let text_response: String?
    let emotion: PetEmotion?
    let policy: String?
}

struct PetEmotion: Codable {
    let primary: String
    let intensity: Double
    let confidence: Double
}
