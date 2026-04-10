import Foundation

// MARK: - LLM Service Protocol

/// Protocol for LLM service (enables mocking in tests)
protocol PetLLMServiceProtocol {
    func generateResponse(_ request: PetLLMRequest) async throws -> PetLLMResponse
}

// MARK: - Pet LLM Service

/// Service for generating LLM responses via Supabase Edge Function
final class PetLLMService: PetLLMServiceProtocol {
    
    private let edgeFunctionURL: String
    private let session: URLSession
    
    /// Initialize with edge function URL
    /// - Parameters:
    ///   - supabaseURL: Base Supabase URL
    ///   - functionName: Edge function name (default: "pet-llm")
    init(supabaseURL: String, functionName: String = "pet-llm") {
        self.edgeFunctionURL = "\(supabaseURL)/functions/v1/\(functionName)"
        self.session = URLSession(configuration: .ephemeral)
    }
    
    /// Generate response via Supabase Edge Function
    /// - Parameter request: LLM request payload
    /// - Returns: LLM response with filtered text
    func generateResponse(_ request: PetLLMRequest) async throws -> PetLLMResponse {
        do {
            // Build request
            guard let url = URL(string: edgeFunctionURL) else {
                throw PetLLMError.invalidURL(edgeFunctionURL)
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("rewind-pet-2026-secure-key", forHTTPHeaderField: "X-Pet-LLM-Key")
            urlRequest.timeoutInterval = 30
            
            // Encode request body
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let bodyData = try encoder.encode(request)
            urlRequest.httpBody = bodyData

            // Execute request
            let urlSession = URLSession(configuration: .ephemeral)
            print("🐾 [LLMService] Sending request to: \(edgeFunctionURL)")
            print("🐾 [LLMService] Request body: \(String(data: bodyData, encoding: .utf8) ?? "nil")")
            let (data, response) = try await urlSession.data(for: urlRequest)

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PetLLMError.invalidResponse
            }
            
            print("🐾 [LLMService] Response status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🐾 [LLMService] Raw response: \(responseString)")
            }
            
            // Handle quota errors
            if httpResponse.statusCode == 429 {
                let seed = "quota-\(Date().timeIntervalSince1970)"
                let fallbackText = PetOfflineReplies.pickOfflineReply(kind: .quota, seed: seed)
                return PetLLMResponse(
                    textResponse: fallbackText,
                    filtered: false,
                    reason: "LLM quota exceeded"
                )
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw PetLLMError.httpError(httpResponse.statusCode)
            }
            
            // Decode response
            let decoder = JSONDecoder()
            let llmResponse = try decoder.decode(PetLLMResponse.self, from: data)
            
            // Apply text filter
            if let text = llmResponse.textResponse {
                let filtered = PetTextFilter.filterLLMOutput(text)
                if filtered.filtered {
                    return PetLLMResponse(
                        textResponse: PetConstants.fallbackText,
                        filtered: true,
                        reason: filtered.reason
                    )
                }
                return PetLLMResponse(
                    textResponse: filtered.textResponse,
                    filtered: false
                )
            }
            
            return llmResponse
            
        } catch let error as PetLLMError {
            throw error
        } catch {
            throw PetLLMError.networkError(error)
        }
    }
}

// MARK: - LLM Errors

enum PetLLMError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid response from LLM service"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
