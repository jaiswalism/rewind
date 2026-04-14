// ContentFilter.swift
import Foundation

class ContentFilter {
    
    // A simplified list of universally objectionable terms that Apple might look for filtering.
    // In a real production system, this could be fetched dynamically or use an ML model.
    private static let objectionableWords: Set<String> = [
        "fuck", "shit", "bitch", "cunt", "nigger", "faggot", "dick", "pussy", 
        "asshole", "whore", "slut", "kill yourself", "kys", "rape", "murder", "kill"
    ]
    
    static func containsObjectionableContent(text: String) -> Bool {
        let lowercasedText = text.lowercased()
        
        // Simple word boundary checking
        for word in objectionableWords {
            if lowercasedText.contains(word) {
                // If we want to be more strict, we can check word boundaries:
                // let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
                // if let _ = lowercasedText.range(of: pattern, options: .regularExpression) { return true }
                return true
            }
        }
        return false
    }
}
