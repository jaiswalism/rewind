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
    
    struct CareCornerStatsData {
        var totalBreathingExercises: Int
        var totalMeditationSessions: Int
        var totalChallengesCompleted: Int
        var pawsBalance: Int
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
            
            async let userResponse: [DBUser] = supabase.from("users")
                .select("paws_balance")
                .eq("id", value: session.user.id.uuidString)
                .execute()
                .value
            
            let (breathing, meditation, challenge, users) = try await (breathingCount, meditationCount, challengeCount, userResponse)
            
            stats = CareCornerStatsData(
                totalBreathingExercises: breathing.count ?? 0,
                totalMeditationSessions: meditation.count ?? 0,
                totalChallengesCompleted: challenge.count ?? 0,
                pawsBalance: users.first?.pawsBalance ?? 0
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
                .like("challenge_date", value: "\(today)%")
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
                // Create today's challenge
                let newChallenge = DBDailyChallenge(
                    id: UUID(),
                    title: "Daily Mindfulness",
                    description: "Take a moment to practice gratitude today",
                    category: "mindfulness",
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
        struct PawsUpdate: Encodable { var paws_balance: Int }
        try await supabase.from("users")
            .update(PawsUpdate(paws_balance: (stats?.pawsBalance ?? 0) + 10))
            .eq("id", value: session.user.id.uuidString)
            .execute()
        
        challengeCompleted = true
        await fetchStats()
    }
    
    func recordBreathing(durationSeconds: Int) async throws -> Int {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "CareCornerVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let minutes = durationSeconds / 60
        let pawsEarned = minutes * 2 // 2 paws per minute
        
        let durationString = String(format: "%d:%02d", minutes, durationSeconds % 60)
        
        let exercise = DBBreathingExercise(
            id: UUID(),
            userId: session.user.id,
            durationSeconds: durationSeconds,
            pawsEarned: pawsEarned,
            completedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase.from("breathing_exercises").insert(exercise).execute()
        
        // Update paws
        struct PawsUpdate: Encodable { var paws_balance: Int }
        try await supabase.from("users")
            .update(PawsUpdate(paws_balance: (stats?.pawsBalance ?? 0) + pawsEarned))
            .eq("id", value: session.user.id.uuidString)
            .execute()
        
        await fetchStats()
        
        return pawsEarned
    }
    
    func recordMeditation(durationSeconds: Int, soundName: String) async throws -> Int {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "CareCornerVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let minutes = durationSeconds / 60
        let pawsEarned = minutes * 3 // 3 paws per minute
        
        let durationString = String(format: "%d:%02d", minutes, durationSeconds % 60)
        
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
        struct PawsUpdate: Encodable { var paws_balance: Int }
        try await supabase.from("users")
            .update(PawsUpdate(paws_balance: (stats?.pawsBalance ?? 0) + pawsEarned))
            .eq("id", value: session.user.id.uuidString)
            .execute()
        
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
