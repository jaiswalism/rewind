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
    let user: User? // Null if anonymous or user deleted? API says user object is returned usually.
    let isLikedByMe: Bool? // Often added by APIs for UI state, checking contract...
    let isMine: Bool? // Indicates if the post belongs to the current user
    
    // API Contract might not return `isLikedByMe` directly in the list unless specified. 
    // If not present, we might need to handle it or fetching separately. 
    // Looking at common patterns, let's include it if the API provides it, or nullable.
    
    // Helper for date
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
