import Foundation

enum AppError: LocalizedError {
    case notAuthenticated
    case invalidInput(String)
    case networkError(String)
    case serverError(String)
    case notFound(String)
    case conflict(String)
    case decodingError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .invalidInput(let message):
            return message
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return message
        case .notFound(let entity):
            return "\(entity) not found"
        case .conflict(let message):
            return message
        case .decodingError:
            return "Failed to process server response"
        case .unknown(let message):
            return message
        }
    }
}
