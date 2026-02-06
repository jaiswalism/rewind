import Foundation

class UserService {
    static let shared = UserService()
    private init() {}
    
    // managing the user profile
    func getProfile(completion: @escaping (Result<User, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/users/profile", method: "GET") { (result: Result<APIResponse<User>, Error>) in
            switch result {
            case .success(let response):
                if let user = response.data {
                    completion(.success(user))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateProfile(name: String? = nil, location: String? = nil, dateOfBirth: String? = nil, gender: String? = nil, age: Int? = nil, healthGoal: String? = nil, seekingProfessionalHelp: Bool? = nil, completion: @escaping (Result<User, Error>) -> Void) {
        
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let location = location { body["location"] = location }
        if let dateOfBirth = dateOfBirth { body["dateOfBirth"] = dateOfBirth }
        if let gender = gender { body["gender"] = gender }
        if let age = age { body["age"] = age }
        if let healthGoal = healthGoal { body["healthGoal"] = healthGoal }
        if let seekingProfessionalHelp = seekingProfessionalHelp { body["seekingProfessionalHelp"] = seekingProfessionalHelp }
        
        let requestBody = UpdateProfileRequest(
            name: name,
            location: location,
            dateOfBirth: dateOfBirth,
            gender: gender,
            age: age,
            healthGoal: healthGoal,
            seekingProfessionalHelp: seekingProfessionalHelp
        )
        
        APIService.shared.makeRequest(endpoint: "/users/profile", method: "PUT", body: requestBody) { (result: Result<APIResponse<User>, Error>) in
            switch result {
            case .success(let response):
                if let user = response.data {
                    completion(.success(user))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // update the user's face
    // multipart upload is a bit tricky so we'll handle it properly later
    // sticking to json updates for now
    
    // getting the user started

    
    func saveOnboarding(healthGoal: String, gender: String, age: Int, seekingProfessionalHelp: Bool, completion: @escaping (Result<User, Error>) -> Void) {
        let requestBody = OnboardingRequest(
            healthGoal: healthGoal,
            gender: gender,
            age: age,
            seekingProfessionalHelp: seekingProfessionalHelp
        )
        
        APIService.shared.makeRequest(endpoint: "/users/onboarding", method: "POST", body: requestBody) { (result: Result<APIResponse<User>, Error>) in
            switch result {
            case .success(let response):
                if let user = response.data {
                    completion(.success(user))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getOnboardingStatus(completion: @escaping (Result<Bool, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/users/onboarding-status", method: "GET") { (result: Result<APIResponse<OnboardingStatusResponse>, Error>) in
            switch result {
            case .success(let response):
                if let data = response.data {
                    completion(.success(data.onboardingCompleted))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// data structures for requests
struct UpdateProfileRequest: Codable {
    let name: String?
    let location: String?
    let dateOfBirth: String?
    let gender: String?
    let age: Int?
    let healthGoal: String?
    let seekingProfessionalHelp: Bool?
}

struct OnboardingRequest: Codable {
    let healthGoal: String
    let gender: String
    let age: Int
    let seekingProfessionalHelp: Bool
}

struct OnboardingStatusResponse: Codable {
    let onboardingCompleted: Bool
}
