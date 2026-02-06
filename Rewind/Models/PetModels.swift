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
