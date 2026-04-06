import Foundation
import Supabase
import Combine

@MainActor
final class CareCornerViewModel: ObservableObject {
    static let minimumRewardBreathingSeconds = 60
    static let minimumRewardMeditationSeconds = 120

    @Published var stats: CareCornerStatsData?
    @Published var dailyChallenge: DBDailyChallenge?
    @Published var challengeCompleted = false
    @Published var breathingHistory: [DBBreathingExercise] = []
    @Published var meditationHistory: [DBMeditationSession] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase = SupabaseConfig.shared.client

    private func calculateBreathingPaws(durationSeconds: Int) -> Int {
        guard durationSeconds >= Self.minimumRewardBreathingSeconds else { return 0 }
        return (durationSeconds / 60) * 2
    }

    private func calculateMeditationPaws(durationSeconds: Int) -> Int {
        guard durationSeconds >= Self.minimumRewardMeditationSeconds else { return 0 }
        return (durationSeconds / 60) * 3
    }
    
    struct CareCornerStatsData {
        var totalBreathingExercises: Int
        var totalMeditationSessions: Int
        var totalChallengesCompleted: Int
        var pawsBalance: Int
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
                .like("challenge_date", pattern: "\(today)%")
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
                let templates = [
                    (title: "Mindful Pause", description: "Spend one minute noticing five things around you.", category: "mindfulness"),
                    (title: "Gratitude Reset", description: "Write down one thing that made you smile today.", category: "gratitude"),
                    (title: "Slow Breath Check-In", description: "Take six slow breaths and notice how your body feels.", category: "breathing"),
                    (title: "Quiet Moment", description: "Put your phone face down and sit with the silence for two minutes.", category: "calm")
                ]
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
        guard let challenge = dailyChallenge else { return }
        guard let session = try? await supabase.auth.session else { return }
        
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
        
        // Award paws (10 for completing challenge)
        let currentPaws = try await fetchCurrentPawsBalance(userId: session.user.id)

        struct PawsUpdate: Encodable { var paws_balance: Int }
        let updatedPaws = currentPaws + 10
        try await supabase.from("users")
            .update(PawsUpdate(paws_balance: updatedPaws))
            .eq("id", value: session.user.id.uuidString)
            .execute()
        syncSharedPawsBalance(updatedPaws)
        
        challengeCompleted = true
        await fetchStats()
    }
    
    func recordBreathing(durationSeconds: Int) async throws -> Int {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "CareCornerVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let pawsEarned = calculateBreathingPaws(durationSeconds: durationSeconds)
        
        let exercise = DBBreathingExercise(
            id: UUID(),
            userId: session.user.id,
            durationSeconds: durationSeconds,
            pawsEarned: pawsEarned,
            completedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase.from("breathing_exercises").insert(exercise).execute()
        
        // Update paws
        let currentPaws = try await fetchCurrentPawsBalance(userId: session.user.id)

        struct PawsUpdate: Encodable { var paws_balance: Int }
        let updatedPaws = currentPaws + pawsEarned
        try await supabase.from("users")
            .update(PawsUpdate(paws_balance: updatedPaws))
            .eq("id", value: session.user.id.uuidString)
            .execute()
        syncSharedPawsBalance(updatedPaws)
        
        await fetchStats()
        
        return pawsEarned
    }
    
    func recordMeditation(durationSeconds: Int, soundName: String) async throws -> Int {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "CareCornerVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let pawsEarned = calculateMeditationPaws(durationSeconds: durationSeconds)
        
        let sessionData = DBMeditationSession(
            id: UUID(),
            userId: session.user.id,
            durationSeconds: durationSeconds,
            sessionType: "guided",
            soundName: soundName,
            pawsEarned: pawsEarned,
            completedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase.from("meditation_sessions").insert(sessionData).execute()
        
        // Update paws
        let currentPaws = try await fetchCurrentPawsBalance(userId: session.user.id)

        struct PawsUpdate: Encodable { var paws_balance: Int }
        let updatedPaws = currentPaws + pawsEarned
        try await supabase.from("users")
            .update(PawsUpdate(paws_balance: updatedPaws))
            .eq("id", value: session.user.id.uuidString)
            .execute()
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
}
