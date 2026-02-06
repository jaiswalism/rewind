import Foundation

enum EntryType: String, Codable {
    case text
    case voice
}

struct Journal: Codable {
    let id: String
    let userId: String?
    let title: String
    let content: String
    let entryType: EntryType
    let voiceRecordingUrl: String?
    let transcriptionText: String?
    let moodTags: [String]?
    let mediaUrls: [String]?
    let createdAt: String
    let updatedAt: String
    
    // Helper to get Date object
    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
}

struct CreateJournalRequest: Codable {
    let title: String
    let content: String
    let entryType: String
    let moodTags: [String]?

    let voiceRecordingUrl: String?
    let mediaUrls: [String]?
    let transcriptionText: String?
}

struct JournalListResponse: Codable {
    let success: Bool
    let data: [Journal]
    let pagination: Pagination?
}

struct JournalResponse: Codable {
    let success: Bool
    let data: Journal
}

struct Pagination: Codable {
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int
}

struct UploadMediaResponse: Codable {
    let mediaUrl: String
}
