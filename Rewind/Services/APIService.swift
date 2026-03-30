import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(message: String)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .decodingError:
            return "Failed to process server response"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Session expired. Please login again."
        }
    }
}

class APIService {
    static let shared = APIService()
    private init() {}
    
    private let baseURL = "http://localhost:3000/api/v1"
    
    var authToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "authToken")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "authToken")
        }
    }
    
    func makeRequest<T: Codable>(endpoint: String, method: String = "GET", body: Encodable? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🚀 API Request: \(method) \(endpoint)") // Debug Log
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ API Error: \(error.localizedDescription)") // Debug Log
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.serverError(message: "Invalid response")))
                return
            }
            
            print("✅ API Response: \(httpResponse.statusCode) for \(endpoint)") // Debug Log
            
            if httpResponse.statusCode == 401 {
                completion(.failure(APIError.unauthorized))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    completion(.failure(APIError.serverError(message: errorResponse.error.message)))
                } else {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Decoding Error. Raw Response: \(responseString)")
                    } else {
                        print("❌ Decoding Error. Could not convert data to string.")
                    }
                    print("❌ Decoding Error Detail: \(error)")
                    completion(.failure(APIError.decodingError))
                }
            }
        }.resume()
    }
    // MARK: - Upload Request
    func uploadRequest<T: Codable>(endpoint: String, method: String = "POST", fileUrl: URL, fileName: String, fileType: String = "audio/m4a", completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let fileData = try Data(contentsOf: fileUrl)
            
            var body = Data()
            
            // File
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(fileType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            
            // Close Boundary
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
        } catch {
            print("❌ File Read Error: \(error)")
            completion(.failure(error))
            return
        }
        
        print("🚀 API Upload: \(method) \(endpoint)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ API Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.serverError(message: "Invalid response")))
                return
            }
            
            print("✅ API Response: \(httpResponse.statusCode) for \(endpoint)")
            
            if httpResponse.statusCode == 401 {
                completion(.failure(APIError.unauthorized))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    completion(.failure(APIError.serverError(message: errorResponse.error.message)))
                } else {
                    print("❌ Decoding Error. Detail: \(error)")
                    completion(.failure(APIError.decodingError))
                }
            }
        }.resume()
    }
}

struct ErrorResponse: Codable, Sendable {
    let success: Bool
    let error: ErrorDetail
}

struct ErrorDetail: Codable, Sendable {
    let code: String
    let message: String
}
