import Foundation
import UIKit
import Supabase
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var currentUser: DBUser?
    @Published var isLoggedIn = false
    @Published var error: String?
    
    private let supabase = SupabaseConfig.shared.client
    private let initialPawsBalance = 100
    
    init() {
        Task {
            await checkCurrentSession()
        }
    }

    func getSession() async -> Session? {
        try? await supabase.auth.session
    }
    
    func checkCurrentSession() async {
        if await getSession() != nil {
            isLoggedIn = true
            await fetchCurrentUser()
        } else {
            isLoggedIn = false
        }
    }
    
    func register(name: String, email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            let now = ISO8601DateFormatter().string(from: Date())

            try await seedInitialPawsBalance(userId: session.user.id, updatedAt: now)
            
            let newUser = DBUser(
                id: session.user.id,
                name: name,
                email: email,
                phone: nil,
                profileImageUrl: nil,
                timezone: nil,
                location: nil,
                dateOfBirth: nil,
                gender: nil,
                age: nil,
                healthGoal: nil,
                seekingProfessionalHelp: false,
                pawsBalance: 100,
                totalPosts: 0,
                onboardingCompleted: false,
                createdAt: now,
                updatedAt: now
            )
            
            // Note: We skip the explicit supabase.from("users").insert(newUser) here because
            // the database 'handle_new_user' Auth Trigger creates the schema row automatically!
            // Passing 'name' as metadata above allows the DB trigger to populate the 'name' column.
            
            currentUser = newUser
            isLoggedIn = true
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    func login(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            _ = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            isLoggedIn = true
            await fetchCurrentUser()
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func signInWithOAuth(provider: Provider) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signInWithOAuth(
                provider: provider,
                redirectTo: Constants.Auth.oauthRedirectURL
            )

            // Newer Supabase SDKs complete OAuth and return a session directly.
            isLoggedIn = true
            await ensureInitialPawsBalanceForNewUser(userId: session.user.id)
            await fetchCurrentUser()
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    private func seedInitialPawsBalance(userId: UUID, updatedAt: String) async throws {
        struct InitialPawsUpdate: Encodable {
            var paws_balance: Int
            var updated_at: String
        }

        let payload = InitialPawsUpdate(paws_balance: initialPawsBalance, updated_at: updatedAt)
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                try await supabase.from("users")
                    .update(payload)
                    .eq("id", value: userId.uuidString)
                    .execute()
                return
            } catch {
                lastError = error
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
            }
        }
        
        if let lastError = lastError {
            throw lastError
        }
    }

    private func ensureInitialPawsBalanceForNewUser(userId: UUID) async {
        struct UserBootstrapSnapshot: Decodable {
            let paws_balance: Int?
            let onboarding_completed: Bool?
            let total_posts: Int?
            let created_at: String?
        }

        guard
            let snapshot: UserBootstrapSnapshot = try? await supabase.from("users")
                .select("paws_balance,onboarding_completed,total_posts,created_at")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
        else {
            return
        }

        let hasNoPawsYet = (snapshot.paws_balance ?? 0) <= 0
        let hasNoPosts = (snapshot.total_posts ?? 0) == 0
        let hasNotOnboarded = snapshot.onboarding_completed != true

        var createdRecently = false
        if let createdAt = snapshot.created_at,
           let createdDate = ISO8601DateFormatter().date(from: createdAt) {
            createdRecently = Date().timeIntervalSince(createdDate) <= 900
        }

        guard hasNoPawsYet && hasNoPosts && hasNotOnboarded && createdRecently else {
            return
        }

        do {
            try await seedInitialPawsBalance(
                userId: userId,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
        } catch {
            print("Failed to seed initial paws balance: \(error)")
            self.error = "Error setting initial balance: \(error.localizedDescription)"
        }
    }
    
    func logout() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isLoggedIn = false
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func forgotPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    private func fetchCurrentUser() async {
        guard let session = try? await supabase.auth.session else { return }
        
        do {
            let responseResp: [DBUser] = try await supabase.from("users")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .execute()
                .value
            
            await MainActor.run {
                self.currentUser = responseResp.first
            }
        } catch let DecodingError.dataCorrupted(context) {
            print(context)
            self.error = "Data corrupted: \(context.debugDescription)"
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found:", context.debugDescription)
            self.error = "Missing field: \(key.stringValue)"
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found:", context.debugDescription)
            self.error = "Missing value for: \(context.codingPath.last?.stringValue ?? "")"
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type '\(type)' mismatch:", context.debugDescription)
            self.error = "Type mismatch for: \(context.codingPath.last?.stringValue ?? "")"
        } catch {
            print("Other error: \(error)")
            self.error = error.localizedDescription
        }
    }
    
    func updateProfile(name: String? = nil, location: String? = nil, gender: String? = nil, age: Int? = nil, healthGoal: String? = nil, seekingProfessionalHelp: Bool? = nil) async throws {
        guard let session = try? await supabase.auth.session else { throw NSError(domain: "AuthVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "No session found"]) }
        let userId = session.user.id.uuidString
        
        struct ProfileUpdate: Encodable {
            var updated_at: String
            var name: String?
            var location: String?
            var gender: String?
            var age: Int?
            var health_goal: String?
            var seeking_professional_help: Bool?
        }
        
        let req = ProfileUpdate(
            updated_at: ISO8601DateFormatter().string(from: Date()),
            name: name,
            location: location,
            gender: gender,
            age: age,
            health_goal: healthGoal,
            seeking_professional_help: seekingProfessionalHelp
        )
        
        try await supabase.from("users").update(req).eq("id", value: userId).execute()
        
        await fetchCurrentUser()
    }
    
    func completeOnboarding(healthGoal: String, gender: String, age: Int, seekingProfessionalHelp: Bool) async throws {
        guard let session = try? await supabase.auth.session else { throw NSError(domain: "AuthVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "No session found"]) }
        let userId = session.user.id.uuidString
        
        struct OnboardingUpdate: Encodable {
            var health_goal: String
            var gender: String
            var age: Int
            var seeking_professional_help: Bool
            var onboarding_completed: Bool
            var updated_at: String
        }
        
        let req = OnboardingUpdate(
            health_goal: healthGoal,
            gender: gender,
            age: age,
            seeking_professional_help: seekingProfessionalHelp,
            onboarding_completed: true,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase.from("users").update(req).eq("id", value: userId).execute()
        
        // Cache the completion state locally for offline resilience
        UserDefaults.standard.set(true, forKey: Constants.UserDefaults.hasCompletedOnboarding)
        
        await fetchCurrentUser()
    }
}
