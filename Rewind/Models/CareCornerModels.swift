import Foundation

struct CareCornerStats: Codable {
    let totalPaws: Int
    let breathingMinutes: Int
    let meditationMinutes: Int
    let challengesCompleted: Int
}

struct DailyChallenge: Codable {
    let id: String
    let challengeText: String
    let challengeDate: String
    let isCompleted: Bool
}

struct RecordBreathingRequest: Codable {
    let durationSeconds: Int
}

struct RecordMeditationRequest: Codable {
    let durationSeconds: Int
    let soundName: String
}

struct ActivityResponse: Codable { // Basic response with Paws earned
    let id: String
    let pawsEarned: Int
    // other fields omitted for brevity if not used immediately
}
