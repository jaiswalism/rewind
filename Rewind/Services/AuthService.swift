import Foundation

class AuthService {
    static let shared = AuthService()
    private init() {}
    
    // MARK: - Register
    func register(name: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let body: [String: String] = [
            "name": name,
            "email": email,
            "password": password
        ]
        
        APIService.shared.makeRequest(endpoint: "/auth/register", method: "POST", body: body) { (result: Result<AuthResponse, Error>) in
            switch result {
            case .success(let response):
                self.handleAuthSuccess(response.data)
                completion(.success(response.data.user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        APIService.shared.makeRequest(endpoint: "/auth/login", method: "POST", body: body) { (result: Result<AuthResponse, Error>) in
            switch result {
            case .success(let response):
                self.handleAuthSuccess(response.data)
                completion(.success(response.data.user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Logout
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/auth/logout", method: "POST") { (result: Result<APIResponse<String>, Error>) in
            APIService.shared.authToken = nil
            // Clear other user data if needed
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleAuthSuccess(_ data: AuthResponseData) {
        APIService.shared.authToken = data.tokens.accessToken
        // You might also want to save the refresh token and user info
    }
}
