import Foundation

struct NotificationItem: Codable {
    let id: String
    let title: String
    let message: String
    let type: String

    let isRead: Bool
    let createdAt: String
    
    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
}
