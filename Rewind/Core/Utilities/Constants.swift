import Foundation

enum Constants {
    enum Supabase {
        static let url = "https://YOUR_PROJECT.supabase.co"
        static let anonKey = "YOUR_ANON_KEY"
    }

    /// Penguin intelligence HTTP API (see `Rewind/penguin-intelligence-service`). Simulator: `127.0.0.1` reaches the host Mac. **Physical device:** use your Mac’s LAN IP, e.g. `http://192.168.1.x:3001`.
    enum PenguinService {
        static let baseURL = "http://127.0.0.1:3001"
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
