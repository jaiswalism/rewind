import Foundation

// MARK: - Pet Text Filter

/// Filters LLM output for safety
final class PetTextFilter {
    
    /// Filter LLM output for safety
    /// - Parameter text: Text to filter
    /// - Returns: Filtered text or nil if unsafe, with safety metadata
    static func filterLLMOutput(_ text: String?) -> PetLLMResponse {
        guard let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return PetLLMResponse(textResponse: nil, filtered: false)
        }

        print("🐾 [TextFilter] Input text (\(text.count) chars): \(text)")
        
        // Check for forbidden words
        if containsForbiddenWords(text) {
            print("🐾 [TextFilter] REJECTED: Contains forbidden words")
            return PetLLMResponse(
                textResponse: nil,
                filtered: true,
                reason: "Contains forbidden therapist/medical language"
            )
        }

        // Check for absolutes (must, should, always, never)
        if containsAbsoluteLanguage(text) {
            print("🐾 [TextFilter] REJECTED: Contains absolute language")
            return PetLLMResponse(
                textResponse: nil,
                filtered: true,
                reason: "Contains absolute language"
            )
        }

        // Check line count (should be 1-5 lines)
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        print("🐾 [TextFilter] Line count: \(lines.count)")
        if lines.count > PetConstants.maxResponseLines {
            // Truncate to max lines
            let truncated = lines.prefix(PetConstants.maxResponseLines).joined(separator: "\n")
            print("🐾 [TextFilter] TRUNCATED from \(lines.count) to \(PetConstants.maxResponseLines) lines")
            return PetLLMResponse(
                textResponse: truncated,
                filtered: false,
                reason: "Truncated to \(PetConstants.maxResponseLines) lines"
            )
        }

        print("🐾 [TextFilter] ACCEPTED: Text passed all filters")
        return PetLLMResponse(
            textResponse: text.trimmingCharacters(in: .whitespacesAndNewlines),
            filtered: false
        )
    }
    
    // MARK: - Private Methods
    
    /// Check if text contains forbidden words
    private static func containsForbiddenWords(_ text: String) -> Bool {
        let lowerText = text.lowercased()
        return PetConstants.forbiddenWords.contains { word in
            let regex = try? NSRegularExpression(pattern: "\\b\(word)\\b", options: [])
            let range = NSRange(lowerText.startIndex..., in: lowerText)
            let matches = regex?.matches(in: lowerText, options: [], range: range) ?? []
            return !matches.isEmpty
        }
    }
    
    /// Check if text contains absolute language
    private static func containsAbsoluteLanguage(_ text: String) -> Bool {
        let absoluteWords = ["must", "should", "always", "never"]
        let lowerText = text.lowercased()
        return absoluteWords.contains { word in
            let regex = try? NSRegularExpression(pattern: "\\b\(word)\\b", options: [])
            let range = NSRange(lowerText.startIndex..., in: lowerText)
            let matches = regex?.matches(in: lowerText, options: [], range: range) ?? []
            return !matches.isEmpty
        }
    }
}

// MARK: - Pet Offline Replies

/// Provides deterministic offline replies when LLM is unavailable
final class PetOfflineReplies {
    
    /// Pick an offline reply based on kind and seed
    /// - Parameters:
    ///   - kind: Type of offline reply (quota or general)
    ///   - seed: Seed string for deterministic selection
    /// - Returns: Selected offline reply
    static func pickOfflineReply(kind: OfflineReplyKind, seed: String) -> String {
        let list: [String]
        switch kind {
        case .quota:
            list = PetConstants.quotaReplies
        case .general:
            list = PetConstants.generalOfflineReplies
        }
        
        let index = hash32(seed) % list.count
        return list[index]
    }
    
    /// FNV-1a 32-bit hash (safe version)
    private static func hash32(_ input: String) -> Int {
        var hash: UInt32 = 2166136261
        for byte in input.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16777619
        }
        // Safe conversion: use bitwise AND to ensure positive value
        return Int(hash & 0x7FFFFFFF)
    }
}

enum OfflineReplyKind {
    case quota
    case general
}
