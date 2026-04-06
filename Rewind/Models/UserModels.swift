import Foundation

// api wrapper

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
}

// MARK: - User Model
struct User: Codable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let profileImageUrl: String?
    let location: String?
    let dateOfBirth: String?
    let gender: String?
    let age: Int?
    let healthGoal: String?
    let seekingProfessionalHelp: Bool?
    let pawsBalance: Int
    let totalPosts: Int
    let onboardingCompleted: Bool
    let ownedStyles: [String]
    let createdAt: String
    let updatedAt: String
}

// MARK: - Auth Response
struct Tokens: Codable {
    let accessToken: String
    let refreshToken: String
}

struct AuthResponseData: Codable {
    let user: User
    let tokens: Tokens
}

struct AuthResponse: Codable {
    let success: Bool
    let data: AuthResponseData
}
