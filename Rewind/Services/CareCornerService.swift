import Foundation

class CareCornerService {
    static let shared = CareCornerService()
    private init() {}
    
    // MARK: - Stats
    
    func getStats(completion: @escaping (Result<CareCornerStats, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/care-corner/stats", method: "GET") { (result: Result<APIResponse<CareCornerStats>, Error>) in
            switch result {
            case .success(let response):
                if let data = response.data {
                    completion(.success(data))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Challenges
    
    func getDailyChallenges(completion: @escaping (Result<[DailyChallenge], Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/care-corner/challenges", method: "GET") { (result: Result<APIResponse<[DailyChallenge]>, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func completeChallenge(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/care-corner/challenges/\(id)/complete", method: "POST") { (result: Result<APIResponse<String>, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Breathing
    
    func recordBreathing(durationSeconds: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        let body = RecordBreathingRequest(durationSeconds: durationSeconds)
        APIService.shared.makeRequest(endpoint: "/care-corner/breathing", method: "POST", body: body) { (result: Result<APIResponse<ActivityResponse>, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data?.pawsEarned ?? 0))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Meditation
    
    func recordMeditation(durationSeconds: Int, soundName: String, completion: @escaping (Result<Int, Error>) -> Void) {
        let body = RecordMeditationRequest(durationSeconds: durationSeconds, soundName: soundName)
        APIService.shared.makeRequest(endpoint: "/care-corner/meditation", method: "POST", body: body) { (result: Result<APIResponse<ActivityResponse>, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data?.pawsEarned ?? 0))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
