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

    /// Calls the deployed Supabase Edge Function for pet responses.
    private var petInferURL: URL {
        let base = SupabaseSecrets.supabaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)/functions/v1/\(Constants.PetCompanion.edgeFunctionName)")!
    }

    private var shouldSkipLocalhostInferenceOnDevice: Bool {
        guard let host = petInferURL.host?.lowercased() else {
            return false
        }
        let isLoopback = host == "127.0.0.1" || host == "localhost"

        #if targetEnvironment(simulator)
        return false
        #else
        return isLoopback
        #endif
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

        // Get current pet state
        await fetchPet()
        guard let petData = pet else {
            throw NSError(domain: "PetVM", code: 404, userInfo: [NSLocalizedDescriptionKey: "Pet state not available"])
        }

        // Build inference request
        let timeOfDay = currentTimeOfDay()
        let request = PetInferenceRequest(
            type: .message,
            content: message,
            explicitRequest: true,
            context: PetInferenceContext(
                timeOfDay: timeOfDay,
                daysInactive: 0,
                state: PetCompanionStateSnapshot(
                    energy: Int(petData.state.energy),
                    mood: Int(petData.state.mood),
                    trust: Int(petData.state.trust)
                )
            ),
            userId: session.user.id.uuidString
        )

        // Call native Swift service
        let response = try await PetCompanionService.shared.infer(request)

        // Update local pet state
        if let currentPet = pet {
            var updatedState = currentPet.state
            updatedState.energy = Double(max(0, min(100, Int(currentPet.state.energy) + response.stateDelta.energy)))
            updatedState.mood = Double(max(0, min(100, Int(currentPet.state.mood) + response.stateDelta.mood)))
            updatedState.trust = Double(max(0, min(100, Int(currentPet.state.trust) + response.stateDelta.trust)))
            
            pet = PetData(
                id: currentPet.id,
                name: currentPet.name,
                type: currentPet.type,
                level: currentPet.level,
                experience: currentPet.experience,
                state: updatedState,
                memory: currentPet.memory
            )
        }

        return (
            response: response.textResponse ?? "I'm here for you!",
            emotion: response.emotion.primary.rawValue,
            policy: response.behaviorPolicy.rawValue
        )
    }
    
    func analyzeJournalMood(content: String) async throws -> (emotion: String, policy: String?) {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "PetVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let timeOfDay = currentTimeOfDay()
        let request = PetInferenceRequest(
            type: .journal,
            content: content,
            explicitRequest: false,
            context: PetInferenceContext(
                timeOfDay: timeOfDay,
                daysInactive: 0
            ),
            userId: session.user.id.uuidString
        )

        let response = try await PetCompanionService.shared.infer(request)

        return (
            emotion: response.emotion.primary.rawValue,
            policy: response.behaviorPolicy.rawValue
        )
    }
    
    // MARK: - Helpers
    
    /// Determine current time of day for context
    private func currentTimeOfDay() -> PetTimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
}
