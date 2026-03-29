import Foundation
import Supabase
import Combine

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var posts: [CommunityPostWithUser] = []
    @Published var currentPost: CommunityPostWithUser?
    @Published var comments: [CommentWithUser] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var pagination: PaginationInfo?
    
    private let supabase = SupabaseConfig.shared.client
    var currentPage = 1
    let perPage = 20
    
    struct PaginationInfo {
        let page: Int
        let perPage: Int
        let total: Int
        let totalPages: Int
        let hasNext: Bool
        let hasPrev: Bool
    }
    
    struct CommunityPostWithUser: Identifiable {
        let post: DBCommunityPost
        let user: DBUser?
        
        var id: UUID { post.id }
        var isMine: Bool = false
        var isLiked: Bool = false
    }
    
    struct CommentWithUser: Identifiable {
        let comment: DBComment
        let user: DBUser?
        
        var id: UUID { comment.id }
    }
    
    func fetchPosts(page: Int = 1, tag: String? = nil, refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            posts = []
        }
        
        isLoading = true
        
        do {
            var query = supabase.from("community_posts")
                .select("*")
                .eq("is_deleted", value: false)
            
            if let tag = tag, !tag.isEmpty {
                // Approximate array contains or substring match depending on PostgREST setup
                query = query.like("tags", value: "%\(tag)%")
            }
            
            let postData: [DBCommunityPost] = try await query
                .order("created_at", ascending: false)
                .range(from: (page - 1) * perPage, to: page * perPage - 1)
                .execute()
                .value
            
            let session = try? await supabase.auth.session
            let currentUserId = session?.user.id.uuidString
            
            var likedPostIds: Set<String> = []
            if let currentUserId = currentUserId, !postData.isEmpty {
                struct LikeResult: Decodable {
                    let post_id: UUID
                }
                let postIds = postData.map { $0.id.uuidString }
                let likedPosts: [LikeResult]? = try? await supabase.from("post_likes")
                    .select("post_id")
                    .eq("user_id", value: currentUserId)
                    .in("post_id", value: postIds)
                    .execute()
                    .value
                if let likes = likedPosts {
                    likedPostIds = Set(likes.map { $0.post_id.uuidString })
                }
            }
            
            // Get user info for each post
            var postsWithUsers: [CommunityPostWithUser] = []
            for post in postData {
                var user: DBUser? = nil
                if !post.isAnonymous, let userId = post.userId?.uuidString {
                    let userResponse: [DBUser]? = try? await supabase.from("users")
                        .select("id, name, profile_image_url")
                        .eq("id", value: userId)
                        .execute()
                        .value
                    if let users = userResponse {
                        user = users.first
                    }
                }
                
                let isMine = post.userId?.uuidString == currentUserId
                let isLiked = likedPostIds.contains(post.id.uuidString)
                
                postsWithUsers.append(CommunityPostWithUser(post: post, user: user, isMine: isMine, isLiked: isLiked))
            }
            
            if page == 1 {
                posts = postsWithUsers
            } else {
                posts.append(contentsOf: postsWithUsers)
            }
            
            currentPage = page
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createPost(content: String, isAnonymous: Bool, tags: [String], mediaUrls: [String]? = nil) async throws -> DBCommunityPost {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "CommunityVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        let newPost = DBCommunityPost(
            id: UUID(),
            userId: isAnonymous ? nil : session.user.id,
            content: content,
            isAnonymous: isAnonymous,
            tags: tags,
            mediaUrls: mediaUrls ?? [],
            likeCount: 0,
            commentCount: 0,
            isDeleted: false,
            createdAt: now,
            updatedAt: now
        )
        
        try await supabase.from("community_posts").insert(newPost).execute()
        
        return newPost
    }
    
    func updatePost(id: String, content: String, tags: [String]) async throws {
        struct UpdatePostReq: Encodable {
            var content: String
            var tags: [String]
            var updated_at: String
        }
        let req = UpdatePostReq(content: content, tags: tags, updated_at: ISO8601DateFormatter().string(from: Date()))
        try await supabase.from("community_posts")
            .update(req)
            .eq("id", value: id)
            .execute()
        
        if let index = posts.firstIndex(where: { $0.id.uuidString == id }) {
            posts[index] = CommunityPostWithUser(
                post: DBCommunityPost(
                    id: posts[index].post.id,
                    userId: posts[index].post.userId,
                    content: content,
                    isAnonymous: posts[index].post.isAnonymous,
                    tags: tags,
                    mediaUrls: posts[index].post.mediaUrls,
                    likeCount: posts[index].post.likeCount,
                    commentCount: posts[index].post.commentCount,
                    isDeleted: posts[index].post.isDeleted,
                    createdAt: posts[index].post.createdAt,
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                ),
                user: posts[index].user
            )
        }
    }
    
    func deletePost(id: UUID) async throws {
        struct DeletePostReq: Encodable {
            var is_deleted: Bool
            var updated_at: String
        }
        let req = DeletePostReq(is_deleted: true, updated_at: ISO8601DateFormatter().string(from: Date()))
        try await supabase.from("community_posts")
            .update(req)
            .eq("id", value: id.uuidString)
            .execute()
        
        posts.removeAll { $0.id == id }
    }
    
    func toggleLike(postId: UUID) async throws -> (liked: Bool, count: Int) {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "CommunityVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        // Check if already liked
        let existingLikeResp: [DBPostLike] = try await supabase.from("post_likes")
            .select("*")
            .eq("post_id", value: postId.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .execute()
            .value
        
        if let existing = existingLikeResp.first {
            // Unlike
            try await supabase.from("post_likes").delete().eq("id", value: existing.id.uuidString).execute()
            
            // Update count
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                let newCount = max(0, posts[index].post.likeCount - 1)
                posts[index] = CommunityPostWithUser(
                    post: DBCommunityPost(
                        id: posts[index].post.id,
                        userId: posts[index].post.userId,
                        content: posts[index].post.content,
                        isAnonymous: posts[index].post.isAnonymous,
                        tags: posts[index].post.tags,
                        mediaUrls: posts[index].post.mediaUrls,
                        likeCount: newCount,
                        commentCount: posts[index].post.commentCount,
                        isDeleted: posts[index].post.isDeleted,
                        createdAt: posts[index].post.createdAt,
                        updatedAt: posts[index].post.updatedAt
                    ),
                    user: posts[index].user,
                    isMine: posts[index].isMine,
                    isLiked: false
                )
                return (false, newCount)
            }
            return (false, 0)
        } else {
            // Like
            let newLike = DBPostLike(
                id: UUID(),
                postId: postId,
                userId: session.user.id,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase.from("post_likes").insert(newLike).execute()
            
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                let newCount = posts[index].post.likeCount + 1
                posts[index] = CommunityPostWithUser(
                    post: DBCommunityPost(
                        id: posts[index].post.id,
                        userId: posts[index].post.userId,
                        content: posts[index].post.content,
                        isAnonymous: posts[index].post.isAnonymous,
                        tags: posts[index].post.tags,
                        mediaUrls: posts[index].post.mediaUrls,
                        likeCount: newCount,
                        commentCount: posts[index].post.commentCount,
                        isDeleted: posts[index].post.isDeleted,
                        createdAt: posts[index].post.createdAt,
                        updatedAt: posts[index].post.updatedAt
                    ),
                    user: posts[index].user,
                    isMine: posts[index].isMine,
                    isLiked: true
                )
                return (true, newCount)
            }
            return (true, 1)
        }
    }
    
    func fetchComments(postId: UUID, page: Int = 1) async {
        isLoading = true
        
        do {
            let commentData: [DBComment] = try await supabase.from("comments")
                .select("*")
                .eq("post_id", value: postId.uuidString)
                .order("created_at", ascending: true)
                .range(from: (page - 1) * perPage, to: page * perPage - 1)
                .execute()
                .value
            
            var commentsWithUsers: [CommentWithUser] = []
            for comment in commentData {
                let userResponse: [DBUser]? = try? await supabase.from("users")
                    .select("id, name, profile_image_url")
                    .eq("id", value: comment.userId.uuidString)
                    .execute()
                    .value
                var user: DBUser? = nil
                if let users = userResponse {
                    user = users.first
                }
                commentsWithUsers.append(CommentWithUser(comment: comment, user: user))
            }
            
            comments = commentsWithUsers
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addComment(postId: UUID, text: String) async throws -> DBComment {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "CommunityVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        let newComment = DBComment(
            id: UUID(),
            postId: postId,
            userId: session.user.id,
            content: text,
            likeCount: 0,
            createdAt: now,
            updatedAt: now
        )
        
        try await supabase.from("comments").insert(newComment).execute()
        
        // Wrap the DBComment in CommentWithUser, referencing the exact CurrentUser matching who posted it
        let currentUserResp: [DBUser]? = try? await supabase.from("users")
            .select("id, name, profile_image_url")
            .eq("id", value: session.user.id.uuidString)
            .execute()
            .value
            
        let commentWithUser = CommentWithUser(comment: newComment, user: currentUserResp?.first)
        
        await MainActor.run {
            self.comments.insert(commentWithUser, at: 0) // Optimistic Local Insert
        }
        
        // Update comment count
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            let newCount = posts[index].post.commentCount + 1
            posts[index] = CommunityPostWithUser(
                post: DBCommunityPost(
                    id: posts[index].post.id,
                    userId: posts[index].post.userId,
                    content: posts[index].post.content,
                    isAnonymous: posts[index].post.isAnonymous,
                    tags: posts[index].post.tags,
                    mediaUrls: posts[index].post.mediaUrls,
                    likeCount: posts[index].post.likeCount,
                    commentCount: newCount,
                    isDeleted: posts[index].post.isDeleted,
                    createdAt: posts[index].post.createdAt,
                    updatedAt: posts[index].post.updatedAt
                ),
                user: posts[index].user,
                isMine: posts[index].isMine,
                isLiked: posts[index].isLiked
            )
        }
        
        return newComment
    }
    
    func getAvailableTags() async -> [String] {
        do {
            struct TagResult: Decodable {
                let tags: [String]
            }
            let posts: [TagResult] = try await supabase.from("community_posts")
                .select("tags")
                .eq("is_deleted", value: false)
                .execute()
                .value
            
            var allTags = Set<String>()
            for post in posts {
                for tag in post.tags {
                    allTags.insert(tag.lowercased().trimmingCharacters(in: .whitespaces))
                }
            }
            
            return Array(allTags).sorted()
        } catch {
            return []
        }
    }
}
