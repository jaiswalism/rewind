import Foundation
// ...existing code...

struct CommunityPost: Codable, Identifiable {
    let id: String
    let userId: String?
    let content: String
    let isAnonymous: Bool
    var tags: [String]
    var mediaUrls: [String]?
    var likeCount: Int
    var commentCount: Int
    let createdAt: String
    var updatedAt: String?
    var user: User?
    var isLikedByMe: Bool?
    var isMine: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case isAnonymous = "is_anonymous"
        case tags
        case mediaUrls = "media_urls"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case isLikedByMe = "is_liked_by_me"
        case isMine = "is_mine"
    }

    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
}
