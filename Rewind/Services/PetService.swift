import Foundation

class HomePetService {
    static let shared = HomePetService()
    private init() {}
    
    // fetching your pet's details
    func getPet(completion: @escaping (Result<Pet, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/homepets/user-pet", method: "GET") { (result: Result<APIResponse<Pet>, Error>) in
            switch result {
            case .success(let response):
                if let pet = response.data {
                    completion(.success(pet))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updatePet(name: String?, type: String?, color: String?, completion: @escaping (Result<Pet, Error>) -> Void) {
        let body = UpdatePetRequest(name: name, type: type, color: color)
        APIService.shared.makeRequest(endpoint: "/homepets/user-pet", method: "PUT", body: body) { (result: Result<APIResponse<Pet>, Error>) in
            switch result {
            case .success(let response):
                if let pet = response.data {
                    completion(.success(pet))
                } else {
                    completion(.failure(APIError.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
