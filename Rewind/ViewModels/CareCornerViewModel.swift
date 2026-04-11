import Foundation
import Supabase
import Combine

@MainActor
final class CareCornerViewModel: ObservableObject {

    @Published var stats: CareCornerStatsData?
    @Published var dailyChallenge: DBDailyChallenge?
    @Published var challengeCompleted = false
    @Published var breathingHistory: [DBBreathingExercise] = []
    @Published var meditationHistory: [DBMeditationSession] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase = SupabaseConfig.shared.client

    private func executeWithRetry<T>(attempts: Int = 3, operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        for attempt in 1...attempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < attempts {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 350_000_000)
                }
            }
        }
        throw lastError ?? NSError(domain: "CareCornerVM", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown retry failure"])
    }
    
    struct CareCornerStatsData {
        var totalBreathingExercises: Int
        var totalMeditationSessions: Int
        var totalChallengesCompleted: Int
        var pawsBalance: Int
    }

    struct ChallengeCommunityPrefill {
        let text: String
        let tags: [String]
    }

    private struct UserPawsRow: Decodable {
        let paws_balance: Int?
    }

    private func fetchCurrentPawsBalance(userId: UUID) async throws -> Int {
        let rows: [UserPawsRow] = try await supabase.from("users")
            .select("paws_balance")
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        return rows.first?.paws_balance ?? 0
    }

    private func syncSharedPawsBalance(_ newBalance: Int) {
        var currentUser = UserViewModel.shared.user
        currentUser?.pawsBalance = newBalance
        UserViewModel.shared.user = currentUser
    }

    func communityPrefillForCurrentChallenge() -> ChallengeCommunityPrefill? {
        guard let challenge = dailyChallenge else { return nil }

        if let template = CareChallengeCatalog.template(matching: challenge) {
            return ChallengeCommunityPrefill(text: template.communityPostDraft, tags: template.suggestedTags)
        }

        let fallbackText = "I completed today's challenge: \(challenge.title). What I did: \(challenge.description) What helped me most today was:"
        return ChallengeCommunityPrefill(text: fallbackText, tags: [tagForCategory(challenge.category)])
    }

    func communityPrefillFallbackForToday() -> ChallengeCommunityPrefill {
        let templates = CareChallengeCatalog.templates
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let template = templates[dayIndex % templates.count]
        let text = "I completed today's challenge: \(template.title). What I did: \(template.description) What helped me most today was:"
        return ChallengeCommunityPrefill(text: text, tags: template.suggestedTags)
    }

    private func tagForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "stress":
            return "STRESS"
        case "anxiety", "calm":
            return "ANXIETY"
        case "gratitude":
            return "GRATITUDE"
        case "connection", "relationships":
            return "RELATIONSHIPS"
        case "affirmation":
            return "AFFIRMATION"
        case "focus", "work":
            return "WORK"
        case "mindfulness", "mental_health", "mental health":
            return "MENTAL HEALTH"
        default:
            return "DAILY"
        }
    }
    
    func fetchStats() async {
        isLoading = true
        
        do {
            guard let session = try? await supabase.auth.session else { return }
            
            async let breathingCount = supabase.from("breathing_exercises")
                .select("*", head: true)
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
            
            async let meditationCount = supabase.from("meditation_sessions")
                .select("*", head: true)
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
            
            async let challengeCount = supabase.from("user_challenge_completions")
                .select("*", head: true)
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
            
            async let userResponse: [UserPawsRow] = supabase.from("users")
                .select("paws_balance")
                .eq("id", value: session.user.id.uuidString)
                .execute()
                .value
            
            let (breathing, meditation, challenge, users) = try await (breathingCount, meditationCount, challengeCount, userResponse)
            
            stats = CareCornerStatsData(
                totalBreathingExercises: breathing.count ?? 0,
                totalMeditationSessions: meditation.count ?? 0,
                totalChallengesCompleted: challenge.count ?? 0,
                pawsBalance: users.first?.paws_balance ?? 0
            )
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchDailyChallenge() async {
        isLoading = true
        
        do {
            let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
            
            let responseResp: [DBDailyChallenge] = try await supabase.from("daily_challenges")
                .select("*")
                .eq("created_for_date", value: String(today))
                .execute()
                .value
            let response = responseResp
            
            if let challenge = response.first {
                dailyChallenge = challenge
                
                // Check if user completed it
                guard let session = try? await supabase.auth.session else { return }
                
                let completionsResp: [DBUserChallengeCompletion] = try await supabase.from("user_challenge_completions")
                    .select("*")
                    .eq("challenge_id", value: challenge.id.uuidString)
                    .eq("user_id", value: session.user.id.uuidString)
                    .execute()
                    .value
                let completions = completionsResp
                
                challengeCompleted = !completions.isEmpty
            } else {
                let templates = CareChallengeCatalog.templates
                let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
                let template = templates[dayIndex % templates.count]

                let newChallenge = DBDailyChallenge(
                    id: UUID(),
                    title: template.title,
                    description: template.description,
                    category: template.category,
                    points: 10,
                    createdForDate: String(today)
                )
                
                try await supabase.from("daily_challenges").insert(newChallenge).execute()
                dailyChallenge = newChallenge
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func completeChallenge() async throws {
        if dailyChallenge == nil {
            await fetchDailyChallenge()
        }

        guard let challenge = dailyChallenge else {
            throw NSError(
                domain: "CareCornerVM",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Today's challenge is unavailable right now."]
            )
        }

        guard let session = try? await supabase.auth.session else {
            throw NSError(
                domain: "CareCornerVM",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "You need to be signed in to complete challenges."]
            )
        }
        
        // Check if already completed
        let existingResp: [DBUserChallengeCompletion] = try await supabase.from("user_challenge_completions")
            .select("*")
            .eq("challenge_id", value: challenge.id.uuidString)
            .eq("user_id", value: session.user.id.uuidString)
            .execute()
            .value
        let existing = existingResp
        
        if !existing.isEmpty {
            return
        }
        
        let completion = DBUserChallengeCompletion(
            id: UUID(),
            userId: session.user.id,
            challengeId: challenge.id,
            completedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase.from("user_challenge_completions").insert(completion).execute()
        
        // Award paws (use points from the challenge)
        let rewardPoints = challenge.points
        let currentPaws = try await fetchCurrentPawsBalance(userId: session.user.id)

        struct PawsUpdate: Encodable { var paws_balance: Int }
        let updatedPaws = currentPaws + rewardPoints
        try await supabase.from("users")
            .update(PawsUpdate(paws_balance: updatedPaws))
            .eq("id", value: session.user.id.uuidString)
            .execute()
        syncSharedPawsBalance(updatedPaws)

        challengeCompleted = true
        await fetchStats()

        // Trigger pet companion inference in background so completion UX stays responsive.
        _ = Task(priority: .utility) {
            await self.inferPetCompanionChallenge(challenge: challenge)
        }
    }
    
    func recordBreathing(durationSeconds: Int) async throws -> Int {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "CareCornerVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

    let pawsEarned = PawsCalculator.calculateBreathingPaws(durationSeconds: durationSeconds)
        
        let exercise = DBBreathingExercise(
            id: UUID(),
            userId: session.user.id,
            durationSeconds: durationSeconds,
            pawsEarned: pawsEarned,
            completedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        _ = try await executeWithRetry {
            try await self.supabase.from("breathing_exercises").insert(exercise).execute()
        }
        
        // Update paws
        let currentPaws = try await executeWithRetry {
            try await self.fetchCurrentPawsBalance(userId: session.user.id)
        }

        struct PawsUpdate: Encodable { var paws_balance: Int }
        let updatedPaws = currentPaws + pawsEarned
        _ = try await executeWithRetry {
            try await self.supabase.from("users")
                .update(PawsUpdate(paws_balance: updatedPaws))
                .eq("id", value: session.user.id.uuidString)
                .execute()
        }
        syncSharedPawsBalance(updatedPaws)
        
        await fetchStats()
        
        return pawsEarned
    }
    
    func recordMeditation(durationSeconds: Int, soundName: String) async throws -> Int {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "CareCornerVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

    let pawsEarned = PawsCalculator.calculateMeditationPaws(durationSeconds: durationSeconds)
        
        let sessionData = DBMeditationSession(
            id: UUID(),
            userId: session.user.id,
            durationSeconds: durationSeconds,
            sessionType: "guided",
            soundName: soundName,
            pawsEarned: pawsEarned,
            completedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        _ = try await executeWithRetry {
            try await self.supabase.from("meditation_sessions").insert(sessionData).execute()
        }
        
        // Update paws
        let currentPaws = try await executeWithRetry {
            try await self.fetchCurrentPawsBalance(userId: session.user.id)
        }

        struct PawsUpdate: Encodable { var paws_balance: Int }
        let updatedPaws = currentPaws + pawsEarned
        _ = try await executeWithRetry {
            try await self.supabase.from("users")
                .update(PawsUpdate(paws_balance: updatedPaws))
                .eq("id", value: session.user.id.uuidString)
                .execute()
        }
        syncSharedPawsBalance(updatedPaws)
        
        await fetchStats()
        
        return pawsEarned
    }
    
    func fetchHistory() async {
        isLoading = true
        
        do {
            guard let session = try? await supabase.auth.session else { return }
            
            async let breathing: [DBBreathingExercise] = supabase.from("breathing_exercises")
                .select("*")
                .eq("user_id", value: session.user.id.uuidString)
                .order("completed_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            async let meditation: [DBMeditationSession] = supabase.from("meditation_sessions")
                .select("*")
                .eq("user_id", value: session.user.id.uuidString)
                .order("completed_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            if let bResponse = try? await breathing {
                breathingHistory = bResponse
            }
            
            if let mResponse = try? await meditation {
                meditationHistory = mResponse
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Pet Companion Integration
    
    /// Trigger pet companion inference after challenge completion
    private func inferPetCompanionChallenge(challenge: DBDailyChallenge) async {
        do {
            guard let userId = UserViewModel.shared.user?.id else { return }
            
            let timeOfDay = currentTimeOfDay()
            let content = "Completed challenge: \(challenge.title)"
            let request = PetInferenceRequest(
                type: .checkin,
                content: content,
                explicitRequest: false,
                context: PetInferenceContext(
                    timeOfDay: timeOfDay,
                    daysInactive: 0
                ),
                userId: userId.uuidString
            )
            
            let response = try await PetCompanionService.shared.infer(request)
            print("🐾 Pet companion challenge: emotion=\(response.emotion.primary), policy=\(response.behaviorPolicy)")
        } catch {
            print("🐾 Pet companion challenge inference failed: \(error.localizedDescription)")
        }
    }
    
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
