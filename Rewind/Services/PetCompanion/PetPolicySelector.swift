import Foundation

// MARK: - Pet Policy Selector

/// Selects behavior policy based on context and rules
final class PetPolicySelector {
    
    // MARK: - Public Methods
    
    /// Select behavior policy based on context and rules
    /// - Parameters:
    ///   - emotion: Detected emotion
    ///   - intensity: Emotion intensity (0.0 to 1.0)
    ///   - trust: Current trust level (0 to 100)
    ///   - daysInactive: Days since last interaction
    ///   - inputType: Type of input
    ///   - explicitRequest: Whether user explicitly asked for suggestion
    ///   - moodDelta: Change in mood (optional)
    /// - Returns: Selected policy, whether it allows text response, and the rule ID
    static func selectPolicy(
        emotion: PetEmotionType,
        intensity: Double,
        trust: Int,
        daysInactive: Int,
        inputType: PetInputType,
        explicitRequest: Bool,
        moodDelta: Int? = nil
    ) -> (policy: PetBehaviorPolicy, allowsTextResponse: Bool, ruleId: String) {
        
        // Compute derived context flags
        let positiveTrend = (moodDelta ?? 0) > PetConstants.policyPositiveTrendMoodDelta && emotion == .positive
        let repeatedDistress = intensity > PetConstants.policyAskSoftQuestionIntensityThreshold && emotion != .positive
        
        // Check policies in priority order (highest priority first)
        
        // SUGGEST_GROUNDING - highest priority (explicit request)
        if explicitRequest {
            return (
                policy: .suggestGrounding,
                allowsTextResponse: true,
                ruleId: PetConstants.ruleSuggestGroundingExplicit
            )
        }
        
        // SILENT_COMPANION - high priority (high intensity + low trust, or inactive, or silence)
        if (intensity > PetConstants.policySilentIntensityThreshold && trust < PetConstants.policySilentTrustThreshold) ||
           daysInactive > PetConstants.policySilentDaysInactiveThreshold ||
           inputType == .silence {
            
            var ruleId = PetConstants.ruleSilentCompanionDefault
            if daysInactive > PetConstants.policySilentDaysInactiveThreshold {
                ruleId = PetConstants.ruleSilentCompanionInactive
            } else if inputType == .silence {
                ruleId = PetConstants.ruleSilentCompanionSilence
            } else {
                ruleId = PetConstants.ruleSilentCompanionHighIntensityLowTrust
            }
            
            return (
                policy: .silentCompanion,
                allowsTextResponse: false, // Silent companion uses fallback text
                ruleId: ruleId
            )
        }
        
        // CELEBRATE_SMALL_WIN - positive trend
        if positiveTrend && (moodDelta ?? 0) > PetConstants.policyPositiveTrendMoodDelta {
            return (
                policy: .celebrateSmallWin,
                allowsTextResponse: true,
                ruleId: PetConstants.ruleCelebrateSmallWin
            )
        }
        
        // ASK_SOFT_QUESTION - repeated distress with trust
        if intensity > PetConstants.policyAskSoftQuestionIntensityThreshold &&
           trust > PetConstants.policyAskSoftQuestionTrustThreshold &&
           repeatedDistress {
            return (
                policy: .askSoftQuestion,
                allowsTextResponse: true,
                ruleId: PetConstants.ruleAskSoftQuestion
            )
        }
        
        // REFLECT - default for moderate cases
        return (
            policy: .reflect,
            allowsTextResponse: true,
            ruleId: PetConstants.ruleReflectDefault
        )
    }
}
