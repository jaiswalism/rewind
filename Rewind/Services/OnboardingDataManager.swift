import Foundation
import Combine

class OnboardingDataManager {
    static let shared = OnboardingDataManager()
    private init() {}
    
    private let authViewModel = AuthViewModel()
    
    // storing the user's choices
    var healthGoal: String?
    var gender: String?
    var age: Int?
    var seekingProfessionalHelp: Bool?
    
    func reset() {
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
        
        try await authViewModel.completeOnboarding(
            healthGoal: healthGoal,
            gender: gender,
            age: age,
            seekingProfessionalHelp: help
        )
        guard let user = authViewModel.currentUser else {
            throw NSError(domain: "Onboarding", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load user profile after onboarding setup."])
        }
        
        return user
    }
}
