import Foundation
import Combine
import Supabase

class OnboardingDataManager {
    static let shared = OnboardingDataManager()
    private init() {}
    
    // storing the user's choices
    var displayName: String?   // captured from Apple Sign-In fullName
    var healthGoal: String?
    var gender: String?
    var age: Int?
    var seekingProfessionalHelp: Bool?
    
    func reset() {
        displayName = nil
        healthGoal = nil
        gender = nil
        age = nil
        seekingProfessionalHelp = nil
    }
    
    func isComplete() -> Bool {
        return healthGoal != nil && gender != nil && age != nil && seekingProfessionalHelp != nil
    }
    
    func submit() async throws -> DBUser {
        guard let healthGoal = healthGoal,
              let gender = gender,
              let age = age,
              let help = seekingProfessionalHelp else {
            throw NSError(domain: "Onboarding", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing onboarding data"])
        }
        
        // Use the active session directly — no separate AuthViewModel needed
        let session = try await SupabaseConfig.shared.client.auth.session
        let userId = session.user.id
        
        struct OnboardingUpdate: Encodable {
            var name: String?
            var health_goal: String
            var gender: String
            var age: Int
            var seeking_professional_help: Bool
            var onboarding_completed: Bool
            var updated_at: String
        }
        
        let req = OnboardingUpdate(
            name: displayName,          // write Apple name reliably here, when row exists
            health_goal: healthGoal,
            gender: gender,
            age: age,
            seeking_professional_help: help,
            onboarding_completed: true,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await SupabaseConfig.shared.client.from("users").update(req).eq("id", value: userId).execute()
        
        // Cache locally for offline resilience
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
        
        // Fetch and return the updated user row directly
        let response: DBUser = try await SupabaseConfig.shared.client
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return response
    }
}
