import Foundation

enum Constants {
    enum Auth {
        static let oauthRedirectURL = URL(string: "rewind://auth-callback")!
    }

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
        static let breathingPawsPerMinute = 2
        static let meditationPawsPerMinute = 3
        static let challengeCompletionPaws = 10
        static let minimumBreathingSeconds = 60
        static let minimumMeditationSeconds = 120
    }

    enum UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let currentUserID = "currentUserID"
        static let selectedPetMartStyle = "selectedPetMartStyle"
        static let ownedPetMartStyles = "ownedPetMartStyles"
    }
}
