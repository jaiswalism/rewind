import Foundation

enum Constants {
    enum Auth {
        static let oauthRedirectURL = URL(string: "rewind://auth-callback")!
    }

    enum Supabase {
        static let url = "https://YOUR_PROJECT.supabase.co"
        static let anonKey = "YOUR_ANON_KEY"
    }

    /// Pet companion service (native Swift - replaces old penguin microservice)
    /// All core logic runs locally, LLM calls go through Supabase Edge Function
    enum PetCompanion {
        static let edgeFunctionName = "pet-llm"
        static let defaultSmoothingAlpha: Double = 0.3
        static let defaultState: (energy: Int, mood: Int, trust: Int) = (50, 50, 50)
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
