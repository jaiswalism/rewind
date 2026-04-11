import Foundation

// MARK: - Enums & Types

/// Input type for companion inference
enum PetInputType: String, Codable, CaseIterable {
    case checkin
    case journal
    case message
    case breathing
    case silence
}

/// Time of day for context
enum PetTimeOfDay: String, Codable, CaseIterable {
    case morning
    case afternoon
    case evening
    case night
}

/// Primary emotion detected in user input
enum PetEmotionType: String, Codable, CaseIterable {
    case calm
    case neutral
    case low
    case anxious
    case overwhelmed
    case positive
}

/// Behavior policy selected for response
enum PetBehaviorPolicy: String, Codable, CaseIterable {
    case silentCompanion = "SILENT_COMPANION"
    case reflect = "REFLECT"
    case askSoftQuestion = "ASK_SOFT_QUESTION"
    case celebrateSmallWin = "CELEBRATE_SMALL_WIN"
    case suggestGrounding = "SUGGEST_GROUNDING"
}

// MARK: - Database Models

/// Pet companion state tracked per user (energy, mood, trust)
struct PetCompanionState: Codable, Identifiable {
    let id: String?
    let userId: String
    var energy: Int
    var mood: Int
    var trust: Int
    let lastUpdated: Date?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case energy
        case mood
        case trust
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
    
    init(id: String? = nil, userId: String, energy: Int = 50, mood: Int = 50, trust: Int = 50, lastUpdated: Date? = nil, createdAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.energy = energy
        self.mood = mood
        self.trust = trust
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
    }
}

/// Aggregated behavioral patterns for personalization
struct PetCompanionMemory: Codable, Identifiable {
    let id: String?
    let userId: String
    var weekAvgMood: Double?
    var dominantEmotion: String?
    var talkPreference: String?
    let lastUpdated: Date?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekAvgMood = "week_avg_mood"
        case dominantEmotion = "dominant_emotion"
        case talkPreference = "talk_preference"
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
    
    init(id: String? = nil, userId: String, weekAvgMood: Double? = nil, dominantEmotion: String? = nil, talkPreference: String? = nil, lastUpdated: Date? = nil, createdAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.weekAvgMood = weekAvgMood
        self.dominantEmotion = dominantEmotion
        self.talkPreference = talkPreference
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
    }
}

/// Journal entry with emotion inference metadata
struct PetJournalEntry: Codable, Identifiable {
    let id: String?
    let userId: String
    let content: String
    let emotion: String?
    let emotionIntensity: Double?
    let emotionConfidence: Double?
    let energyDelta: Int?
    let moodDelta: Int?
    let trustDelta: Int?
    let behaviorPolicy: String?
    let policyRuleTriggered: String?
    let signals: [String]?
    let textResponse: String?
    let encrypted: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case emotion
        case emotionIntensity = "emotion_intensity"
        case emotionConfidence = "emotion_confidence"
        case energyDelta = "energy_delta"
        case moodDelta = "mood_delta"
        case trustDelta = "trust_delta"
        case behaviorPolicy = "behavior_policy"
        case policyRuleTriggered = "policy_rule_triggered"
        case signals
        case textResponse = "text_response"
        case encrypted
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: String? = nil, userId: String, content: String, emotion: String? = nil, emotionIntensity: Double? = nil, emotionConfidence: Double? = nil, energyDelta: Int? = nil, moodDelta: Int? = nil, trustDelta: Int? = nil, behaviorPolicy: String? = nil, policyRuleTriggered: String? = nil, signals: [String]? = nil, textResponse: String? = nil, encrypted: Bool = false, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.content = content
        self.emotion = emotion
        self.emotionIntensity = emotionIntensity
        self.emotionConfidence = emotionConfidence
        self.energyDelta = energyDelta
        self.moodDelta = moodDelta
        self.trustDelta = trustDelta
        self.behaviorPolicy = behaviorPolicy
        self.policyRuleTriggered = policyRuleTriggered
        self.signals = signals
        self.textResponse = textResponse
        self.encrypted = encrypted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Inference Request/Response Models

/// Context for inference request
struct PetInferenceContext: Codable {
    let timeOfDay: PetTimeOfDay
    let daysInactive: Int
    let lastPolicy: PetBehaviorPolicy?
    let state: PetCompanionStateSnapshot?
    
    enum CodingKeys: String, CodingKey {
        case timeOfDay = "time_of_day"
        case daysInactive = "days_inactive"
        case lastPolicy = "last_policy"
        case state
    }
    
    init(timeOfDay: PetTimeOfDay, daysInactive: Int = 0, lastPolicy: PetBehaviorPolicy? = nil, state: PetCompanionStateSnapshot? = nil) {
        self.timeOfDay = timeOfDay
        self.daysInactive = daysInactive
        self.lastPolicy = lastPolicy
        self.state = state
    }
}

/// Snapshot of companion state for inference
struct PetCompanionStateSnapshot: Codable {
    let energy: Int
    let mood: Int
    let trust: Int
    
    init(energy: Int = 50, mood: Int = 50, trust: Int = 50) {
        self.energy = energy
        self.mood = mood
        self.trust = trust
    }
    
    init(from state: PetCompanionState) {
        self.energy = state.energy
        self.mood = state.mood
        self.trust = state.trust
    }
}

/// Inference request payload
struct PetInferenceRequest: Codable {
    let type: PetInputType
    let content: String?
    let explicitRequest: Bool
    let context: PetInferenceContext
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case content
        case explicitRequest = "explicit_request"
        case context
        case userId = "user_id"
    }
    
    init(type: PetInputType, content: String? = nil, explicitRequest: Bool = false, context: PetInferenceContext, userId: String? = nil) {
        self.type = type
        self.content = content
        self.explicitRequest = explicitRequest
        self.context = context
        self.userId = userId
    }
}

/// Detected emotion with metadata
struct PetDetectedEmotion: Codable {
    let primary: PetEmotionType
    let intensity: Double  // 0.0 to 1.0
    let confidence: Double // 0.0 to 1.0
    let sentiment: Double  // -1.0 to 1.0
    
    init(primary: PetEmotionType, intensity: Double, confidence: Double, sentiment: Double = 0) {
        self.primary = primary
        self.intensity = intensity
        self.confidence = confidence
        self.sentiment = sentiment
    }
}

/// State delta from emotion
struct PetStateDelta: Codable {
    let energy: Int
    let mood: Int
    let trust: Int
    
    init(energy: Int = 0, mood: Int = 0, trust: Int = 0) {
        self.energy = energy
        self.mood = mood
        self.trust = trust
    }
}

/// Explainability metadata
struct PetExplainability: Codable {
    let signals: [String]
    let ruleTriggered: String
    
    enum CodingKeys: String, CodingKey {
        case signals
        case ruleTriggered = "rule_triggered"
    }
    
    init(signals: [String], ruleTriggered: String) {
        self.signals = signals
        self.ruleTriggered = ruleTriggered
    }
}

/// Complete inference response
struct PetInferenceResponse: Codable {
    let emotion: PetDetectedEmotion
    let stateDelta: PetStateDelta
    let behaviorPolicy: PetBehaviorPolicy
    let textResponse: String?
    let explainability: PetExplainability
    
    enum CodingKeys: String, CodingKey {
        case emotion
        case stateDelta = "penguin_state_delta"
        case behaviorPolicy = "behavior_policy"
        case textResponse = "text_response"
        case explainability
    }
    
    init(emotion: PetDetectedEmotion, stateDelta: PetStateDelta, behaviorPolicy: PetBehaviorPolicy, textResponse: String?, explainability: PetExplainability) {
        self.emotion = emotion
        self.stateDelta = stateDelta
        self.behaviorPolicy = behaviorPolicy
        self.textResponse = textResponse
        self.explainability = explainability
    }
}

/// State apply request
struct PetStateApplyRequest: Codable {
    let userId: String
    let delta: PetStateDelta
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case delta
    }
    
    init(userId: String, delta: PetStateDelta) {
        self.userId = userId
        self.delta = delta
    }
}

/// LLM generation request
struct PetLLMRequest: Codable {
    let policy: PetBehaviorPolicy
    let emotion: PetDetectedEmotion
    let petState: PetCompanionStateSnapshot
    let contentSummary: String
    
    enum CodingKeys: String, CodingKey {
        case policy
        case emotion
        case petState = "penguin_state"
        case contentSummary = "content_summary"
    }
    
    init(policy: PetBehaviorPolicy, emotion: PetDetectedEmotion, petState: PetCompanionStateSnapshot, contentSummary: String) {
        self.policy = policy
        self.emotion = emotion
        self.petState = petState
        self.contentSummary = contentSummary
    }
}

/// LLM generation response
struct PetLLMResponse: Codable {
    let textResponse: String?
    let filtered: Bool
    let reason: String?
    
    enum CodingKeys: String, CodingKey {
        case textResponse = "text_response"
        case filtered
        case reason
    }
    
    init(textResponse: String?, filtered: Bool = false, reason: String? = nil) {
        self.textResponse = textResponse
        self.filtered = filtered
        self.reason = reason
    }
}
