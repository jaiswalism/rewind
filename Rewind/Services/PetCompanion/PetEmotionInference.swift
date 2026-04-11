import Foundation

// MARK: - Pet Emotion Inference

/// Infers emotion from user content using deterministic rules
final class PetEmotionInference {
    
    // MARK: - Public Methods
    
    /// Infer emotion from content using deterministic rules
    /// - Parameters:
    ///   - content: The text content to analyze
    ///   - type: The type of input (checkin, journal, etc.)
    /// - Returns: Inference result with emotion, intensity, confidence, and sentiment
    static func inferEmotion(content: String?, type: PetInputType) -> PetDetectedEmotion {
        let sentiment = computeSentiment(content)
        let intensity = calculateIntensity(content)
        let keywordMatch = detectKeywords(content)
        
        let thresholds = sentimentThresholds
        
        // Determine primary emotion based on sentiment and keywords
        var primary: PetEmotionType
        
        // Check for specific keyword-based emotions first (prioritize keywords over sentiment)
        if keywordMatch.keywords.contains(where: PetConstants.anxiousKeywords.contains) {
            primary = sentiment < thresholds.anxious ? .anxious : .low
        } else if keywordMatch.keywords.contains(where: PetConstants.overwhelmedKeywords.contains) {
            primary = .overwhelmed
        } else if keywordMatch.category == .negative && keywordMatch.totalWeight > 0.3 {
            // If we have significant negative keywords, prioritize negative emotion
            if sentiment <= thresholds.overwhelmed {
                primary = .overwhelmed
            } else if sentiment <= thresholds.low {
                primary = .low
            } else {
                primary = .anxious
            }
        } else if sentiment <= thresholds.overwhelmed {
            primary = .overwhelmed
        } else if sentiment <= thresholds.low {
            primary = .low
        } else if sentiment >= thresholds.positive {
            primary = .positive
        } else if sentiment >= thresholds.neutralLower && sentiment <= thresholds.neutralUpper {
            primary = .calm
        } else {
            primary = .neutral
        }
        
        // Special handling for silence/breathing types
        if type == .silence || type == .breathing {
            primary = .calm
        }
        
        // Calculate confidence based on signal strength
        let sentimentMagnitude = abs(sentiment)
        let keywordStrength: Double = keywordMatch.keywords.isEmpty ? 0 : 0.3
        let intensityContribution = intensity * 0.4
        let confidence = min(
            sentimentMagnitude * 0.3 + keywordStrength + intensityContribution,
            1.0
        )
        
        return PetDetectedEmotion(
            primary: primary,
            intensity: max(0, min(1, intensity)),
            confidence: max(PetConstants.confidenceMinValue, min(PetConstants.confidenceMaxValue, confidence)),
            sentiment: sentiment // Include sentiment for explainability
        )
    }
    
    // MARK: - Private Methods
    
    /// Compute sentiment score from text content
    /// Returns normalized score between -1 (very negative) and +1 (very positive)
    private static func computeSentiment(_ content: String?) -> Double {
        guard let content = content, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 0
        }
        
        let text = content.lowercased()
        var score: Double = 0
        var matchCount = 0
        
        // Check negative keywords
        for (word, weight) in PetConstants.negativeKeywordWeights {
            let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b", options: [])
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex?.matches(in: text, options: [], range: range) ?? []
            if !matches.isEmpty {
                score += weight * Double(matches.count)
                matchCount += matches.count
            }
        }
        
        // Check positive keywords
        for (word, weight) in PetConstants.positiveKeywordWeights {
            let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b", options: [])
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex?.matches(in: text, options: [], range: range) ?? []
            if !matches.isEmpty {
                score += weight * Double(matches.count)
                matchCount += matches.count
            }
        }
        
        // Normalize by match count if we have matches
        if matchCount > 0 {
            score = score / Double(matchCount)
        }
        
        // Clamp to [-1, 1]
        return max(-1, min(1, score))
    }
    
    /// Calculate intensity from various text features
    private static func calculateIntensity(_ content: String?) -> Double {
        guard let content = content, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 0
        }
        
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Exclamation count
        let exclamationCount = text.filter { $0 == "!" }.count
        let exclamationScore = min(Double(exclamationCount) * PetConstants.intensityExclamationWeight, 0.3)
        
        // Caps ratio
        let capsCount = text.filter { $0.isUppercase }.count
        let capsRatio = text.isEmpty ? 0 : Double(capsCount) / Double(text.count)
        let capsScore = min(capsRatio * PetConstants.intensityCapsWeight, 0.2)
        
        // Length factor (longer texts may indicate more emotional content)
        let normalizedLength = min(Double(text.count) / Double(PetConstants.intensityMaxLength), 1)
        let lengthScore = normalizedLength * PetConstants.intensityLengthFactor
        
        // Sentiment magnitude
        let sentiment = computeSentiment(content)
        let sentimentMagnitude = abs(sentiment)
        
        // Combine factors - increased weight on sentiment magnitude for better detection
        let intensity = min(
            sentimentMagnitude * 0.7 + exclamationScore + capsScore + lengthScore,
            1.0
        )
        
        return max(0, min(1, intensity))
    }
    
    /// Detect keywords in content and return matches
    internal static func detectKeywords(_ content: String?) -> KeywordMatch {
        guard let content = content, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return KeywordMatch(keywords: [], category: .positive, totalWeight: 0)
        }
        
        let text = content.lowercased()
        
        var foundNegative: [String] = []
        var foundPositive: [String] = []
        var negativeWeight: Double = 0
        var positiveWeight: Double = 0
        
        // Check negative keywords
        for (word, weight) in PetConstants.negativeKeywordWeights {
            let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b", options: [])
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex?.matches(in: text, options: [], range: range) ?? []
            if !matches.isEmpty {
                foundNegative.append(word)
                negativeWeight += abs(weight)
            }
        }
        
        // Check positive keywords
        for (word, weight) in PetConstants.positiveKeywordWeights {
            let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b", options: [])
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex?.matches(in: text, options: [], range: range) ?? []
            if !matches.isEmpty {
                foundPositive.append(word)
                positiveWeight += weight
            }
        }
        
        // Determine dominant category
        if negativeWeight > positiveWeight {
            return KeywordMatch(
                keywords: foundNegative,
                category: .negative,
                totalWeight: negativeWeight
            )
        } else if positiveWeight > 0 {
            return KeywordMatch(
                keywords: foundPositive,
                category: .positive,
                totalWeight: positiveWeight
            )
        }
        
        return KeywordMatch(keywords: [], category: .positive, totalWeight: 0)
    }
    
    // MARK: - Sentiment Thresholds
    
    private static var sentimentThresholds: (positive: Double, neutralLower: Double, neutralUpper: Double, low: Double, anxious: Double, overwhelmed: Double) {
        return (
            positive: PetConstants.sentimentThresholdPositive,
            neutralLower: PetConstants.sentimentThresholdCalmLower,
            neutralUpper: PetConstants.sentimentThresholdCalmUpper,
            low: PetConstants.sentimentThresholdLow,
            anxious: PetConstants.sentimentThresholdAnxious,
            overwhelmed: PetConstants.sentimentThresholdOverwhelmed
        )
    }
}

// MARK: - Keyword Match Helper

extension PetEmotionInference {
    struct KeywordMatch {
        let keywords: [String]
        let category: KeywordCategory
        let totalWeight: Double
        
        enum KeywordCategory {
            case negative
            case positive
        }
    }
}
