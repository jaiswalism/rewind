import Foundation

enum Constants {
    enum Supabase {
        static let url = "https://YOUR_PROJECT.supabase.co"
        static let anonKey = "YOUR_ANON_KEY"
    }

    enum PenguinService {
        static let baseURL = "http://localhost:3001"
    }

    enum Pagination {
        static let defaultPerPage = 20
        static let maxPerPage = 100
    }

    enum Paws {
        static let breathingPawsPerMinute = 20
        static let meditationPawsPerMinute = 20
        static let challengeCompletionPaws = 50
    }

    enum UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let currentUserID = "currentUserID"
    }
}
