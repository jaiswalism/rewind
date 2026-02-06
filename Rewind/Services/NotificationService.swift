import Foundation

class NotificationService {
    static let shared = NotificationService()
    private init() {}
    
    // grabbing the latest notifications from the server
    func getNotifications(completion: @escaping (Result<[NotificationItem], Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/notifications", method: "GET") { (result: Result<APIResponse<[NotificationItem]>, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func markAsRead(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/notifications/\(id)/read", method: "POST") { (result: Result<APIResponse<String>, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
