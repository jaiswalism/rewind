import Foundation


struct BreathingExercise: Codable, Identifiable {
    let id: String
    let userId: String?
    let durationSeconds: Int
    let durationString: String
    let pawsEarned: Int
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case durationSeconds = "duration_seconds"
        case durationString = "duration_string"
        case pawsEarned = "paws_earned"
        case completedAt = "completed_at"
    }

    var completedDate: Date? {
        Date.fromISO8601(completedAt)
    }
}

struct MeditationSession: Codable, Identifiable {
    let id: String
    let userId: String?
    let durationSeconds: Int
    let durationString: String
    let soundName: String
    let pawsEarned: Int
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case durationSeconds = "duration_seconds"
        case durationString = "duration_string"
        case soundName = "sound_name"
        case pawsEarned = "paws_earned"
        case completedAt = "completed_at"
    }

    var completedDate: Date? {
        Date.fromISO8601(completedAt)
    }
}

struct WellnessStats: Codable {
    let totalBreathingExercises: Int
    let totalMeditationSessions: Int
    let totalChallengesCompleted: Int
    let pawsBalance: Int

    enum CodingKeys: String, CodingKey {
        case totalBreathingExercises = "total_breathing_exercises"
        case totalMeditationSessions = "total_meditation_sessions"
        case totalChallengesCompleted = "total_challenges_completed"
        case pawsBalance = "paws_balance"
    }

    var totalActivities: Int {
        totalBreathingExercises + totalMeditationSessions + totalChallengesCompleted
    }
}

