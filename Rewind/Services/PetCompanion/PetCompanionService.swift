import Foundation
import Combine

// MARK: - Pet Companion Service

/// Main orchestrator for pet companion functionality
/// Replaces the Node.js /infer endpoint with native Swift implementation
@MainActor
final class PetCompanionService: ObservableObject {
    
    static let shared = PetCompanionService()
    
    @Published var currentState: PetCompanionState?
    @Published var isProcessing = false
    
    private let repository = PetRepository.shared
    private var llmService: PetLLMServiceProtocol?
    
    private init() {}
    
    /// Set the LLM service (can be nil for offline-only mode)
    func setLLMService(_ service: PetLLMServiceProtocol?) {
        self.llmService = service
    }
    
    // MARK: - Core Inference
    
    /// Run the complete inference pipeline (replaces POST /infer)
    /// - Parameters:
    ///   - request: Inference request
    /// - Returns: Inference response
    func infer(_ request: PetInferenceRequest) async throws -> PetInferenceResponse {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // 1. Handle silence shortcut
            if request.type == .silence && (request.content == nil || request.content?.isEmpty == true) {
                return handleSilenceShortcut()
            }
            
            // 2. Emotion inference
            let emotion = PetEmotionInference.inferEmotion(
                content: request.content,
                type: request.type
            )
            
            // 3. Compute state delta
            let stateDelta = PetStateManager.computeStateDelta(
                emotion: emotion.primary,
                intensity: emotion.intensity
            )
            
            // 4. Get current state from DB (if userId provided)
            var currentStateSnapshot: PetCompanionStateSnapshot
            var daysInactive = 0
            
            if let userId = request.userId {
                daysInactive = try await repository.calculateDaysInactive(userId: userId)
                
                let petState = try await repository.getOrCreatePetCompanionState(userId: userId)
                
                // Apply decay for inactivity
                let decayedState = PetStateManager.applyDecay(state: petState, daysInactive: daysInactive)
                
                // Update state if decay was applied
                if daysInactive > PetConstants.decayThresholdDays {
                    _ = try await repository.updatePetCompanionState(decayedState)
                }
                
                currentStateSnapshot = PetCompanionStateSnapshot(from: decayedState)
                self.currentState = decayedState
            } else {
                // Use context state or defaults
                currentStateSnapshot = request.context.state ?? PetCompanionStateSnapshot()
            }
            
            // 5. Apply smoothing to get target state
            let currentStateFull: PetCompanionState
            if let userId = request.userId {
                currentStateFull = try await repository.getOrCreatePetCompanionState(userId: userId)
            } else {
                currentStateFull = PetCompanionState(
                    userId: "anonymous",
                    energy: currentStateSnapshot.energy,
                    mood: currentStateSnapshot.mood,
                    trust: currentStateSnapshot.trust
                )
            }
            
            let smoothedState = PetStateManager.applySmoothing(
                current: currentStateFull,
                delta: stateDelta
            )
            
            // 6. Clip state to valid range
            let clippedState = PetStateManager.clipState(smoothedState)
            
            // 7. Compute actual delta (clipped - current)
            let actualDelta = PetStateManager.computeActualDelta(
                current: currentStateFull,
                target: clippedState
            )
            
            // 8. Select policy
            let moodDelta = actualDelta.mood
            let (policy, allowsTextResponse, ruleId) = PetPolicySelector.selectPolicy(
                emotion: emotion.primary,
                intensity: emotion.intensity,
                trust: clippedState.trust,
                daysInactive: daysInactive,
                inputType: request.type,
                explicitRequest: request.explicitRequest,
                moodDelta: moodDelta
            )
            
            // 9. Generate text response
            var textResponse: String?
            if allowsTextResponse {
                textResponse = try await generateTextResponse(
                    policy: policy,
                    emotion: emotion,
                    state: clippedState,
                    contentSummary: request.content ?? "",
                    userId: request.userId
                )
            } else {
                // Silent companion uses fallback
                textResponse = PetConstants.fallbackText
            }
            
            // 10. Build explainability
            let signals = buildExplainabilitySignals(
                emotion: emotion,
                content: request.content
            )
            
            let explainability = PetExplainability(
                signals: signals,
                ruleTriggered: ruleId
            )
            
            // 11. Build response
            let response = PetInferenceResponse(
                emotion: emotion,
                stateDelta: actualDelta,
                behaviorPolicy: policy,
                textResponse: textResponse,
                explainability: explainability
            )
            
            // 12. Persist state if userId provided
            if let userId = request.userId {
                try await repository.updatePetCompanionState(clippedState)
                self.currentState = clippedState
                
                // Persist journal entry if content exists
                if let content = request.content, !content.isEmpty {
                    let journalEntry = PetJournalEntry(
                        userId: userId,
                        content: content,
                        emotion: emotion.primary.rawValue,
                        emotionIntensity: emotion.intensity,
                        emotionConfidence: emotion.confidence,
                        energyDelta: actualDelta.energy,
                        moodDelta: actualDelta.mood,
                        trustDelta: actualDelta.trust,
                        behaviorPolicy: policy.rawValue,
                        policyRuleTriggered: ruleId,
                        signals: signals,
                        textResponse: textResponse
                    )
                    _ = try await repository.createPetJournalEntry(journalEntry)
                }
            }
            
            return response
            
        } catch {
            throw PetCompanionError.inferenceFailed(error)
        }
    }
    
    // MARK: - State Management
    
    /// Apply a state delta directly (replaces POST /state/apply)
    /// - Parameter request: State apply request
    /// - Returns: Updated state
    func applyStateDelta(_ request: PetStateApplyRequest) async throws -> PetCompanionState {
        do {
            let updatedState = try await repository.applyStateDelta(
                userId: request.userId,
                delta: request.delta
            )
            
            self.currentState = updatedState
            return updatedState
        } catch {
            throw PetCompanionError.stateApplyFailed(error)
        }
    }
    
    /// Get user's current companion state
    /// - Parameter userId: User ID
    /// - Returns: Current state
    func getCurrentState(userId: String) async throws -> PetCompanionState {
        do {
            let state = try await repository.getOrCreatePetCompanionState(userId: userId)
            self.currentState = state
            return state
        } catch {
            throw PetCompanionError.getStateFailed(error)
        }
    }
    
    // MARK: - Memory
    
    /// Get user's companion memory
    /// - Parameter userId: User ID
    /// - Returns: Companion memory
    func getCompanionMemory(userId: String) async throws -> PetCompanionMemory? {
        do {
            return try await repository.getPetCompanionMemory(userId: userId)
        } catch {
            throw PetCompanionError.getMemoryFailed(error)
        }
    }
    
    /// Update user's companion memory
    /// - Parameters:
    ///   - userId: User ID
    ///   - weekAvgMood: Weekly average mood
    ///   - dominantEmotion: Dominant emotion
    ///   - talkPreference: Talk preference
    /// - Returns: Updated memory
    func updateCompanionMemory(
        userId: String,
        weekAvgMood: Double? = nil,
        dominantEmotion: String? = nil,
        talkPreference: String? = nil
    ) async throws -> PetCompanionMemory {
        do {
            return try await repository.updatePetCompanionMemory(
                userId: userId,
                weekAvgMood: weekAvgMood,
                dominantEmotion: dominantEmotion,
                talkPreference: talkPreference
            )
        } catch {
            throw PetCompanionError.updateMemoryFailed(error)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Handle silence shortcut (no LLM call needed)
    private func handleSilenceShortcut() -> PetInferenceResponse {
        let emotion = PetDetectedEmotion(primary: .calm, intensity: 0, confidence: 0.1)
        let stateDelta = PetStateDelta(energy: 0, mood: 0, trust: 0)
        let explainability = PetExplainability(
            signals: ["type:silence"],
            ruleTriggered: PetConstants.ruleSilentCompanionSilence
        )
        
        return PetInferenceResponse(
            emotion: emotion,
            stateDelta: stateDelta,
            behaviorPolicy: .silentCompanion,
            textResponse: PetConstants.fallbackText,
            explainability: explainability
        )
    }
    
    /// Generate text response via LLM or fallback
    private func generateTextResponse(
        policy: PetBehaviorPolicy,
        emotion: PetDetectedEmotion,
        state: PetCompanionState,
        contentSummary: String,
        userId: String?
    ) async throws -> String {
        // Try LLM if available
        if let llmService = llmService {
            print("🐾 Attempting LLM generation...")
            do {
                let llmRequest = PetLLMRequest(
                    policy: policy,
                    emotion: emotion,
                    petState: PetCompanionStateSnapshot(from: state),
                    contentSummary: contentSummary
                )

                let llmResponse = try await llmService.generateResponse(llmRequest)

                if let text = llmResponse.textResponse, !text.isEmpty {
                    print("🐾 LLM response received (\(text.count) chars): \(text.prefix(80))...")
                    return text
                } else {
                    print("🐾 LLM returned empty response, using offline fallback")
                }
            } catch {
                // Fall through to offline reply
                print("🐾 LLM generation failed: \(error.localizedDescription)")
                print("🐾 Full error: \(error)")
            }
        } else {
            print("🐾 LLM service not configured, using offline fallback")
        }

        // Fallback to offline reply
        let seed = "\(policy.rawValue)-\(emotion.primary.rawValue)-\(Date().timeIntervalSince1970)"
        return PetOfflineReplies.pickOfflineReply(kind: .general, seed: seed)
    }
    
    /// Build explainability signals
    private func buildExplainabilitySignals(emotion: PetDetectedEmotion, content: String?) -> [String] {
        var signals: [String] = []
        
        // Sentiment signal
        signals.append("sentiment:\(String(format: "%.2f", emotion.sentiment))")
        
        // Keywords signal (extract from content if available)
        if let content = content, !content.isEmpty {
            let keywordMatch = PetEmotionInference.detectKeywords(content)
            if !keywordMatch.keywords.isEmpty {
                let keywords = keywordMatch.keywords.prefix(5).joined(separator: ",")
                signals.append("keywords:\(keywords)")
            }
        }
        
        // Intensity signal
        signals.append("intensity:\(String(format: "%.2f", emotion.intensity))")
        
        return signals
    }
}

// MARK: - Errors

enum PetCompanionError: LocalizedError {
    case inferenceFailed(Error)
    case stateApplyFailed(Error)
    case getStateFailed(Error)
    case getMemoryFailed(Error)
    case updateMemoryFailed(Error)
    case llmNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .inferenceFailed(let error):
            return "Inference failed: \(error.localizedDescription)"
        case .stateApplyFailed(let error):
            return "State apply failed: \(error.localizedDescription)"
        case .getStateFailed(let error):
            return "Failed to get state: \(error.localizedDescription)"
        case .getMemoryFailed(let error):
            return "Failed to get memory: \(error.localizedDescription)"
        case .updateMemoryFailed(let error):
            return "Failed to update memory: \(error.localizedDescription)"
        case .llmNotConfigured:
            return "LLM service not configured"
        }
    }
}
