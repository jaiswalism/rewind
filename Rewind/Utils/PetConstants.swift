import Foundation

// MARK: - Pet Companion Constants

/// All configuration constants for the pet companion system
enum PetConstants {
    
    // MARK: - Sentiment & Emotion Rules
    
    /// Negative keyword weights for sentiment analysis
    static let negativeKeywordWeights: [String: Double] = [
        "sleep": -0.4,
        "tired": -0.3,
        "exhausted": -0.5,
        "alone": -0.3,
        "lonely": -0.4,
        "anxious": -0.5,
        "anxiety": -0.5,
        "worried": -0.4,
        "stress": -0.4,
        "stressed": -0.4,
        "overwhelmed": -0.6,
        "sad": -0.4,
        "depressed": -0.5,
        "angry": -0.4,
        "frustrated": -0.4,
        "can't": -0.3,
        "cannot": -0.3,
        "couldn't": -0.3,
        "concentrate": -0.3,
        "skipped": -0.3,
        "skip": -0.3,
        "lectures": -0.2,
        "hate": -0.5,
        "terrible": -0.4,
        "awful": -0.4,
        "bad": -0.3
    ]
    
    /// Positive keyword weights for sentiment analysis
    static let positiveKeywordWeights: [String: Double] = [
        "good": 0.3,
        "great": 0.5,
        "excellent": 0.6,
        "proud": 0.5,
        "happy": 0.4,
        "glad": 0.3,
        "grateful": 0.4,
        "thankful": 0.4,
        "better": 0.3,
        "improved": 0.3,
        "accomplished": 0.4,
        "achieved": 0.4,
        "success": 0.4,
        "love": 0.4,
        "enjoy": 0.3,
        "wonderful": 0.5,
        "amazing": 0.5
    ]
    
    /// Keywords that trigger anxious/low emotion classification
    static let anxiousKeywords: Set<String> = [
        "anxious", "anxiety", "worried", "stress", "stressed"
    ]
    
    /// Keywords that trigger overwhelmed emotion classification
    static let overwhelmedKeywords: Set<String> = [
        "overwhelmed"
    ]
    
    // MARK: - Sentiment Thresholds
    
    /// Sentiment score threshold for positive emotion
    static let sentimentThresholdPositive: Double = 0.3
    
    /// Sentiment score threshold for calm emotion (lower bound)
    static let sentimentThresholdCalmLower: Double = -0.2
    
    /// Sentiment score threshold for calm emotion (upper bound)
    static let sentimentThresholdCalmUpper: Double = 0.2
    
    /// Sentiment score threshold for low emotion
    static let sentimentThresholdLow: Double = -0.5
    
    /// Sentiment score threshold for anxious emotion
    static let sentimentThresholdAnxious: Double = -0.4
    
    /// Sentiment score threshold for overwhelmed emotion
    static let sentimentThresholdOverwhelmed: Double = -0.6
    
    // MARK: - Intensity Calculation
    
    /// Weight for exclamation marks in intensity
    static let intensityExclamationWeight: Double = 0.1
    
    /// Weight for caps ratio in intensity
    static let intensityCapsWeight: Double = 0.15
    
    /// Length factor for intensity
    static let intensityLengthFactor: Double = 0.05
    
    /// Max text length for intensity calculation
    static let intensityMaxLength: Int = 1000
    
    // MARK: - State Management
    
    /// Exponential smoothing alpha (0.0 = no smoothing, 1.0 = no smoothing)
    static let smoothingAlpha: Double = 0.3
    
    /// Days inactive threshold before decay starts
    static let decayThresholdDays: Int = 7
    
    /// Energy decay per day (after threshold)
    static let decayEnergyPerDay: Int = -1
    
    /// Mood decay per day (after threshold)
    static let decayMoodPerDay: Int = -1
    
    /// Trust decay per day (after threshold)
    static let decayTrustPerDay: Int = 0
    
    /// Minimum state value
    static let stateMinValue: Int = 0
    
    /// Maximum state value
    static let stateMaxValue: Int = 100
    
    // MARK: - Emotion Deltas
    
    /// Base state deltas for each emotion
    static let emotionDeltas: [PetEmotionType: (energy: Int, mood: Int, trust: Int)] = [
        .calm: (energy: 2, mood: 3, trust: 1),
        .neutral: (energy: 0, mood: 0, trust: 0),
        .low: (energy: -5, mood: -4, trust: -1),
        .anxious: (energy: -3, mood: -5, trust: -2),
        .overwhelmed: (energy: -7, mood: -6, trust: -3),
        .positive: (energy: 4, mood: 5, trust: 2)
    ]
    
    /// Intensity multipliers
    static let intensityMultiplierLow: Double = 0.5    // intensity < 0.3
    static let intensityMultiplierMedium: Double = 1.0 // 0.3 <= intensity < 0.8
    static let intensityMultiplierHigh: Double = 1.5   // intensity >= 0.8
    
    /// Intensity thresholds
    static let intensityThresholdLow: Double = 0.3
    static let intensityThresholdHigh: Double = 0.8
    
    // MARK: - Policy Selection
    
    /// Trust threshold for silent companion policy
    static let policySilentTrustThreshold: Int = 50
    
    /// Intensity threshold for silent companion policy
    static let policySilentIntensityThreshold: Double = 0.5
    
    /// Days inactive threshold for silent companion policy
    static let policySilentDaysInactiveThreshold: Int = 14
    
    /// Mood delta threshold for positive trend
    static let policyPositiveTrendMoodDelta: Int = 4
    
    /// Intensity threshold for ask soft question policy
    static let policyAskSoftQuestionIntensityThreshold: Double = 0.65
    
    /// Trust threshold for ask soft question policy
    static let policyAskSoftQuestionTrustThreshold: Int = 60
    
    // MARK: - Confidence Calculation
    
    /// Weight for sentiment magnitude in confidence
    static let confidenceSentimentWeight: Double = 0.3
    
    /// Weight for keyword strength in confidence
    static let confidenceKeywordWeight: Double = 0.3
    
    /// Weight for intensity in confidence
    static let confidenceIntensityWeight: Double = 0.4
    
    /// Minimum confidence value
    static let confidenceMinValue: Double = 0.1
    
    /// Maximum confidence value
    static let confidenceMaxValue: Double = 1.0
    
    // MARK: - LLM Configuration
    
    /// Default system prompt for LLM
    static let llmSystemPrompt = """
    You are the user's calm virtual companion in a wellness app. Do not claim to be a specific animal or mention cold, ice, snow, or polar settings unless the user brings them up. Always: be brief (1-3 lines), non-judgmental, reflective, and observational. Never diagnose, never give medical/legal/financial advice, never use absolutes such as "always" or "never". Only propose grounding activities if the user explicitly asks for suggestions. If you cannot comply or your output violates these rules, return exactly: "I'm here with you."
    """
    
    /// LLM prompt template
    static let llmPromptTemplate = """
    Policy: %{policy}
    Emotion: %{emotion} intensity %{intensity}
    Companion state: mood %{mood}, energy %{energy}, trust %{trust}
    User content: "%{summary}"
    Produce one short empathetic response following your system guidelines.
    """
    
    /// Max output tokens for LLM
    static let llmMaxOutputTokens: Int = 120
    
    /// Min output tokens for LLM
    static let llmMinOutputTokens: Int = 64
    
    /// Max output tokens upper bound
    static let llmMaxOutputTokensUpperBound: Int = 256
    
    /// LLM temperature
    static let llmTemperature: Double = 0.75
    
    // MARK: - Text Filter
    
    /// Forbidden words in LLM output
    static let forbiddenWords: Set<String> = [
        "must", "should", "always", "never", "cure", "diagnosis", "diagnose",
        "syndrome", "treatment", "therapy", "medication", "prescription",
        "doctor", "therapist", "psychiatrist", "psychologist", "clinical",
        "pathology", "symptom", "disease", "illness"
    ]
    
    /// Max lines in LLM response
    static let maxResponseLines: Int = 5
    
    /// Safe fallback text
    static let fallbackText = "I'm here with you."
    
    // MARK: - Offline Replies
    
    /// Quota-exceeded offline replies
    static let quotaReplies = [
        "The line to the big brain is busy--try again in a minute. I'm still right here.",
        "Connection's a bit fuzzy. Give me a moment and tap again.",
        "I'm listening; the words are just slow to arrive. Try once more soon."
    ]
    
    /// General offline replies
    static let generalOfflineReplies = [
        "I'm here with you.",
        "I'm glad you said something.",
        "That lands gently. I'm beside you.",
        "I hear you. Take your time.",
        "Quiet moment. I'm staying close."
    ]
    
    // MARK: - Policy Rule IDs
    
    /// Rule ID for suggest grounding (explicit request)
    static let ruleSuggestGroundingExplicit = "suggest_grounding_explicit"
    
    /// Rule ID for silent companion (inactive)
    static let ruleSilentCompanionInactive = "silent_companion_inactive"
    
    /// Rule ID for silent companion (silence type)
    static let ruleSilentCompanionSilence = "silent_companion_silence"
    
    /// Rule ID for silent companion (high intensity, low trust)
    static let ruleSilentCompanionHighIntensityLowTrust = "silent_companion_high_intensity_low_trust"
    
    /// Rule ID for silent companion (default)
    static let ruleSilentCompanionDefault = "silent_companion_default"
    
    /// Rule ID for celebrate small win
    static let ruleCelebrateSmallWin = "celebrate_small_win_positive_trend"
    
    /// Rule ID for ask soft question
    static let ruleAskSoftQuestion = "ask_soft_question_repeated_distress"
    
    /// Rule ID for reflect (default)
    static let ruleReflectDefault = "reflect_default"
}
