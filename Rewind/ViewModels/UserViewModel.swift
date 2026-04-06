import Foundation
import Supabase
import Combine

@MainActor
final class UserViewModel: ObservableObject {
    static let shared = UserViewModel()

    @Published var user: DBUser?
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase = SupabaseConfig.shared.client
    
    func fetchProfile() async {
        isLoading = true
        
        do {
            guard let session = try? await supabase.auth.session else { return }
            
            let response: [DBUser] = try await supabase.from("users")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .execute()
                .value
            user = response.first
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateProfile(name: String? = nil, location: String? = nil, dateOfBirth: String? = nil, gender: String? = nil, age: Int? = nil, healthGoal: String? = nil, seekingProfessionalHelp: Bool? = nil) async throws {
        guard let session = try? await supabase.auth.session else { return }
        
        struct ProfileUpdate: Encodable {
            var updated_at: String
            var name: String?
            var location: String?
            var date_of_birth: String?
            var gender: String?
            var age: Int?
            var health_goal: String?
            var seeking_professional_help: Bool?
        }
        
        let req = ProfileUpdate(
            updated_at: ISO8601DateFormatter().string(from: Date()),
            name: name,
            location: location,
            date_of_birth: dateOfBirth,
            gender: gender,
            age: age,
            health_goal: healthGoal,
            seeking_professional_help: seekingProfessionalHelp
        )
        
        do {
            try await supabase.from("users").update(req).eq("id", value: session.user.id.uuidString).execute()
            await fetchProfile()
        } catch {
            throw NSError(domain: "UserVM", code: 1, userInfo: [NSLocalizedDescriptionKey: "Profile UPDATE User Error: \(error.localizedDescription)"])
        }
    }
    
    func updateProfileImage(imageUrl: String) async throws {
        guard let session = try? await supabase.auth.session else { return }
        
        struct ImageUpdate: Encodable {
            var profile_image_url: String
            var updated_at: String
        }
        
        let req = ImageUpdate(
            profile_image_url: imageUrl,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            try await supabase.from("users").update(req).eq("id", value: session.user.id.uuidString).execute()
            await fetchProfile()
        } catch {
            throw NSError(domain: "UserVM", code: 2, userInfo: [NSLocalizedDescriptionKey: "Image UPDATE User Error: \(error.localizedDescription)"])
        }
    }

    func spendPawsBalance(amount: Int) async throws {
        guard amount > 0 else { return }
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "UserVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        if user == nil {
            await fetchProfile()
        }

        let currentBalance = user?.pawsBalance ?? 0
        guard currentBalance >= amount else {
            throw NSError(domain: "UserVM", code: 402, userInfo: [NSLocalizedDescriptionKey: "Not enough paws"])
        }

        struct BalanceUpdate: Encodable {
            var paws_balance: Int
            var updated_at: String
        }

        let req = BalanceUpdate(
            paws_balance: currentBalance - amount,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        do {
            try await supabase.from("users").update(req).eq("id", value: session.user.id.uuidString).execute()
            await fetchProfile()
        } catch {
            throw NSError(domain: "UserVM", code: 4, userInfo: [NSLocalizedDescriptionKey: "Paws update error: \(error.localizedDescription)"])
        }
    }
    
    func uploadAvatar(imageData: Data) async throws -> String {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "UserVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        // Postgres auth.uid()::text is lowercase, but Swift's UUID().uuidString is uppercase.
        // For text-based RLS policies (storage paths), they MUST match case!
        let userIdString = session.user.id.uuidString.lowercased()
        
        let fileName = "\(userIdString)/avatar.jpg"
        
        // Attempt to actively remove the existing file to bypass UPDATE restrictions
        do {
            _ = try await supabase.storage.from("avatars").remove(paths: [fileName])
        } catch {
            // Ignore if file doesn't exist, or if we lack delete permissions
        }
        
        do {
            try await supabase.storage.from("avatars").upload(
                fileName,
                data: imageData,
                options: SupabaseConfig.Client.UploadOptions(contentType: "image/jpeg", upsert: true)
            )
        } catch {
            throw NSError(domain: "UserVM", code: 3, userInfo: [NSLocalizedDescriptionKey: "Storage Upload Error: \(error.localizedDescription)"])
        }
        
        let publicUrl = try supabase.storage.from("avatars").getPublicURL(path: fileName).absoluteString
        
        // Append a random cache-busting query parameter so AsyncImage refreshes
        let cacheBustedUrl = publicUrl + "?t=\(Date().timeIntervalSince1970)"
        
        try await updateProfileImage(imageUrl: cacheBustedUrl)
        
        return cacheBustedUrl
    }
}
