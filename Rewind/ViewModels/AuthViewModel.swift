import Foundation
import Supabase
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var currentUser: DBUser?
    @Published var isLoggedIn = false
    @Published var error: String?
    
    private let supabase = SupabaseConfig.shared.client
    
    init() {
        Task {
            await checkCurrentSession()
        }
    }
    
    func checkCurrentSession() async {
        do {
            if let _ = try? await supabase.auth.session {
                isLoggedIn = true
                await fetchCurrentUser()
            }
        } catch {
            isLoggedIn = false
        }
    }
    
    func register(name: String, email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        do {
            let session = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            let userId = session.user.id.uuidString
            let now = ISO8601DateFormatter().string(from: Date())
            
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
                pawsBalance: 0,
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
        
        isLoading = false
    }
    
    func login(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            isLoggedIn = true
            await fetchCurrentUser()
        } catch {
            self.error = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func logout() async {
        isLoading = true
        
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isLoggedIn = false
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func forgotPassword(email: String) async throws {
        isLoading = true
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
        
        isLoading = false
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
        
        await fetchCurrentUser()
    }
}
