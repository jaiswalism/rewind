import Foundation

struct CareCornerStats: Codable {
    let totalPaws: Int
    let breathingMinutes: Int
    let meditationMinutes: Int
    let challengesCompleted: Int
}

struct DailyChallenge: Codable, Identifiable {
    let id: String
    let challengeText: String
    let challengeDate: String
    var isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case challengeText = "challenge_text"
        case challengeDate = "challenge_date"
        case isCompleted = "is_completed"
    }
}

struct UserChallengeCompletion: Codable, Identifiable {
    let id: String
    let userId: String
    let challengeId: String
    let completedAt: String
    var challenge: DailyChallenge?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case challengeId = "challenge_id"
        case completedAt = "completed_at"
        case challenge
    }
}

struct RecordBreathingRequest: Codable {
    let durationSeconds: Int
}

struct RecordMeditationRequest: Codable {
    let durationSeconds: Int
    let soundName: String
}

struct ActivityResponse: Codable { // what we get back after an activity

    let id: String
    let pawsEarned: Int
}
