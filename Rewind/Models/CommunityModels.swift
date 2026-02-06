import Foundation

struct CommunityPost: Codable {
    let id: String
    let content: String
    let isAnonymous: Bool
    let tags: [String]
    let mediaUrls: [String]?
    let likeCount: Int
    let commentCount: Int
    let createdAt: String
    let user: User? 
    let isLikedByMe: Bool? 
    let isMine: Bool?

    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
}

struct CreatePostRequest: Codable {
    let content: String
    let isAnonymous: Bool
    let tags: [String]
    let mediaUrls: [String]?
}

struct Comment: Codable {
    let id: String
    let postId: String
    let userId: String
    let commentText: String
    let createdAt: String
    let user: User?
    
    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
}

struct CreateCommentRequest: Codable {
    let commentText: String
}

struct PostListResponse: Codable {
    let success: Bool
    let data: [CommunityPost]
    let pagination: Pagination?
}

struct CommentListResponse: Codable {
    let success: Bool
    let data: [Comment]
    let pagination: Pagination?
}

struct SinglePostResponse: Codable {
    let success: Bool
    let data: CommunityPost
}

struct LikeResponse: Codable {
    let liked: Bool
    let likeCount: Int
}
