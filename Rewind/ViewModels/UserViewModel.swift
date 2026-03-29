import Foundation
import Supabase
import Combine

@MainActor
final class UserViewModel: ObservableObject {
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
        
        try await supabase.from("users").update(req).eq("id", value: session.user.id.uuidString).execute()
        
        await fetchProfile()
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
        
        try await supabase.from("users").update(req).eq("id", value: session.user.id.uuidString).execute()
        
        await fetchProfile()
    }
    
    func uploadAvatar(imageData: Data) async throws -> String {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "UserVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let fileName = "\(session.user.id.uuidString)/avatar.jpg"
        
        try await supabase.storage.from("avatars").upload(
            path: fileName,
            file: imageData,
            options: SupabaseConfig.Client.UploadOptions(contentType: "image/jpeg", upsert: true)
        )
        
        let publicUrl = try supabase.storage.from("avatars").getPublicURL(path: fileName).absoluteString
        
        try await updateProfileImage(imageUrl: publicUrl)
        
        return publicUrl
    }
}
