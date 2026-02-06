import Foundation

class OnboardingDataManager {
    static let shared = OnboardingDataManager()
    private init() {}
    
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
    
    func submit(completion: @escaping (Result<User, Error>) -> Void) {
        guard let healthGoal = healthGoal,
              let gender = gender,
              let age = age,
              let help = seekingProfessionalHelp else {
            completion(.failure(APIError.serverError(message: "Missing onboarding data")))
            return
        }
        
        UserService.shared.saveOnboarding(
            healthGoal: healthGoal,
            gender: gender,
            age: age,
            seekingProfessionalHelp: help,
            completion: completion
        )
    }
}
