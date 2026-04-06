import Foundation
import Supabase
import Combine

@MainActor
final class PetViewModel: ObservableObject {
    @Published var pet: PetData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var isTyping = false
    private var hasLoadedPet = false
    
    private let supabase = SupabaseConfig.shared.client

    /// Must match `Rewind/penguin-intelligence-service` (`POST /infer` on port 3001). For a physical device, set `Constants.PenguinService.baseURL` to your Mac’s LAN IP (e.g. `http://192.168.1.10:3001`).
    private var penguinInferURL: URL {
        URL(string: "\(Constants.PenguinService.baseURL)/infer")!
    }
    
    struct PetData: Identifiable {
        let id: UUID
        var name: String
        var type: String
        var level: Int
        var experience: Int
        var state: PenguinState
        var memory: PenguinMemory?
        
        struct PenguinState {
            var energy: Double
            var mood: Double   // maps to happiness
            var trust: Double  // maps to health
        }
        
        struct PenguinMemory {
            var dominantEmotion: String?  // maps to emotion
            var weekAvgMood: Double        // maps to importance
            var talkPreference: String?   // not stored, nil
        }
    }
    
    struct PenguinChatRequest: Codable {
        let type: String
        let content: String
        let explicit_request: Bool
        let context: PenguinContext
        let user_id: String
        
        struct PenguinContext: Codable {
            let time_of_day: String
            let days_inactive: Int
            let last_policy: String?
            let state: State
            
            struct State: Codable {
                let energy: Int
                let mood: Int
                let trust: Int
            }
        }
    }
    
    struct PenguinChatResponse: Codable {
        let text_response: String?
        let emotion: PenguinEmotion?
        let behavior_policy: String?
        let penguin_state_delta: PenguinDelta?
        
        struct PenguinEmotion: Codable {
            let primary: String
            let intensity: Double
            let confidence: Double
        }
        
        struct PenguinDelta: Codable {
            let energy: Double?
            let mood: Double?
            let trust: Double?
        }
    }
    
    func fetchPet(force: Bool = false) async {
        if hasLoadedPet && !force {
            return
        }

        isLoading = true
        
        do {
            guard let session = try? await supabase.auth.session else { return }
            
            let stateResponse: [DBPenguinState] = try await supabase.from("pet_states")
                .select("*")
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
                .value
            
            let memoryResponse: [DBPenguinMemory] = try await supabase.from("pet_memories")
                .select("*")
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
                .value
            
            let state = stateResponse.first
            let memory = memoryResponse.first
            
            let totalState = (state?.energy ?? 0) + (state?.happiness ?? 0) + (state?.health ?? 0)
            let level = max(1, Int(totalState / 30))
            
            pet = PetData(
                id: session.user.id,
                name: state?.name ?? "Panda Companion",
                type: "panda",
                level: state?.level ?? level,
                experience: state?.experience ?? Int(totalState),
                state: PetData.PenguinState(
                    energy: Double(state?.energy ?? 100),
                    mood: Double(state?.happiness ?? 100),
                    trust: Double(state?.health ?? 50)
                ),
                memory: memory != nil ? PetData.PenguinMemory(
                    dominantEmotion: memory?.emotion,
                    weekAvgMood: Double(memory?.importance ?? 50),
                    talkPreference: nil
                ) : nil
            )

            hasLoadedPet = true
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func sendMessage(_ message: String) async throws -> (response: String, emotion: String?, policy: String?) {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "PetVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        isTyping = true
        
        defer { isTyping = false }
        
        let stateResponse: [DBPenguinState] = try await supabase.from("pet_states")
            .select("*")
            .eq("user_id", value: session.user.id.uuidString)
            .execute()
            .value
        
        let state = stateResponse.first
        
        let daysInactive = 0
        
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<21: timeOfDay = "evening"
        default: timeOfDay = "night"
        }
        
        var request = URLRequest(url: penguinInferURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatRequest = PenguinChatRequest(
            type: "message",
            content: message,
            explicit_request: true,
            context: PenguinChatRequest.PenguinContext(
                time_of_day: timeOfDay,
                days_inactive: daysInactive,
                last_policy: nil,
                state: PenguinChatRequest.PenguinContext.State(
                    energy: state?.energy ?? 100,
                    mood: state?.happiness ?? 100,
                    trust: state?.health ?? 50
                )
            ),
            user_id: session.user.id.uuidString
        )
        
        request.httpBody = try JSONEncoder().encode(chatRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "PetVM", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get response from pet service"])
        }
        
        let decoder = JSONDecoder()
        let penguinResponse = try decoder.decode(PenguinChatResponse.self, from: data)
        
        if let delta = penguinResponse.penguin_state_delta {
            if delta.energy != nil || delta.mood != nil || delta.trust != nil {
                struct StateUpdate: Encodable {
                    var energy: Int?
                    var happiness: Int?
                    var health: Int?
                }
                
                let req = StateUpdate(
                    energy: delta.energy != nil ? min(100, max(0, Int(Double(state?.energy ?? 100) + delta.energy!))) : nil,
                    happiness: delta.mood != nil ? min(100, max(0, Int(Double(state?.happiness ?? 100) + delta.mood!))) : nil,
                    health: delta.trust != nil ? min(100, max(0, Int(Double(state?.health ?? 50) + delta.trust!))) : nil
                )
                
                try await supabase.from("pet_states")
                    .update(req)
                    .eq("user_id", value: session.user.id.uuidString)
                    .execute()
            }
        }
        
        return (
            response: penguinResponse.text_response ?? "I'm here for you!",
            emotion: penguinResponse.emotion?.primary,
            policy: penguinResponse.behavior_policy
        )
    }
    
    func analyzeJournalMood(content: String) async throws -> (emotion: String, policy: String?) {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "PetVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        var request = URLRequest(url: penguinInferURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<21: timeOfDay = "evening"
        default: timeOfDay = "night"
        }
        
        let chatRequest = PenguinChatRequest(
            type: "journal",
            content: content,
            explicit_request: false,
            context: PenguinChatRequest.PenguinContext(
                time_of_day: timeOfDay,
                days_inactive: 0,
                last_policy: nil,
                state: PenguinChatRequest.PenguinContext.State(
                    energy: 100,
                    mood: 100,
                    trust: 50
                )
            ),
            user_id: session.user.id.uuidString
        )
        
        request.httpBody = try JSONEncoder().encode(chatRequest)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        let penguinResponse = try decoder.decode(PenguinChatResponse.self, from: data)
        
        return (
            emotion: penguinResponse.emotion?.primary ?? "neutral",
            policy: penguinResponse.behavior_policy
        )
    }
}
