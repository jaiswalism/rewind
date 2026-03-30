import Foundation

// MARK: - User
// DB columns: id, email, name, profile_image_url, timezone, location, date_of_birth, gender,
//             age, health_goal, seeking_professional_help, created_at, updated_at
// + DB migration adds: phone, paws_balance, total_posts, onboarding_completed
struct DBUser: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String?
    var phone: String?
    var profileImageUrl: String?
    var timezone: String?
    var location: String?
    var dateOfBirth: String?
    var gender: String?
    var age: Int?
    var healthGoal: String?
    var seekingProfessionalHelp: Bool?
    var pawsBalance: Int?
    var totalPosts: Int?
    var onboardingCompleted: Bool?
    let createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, timezone, location, gender, age
        case profileImageUrl = "profile_image_url"
        case dateOfBirth = "date_of_birth"
        case healthGoal = "health_goal"
        case seekingProfessionalHelp = "seeking_professional_help"
        case pawsBalance = "paws_balance"
        case totalPosts = "total_posts"
        case onboardingCompleted = "onboarding_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Journal
// DB columns: id, user_id, title, content, emotion, tags, media_urls, is_favorite, created_at, updated_at
struct DBJournal: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var title: String
    var content: String
    var emotion: String?
    var tags: [String]
    var mediaUrls: [String]
    var isFavorite: Bool
    let createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, content, emotion, tags
        case mediaUrls = "media_urls"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var createdDate: Date? {
        ISO8601DateFormatter().date(from: createdAt)
    }
}

// MARK: - Community Post
// DB columns: id, user_id, content, is_anonymous, tags, media_urls, like_count, comment_count, is_deleted, created_at, updated_at
struct DBCommunityPost: Codable, Identifiable {
    let id: UUID
    var userId: UUID?
    var content: String
    var isAnonymous: Bool
    var tags: [String]
    var mediaUrls: [String]
    var likeCount: Int
    var commentCount: Int
    var isDeleted: Bool
    let createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case isAnonymous = "is_anonymous"
        case tags
        case mediaUrls = "media_urls"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Comment
// DB columns: id, post_id, user_id, content, like_count, created_at, updated_at
struct DBComment: Codable, Identifiable {
    let id: UUID
    var postId: UUID
    var userId: UUID
    var content: String
    var likeCount: Int
    let createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case likeCount = "like_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Post Like
// DB columns: id, post_id, user_id, created_at
struct DBPostLike: Codable, Identifiable {
    let id: UUID
    var postId: UUID
    var userId: UUID
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Notification
// DB columns: id, user_id, title, body, type, is_read, reference_id, created_at
struct DBNotification: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var title: String
    var body: String
    var type: String
    var isRead: Bool
    var referenceId: UUID?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, body, type
        case isRead = "is_read"
        case referenceId = "reference_id"
        case createdAt = "created_at"
    }
}

// MARK: - Daily Challenge
// DB columns: id, title, description, category, points, created_for_date
struct DBDailyChallenge: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    var category: String
    var points: Int
    var createdForDate: String

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, points
        case createdForDate = "created_for_date"
    }
}

// MARK: - User Challenge Completion
// DB columns: id, user_id, challenge_id, completed_at
struct DBUserChallengeCompletion: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var challengeId: UUID
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case challengeId = "challenge_id"
        case completedAt = "completed_at"
    }
}

// MARK: - Breathing Exercise
// DB columns: id, user_id, duration_seconds, completed_at
// + DB migration adds: paws_earned
struct DBBreathingExercise: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var durationSeconds: Int
    var pawsEarned: Int?
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case durationSeconds = "duration_seconds"
        case pawsEarned = "paws_earned"
        case completedAt = "completed_at"
    }
}

// MARK: - Meditation Session
// DB columns: id, user_id, duration_seconds, session_type, completed_at
// + DB migration adds: sound_name, paws_earned
struct DBMeditationSession: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var durationSeconds: Int
    var sessionType: String
    var soundName: String?
    var pawsEarned: Int?
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case durationSeconds = "duration_seconds"
        case sessionType = "session_type"
        case soundName = "sound_name"
        case pawsEarned = "paws_earned"
        case completedAt = "completed_at"
    }
}

// MARK: - Penguin State
// DB columns: id, user_id, name, hunger, happiness, energy, health, level, experience, accessory, color, last_interaction_at, created_at
struct DBPenguinState: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var name: String
    var hunger: Int
    var happiness: Int
    var energy: Int
    var health: Int
    var level: Int
    var experience: Int
    var accessory: String?
    var color: String?
    var lastInteractionAt: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, hunger, happiness, energy, health, level, experience, accessory, color
        case lastInteractionAt = "last_interaction_at"
        case createdAt = "created_at"
    }
}

// MARK: - Penguin Memory
// DB columns: id, user_id, text, importance, emotion, created_at
struct DBPenguinMemory: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var text: String
    var importance: Int
    var emotion: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case text, importance, emotion
        case createdAt = "created_at"
    }
}
