import Foundation

struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    var content: String
    var likeCount: Int
    let createdAt: String
    var updatedAt: String?
    var user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case likeCount = "like_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }

    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
}

struct LikeResponse: Codable {
    let liked: Bool
    let likeCount: Int

    enum CodingKeys: String, CodingKey {
        case liked
        case likeCount = "like_count"
    }
}

struct PostLike: Codable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
