import Foundation

struct CareChallengeTemplate {
    let title: String
    let description: String
    let category: String
    let suggestedTags: [String]
    let communityPostDraft: String
}

enum CareChallengeCatalog {
    private struct ChallengeIntent {
        let titlePrefix: String
        let descriptionPrefix: String
        let reflectionPrompt: String
        let tag: String
    }

    private struct ChallengeContext {
        let label: String
        let focus: String
        let category: String
        let tag: String
    }

    static let templates: [CareChallengeTemplate] = {
        var generated: [CareChallengeTemplate] = []

        for intent in intents {
            for context in contexts {
                let title = "\(intent.titlePrefix) - \(context.label)"
                let description = "\(intent.descriptionPrefix) with attention to \(context.focus)."
                let draft = "I completed today's challenge: \(title). What I did: \(description) \(intent.reflectionPrompt)."
                generated.append(
                    CareChallengeTemplate(
                        title: title,
                        description: description,
                        category: context.category,
                        suggestedTags: [intent.tag, context.tag],
                        communityPostDraft: draft
                    )
                )
            }
        }

        return Array(generated.prefix(200))
    }()

    static func template(matching challenge: DBDailyChallenge) -> CareChallengeTemplate? {
        templates.first {
            $0.title == challenge.title &&
            $0.description == challenge.description &&
            $0.category == challenge.category
        }
    }

    private static let intents: [ChallengeIntent] = [
        .init(titlePrefix: "Mindful Pause", descriptionPrefix: "Take one intentional pause", reflectionPrompt: "I noticed this shift in my mood", tag: "MINDFULNESS"),
        .init(titlePrefix: "Slow Breath Cycle", descriptionPrefix: "Complete a slow breathing cycle", reflectionPrompt: "The breath pattern that helped me most was", tag: "STRESS"),
        .init(titlePrefix: "Gratitude Snapshot", descriptionPrefix: "Name one specific thing you appreciate", reflectionPrompt: "Today I felt grateful for", tag: "GRATITUDE"),
        .init(titlePrefix: "Grounding Check-In", descriptionPrefix: "Use a 5-4-3-2-1 grounding pass", reflectionPrompt: "The detail that grounded me was", tag: "ANXIETY"),
        .init(titlePrefix: "Self-Compassion Minute", descriptionPrefix: "Offer yourself one kind sentence", reflectionPrompt: "The kind sentence I needed today was", tag: "MENTAL HEALTH"),
        .init(titlePrefix: "Hydration Reset", descriptionPrefix: "Pause and hydrate mindfully", reflectionPrompt: "After this reset I felt", tag: "DAILY"),
        .init(titlePrefix: "Posture Reset", descriptionPrefix: "Adjust your posture and release tension", reflectionPrompt: "I felt most tension in", tag: "WORK"),
        .init(titlePrefix: "Micro Stretch", descriptionPrefix: "Do a short stretch sequence", reflectionPrompt: "The stretch that helped me most was", tag: "DAILY"),
        .init(titlePrefix: "Digital Boundary", descriptionPrefix: "Step away from screens for a short break", reflectionPrompt: "Stepping away helped me", tag: "WORK"),
        .init(titlePrefix: "Three Deep Breaths", descriptionPrefix: "Take three deep and deliberate breaths", reflectionPrompt: "After the third breath I noticed", tag: "STRESS"),
        .init(titlePrefix: "Mood Label", descriptionPrefix: "Name your current emotion without judgment", reflectionPrompt: "Naming my emotion helped me", tag: "MENTAL HEALTH"),
        .init(titlePrefix: "Body Scan", descriptionPrefix: "Do a quick head-to-toe body scan", reflectionPrompt: "The strongest body signal I noticed was", tag: "ANXIETY"),
        .init(titlePrefix: "Positive Reframe", descriptionPrefix: "Reframe one difficult thought", reflectionPrompt: "I reframed this thought into", tag: "AFFIRMATION"),
        .init(titlePrefix: "Walk And Breathe", descriptionPrefix: "Take a short mindful walk", reflectionPrompt: "While walking I realized", tag: "HAPPINESS"),
        .init(titlePrefix: "Journaling Spark", descriptionPrefix: "Write one line about your current state", reflectionPrompt: "My one-line journal today is", tag: "DAILY"),
        .init(titlePrefix: "Energy Reset", descriptionPrefix: "Take a calm pause before your next task", reflectionPrompt: "This pause changed my energy by", tag: "WORK"),
        .init(titlePrefix: "Quiet Minute", descriptionPrefix: "Sit in silence for one minute", reflectionPrompt: "In that minute of quiet I noticed", tag: "MINDFULNESS"),
        .init(titlePrefix: "Connection Reach-Out", descriptionPrefix: "Send one supportive message", reflectionPrompt: "Connecting with someone made me feel", tag: "RELATIONSHIPS"),
        .init(titlePrefix: "Evening Wind-Down", descriptionPrefix: "Do a short evening calming ritual", reflectionPrompt: "My wind-down ritual tonight is", tag: "ANXIETY"),
        .init(titlePrefix: "Morning Intent", descriptionPrefix: "Set one clear intention for today", reflectionPrompt: "My intention for today is", tag: "AFFIRMATION")
    ]

    private static let contexts: [ChallengeContext] = [
        .init(label: "Morning Start", focus: "starting the day with clarity", category: "mindfulness", tag: "DAILY"),
        .init(label: "Work Break", focus: "resetting between tasks", category: "focus", tag: "WORK"),
        .init(label: "Stressful Moment", focus: "lowering immediate stress", category: "stress", tag: "STRESS"),
        .init(label: "Anxious Thoughts", focus: "calming anxious loops", category: "anxiety", tag: "ANXIETY"),
        .init(label: "Relationship Reflection", focus: "showing up with empathy", category: "connection", tag: "RELATIONSHIPS"),
        .init(label: "Sleep Prep", focus: "winding down before bed", category: "calm", tag: "MENTAL HEALTH"),
        .init(label: "Confidence Boost", focus: "building self-belief", category: "affirmation", tag: "AFFIRMATION"),
        .init(label: "Gratitude Practice", focus: "appreciating small wins", category: "gratitude", tag: "GRATITUDE"),
        .init(label: "Low Energy Reset", focus: "recovering from mental fatigue", category: "energy", tag: "HAPPINESS"),
        .init(label: "Weekend Recharge", focus: "slowing down and recovering", category: "recovery", tag: "DAILY")
    ]
}
