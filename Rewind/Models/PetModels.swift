import Foundation

struct Pet: Codable {
    let id: String
    let name: String
    let type: String // "cat" or "dog"
    let color: String // e.g., "orange", "yellow", "white" based on UI selection
    let mood: String // "happy", "sleeping", etc. (optional, if backend tracks it)
    let experience: Int
    let level: Int
}

struct UpdatePetRequest: Codable {
    let name: String?
    let type: String? // "cat" or "dog"
    let color: String?
}
