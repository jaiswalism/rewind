import Foundation

class CommunityService {
    static let shared = CommunityService()
    private init() {}
    
    // interacting with community posts    
    func getPosts(page: Int = 1, limit: Int = 10, completion: @escaping (Result<[CommunityPost], Error>) -> Void) {
        let endpoint = "/community/posts?page=\(page)&limit=\(limit)"
        APIService.shared.makeRequest(endpoint: endpoint, method: "GET") { (result: Result<PostListResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    struct UpdatePostRequest: Encodable {
        let content: String
        let tags: [String]
    }

    func updatePost(id: String, content: String, tags: [String], completion: @escaping (Result<CommunityPost, Error>) -> Void) {
        let body = UpdatePostRequest(content: content, tags: tags)
        APIService.shared.makeRequest(endpoint: "/community/posts/\(id)", method: "PUT", body: body) { (result: Result<APIResponse<CommunityPost>, Error>) in
            switch result {
            case .success(let response):
                if let data = response.data {
                    completion(.success(data))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func createPost(content: String, isAnonymous: Bool, tags: [String], mediaUrls: [String]? = nil, completion: @escaping (Result<CommunityPost, Error>) -> Void) {
        let body = CreatePostRequest(content: content, isAnonymous: isAnonymous, tags: tags, mediaUrls: mediaUrls)
        APIService.shared.makeRequest(endpoint: "/community/posts", method: "POST", body: body) { (result: Result<SinglePostResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func deletePost(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/community/posts/\(id)", method: "DELETE") { (result: Result<APIResponse<String>, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // managing likes
    func likePost(id: String, completion: @escaping (Result<LikeResponse, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/community/posts/\(id)/like", method: "POST") { (result: Result<APIResponse<LikeResponse>, Error>) in
            switch result {
            case .success(let response):
                if let data = response.data {
                    completion(.success(data))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func unlikePost(id: String, completion: @escaping (Result<LikeResponse, Error>) -> Void) {
        // backend treats this as a toggle, so same endpoint as like
        APIService.shared.makeRequest(endpoint: "/community/posts/\(id)/like", method: "POST") { (result: Result<APIResponse<LikeResponse>, Error>) in
            switch result {
            case .success(let response):
                if let data = response.data {
                    completion(.success(data))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Comments
    
    func getComments(postId: String, page: Int = 1, limit: Int = 20, completion: @escaping (Result<[Comment], Error>) -> Void) {
        let endpoint = "/community/posts/\(postId)/comments?page=\(page)&limit=\(limit)"
        APIService.shared.makeRequest(endpoint: endpoint, method: "GET") { (result: Result<CommentListResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func addComment(postId: String, text: String, completion: @escaping (Result<Comment, Error>) -> Void) {
        let body = CreateCommentRequest(commentText: text)
        APIService.shared.makeRequest(endpoint: "/community/posts/\(postId)/comments", method: "POST", body: body) { (result: Result<APIResponse<Comment>, Error>) in
            switch result {
            case .success(let response):
                if let comment = response.data {
                    completion(.success(comment))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
