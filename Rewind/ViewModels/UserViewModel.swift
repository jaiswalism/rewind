import Foundation
import Supabase
import Combine

private struct PurchaseParams: Encodable, Sendable {
    let p_user_id: UUID
    let p_amount: Int
    let p_style: String

    enum CodingKeys: String, CodingKey {
        case p_user_id
        case p_amount
        case p_style
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(p_user_id, forKey: .p_user_id)
        try container.encode(p_amount, forKey: .p_amount)
        try container.encode(p_style, forKey: .p_style)
    }
}

private struct FallbackUpdate: Encodable, Sendable {
    var paws_balance: Int
    var owned_styles: [String]
    var updated_at: String
}

private struct SpendParams: Encodable, Sendable {
    let user_id: UUID
    let amount: Int

    enum CodingKeys: String, CodingKey {
        case user_id
        case amount
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(amount, forKey: .amount)
    }
}

private struct ProfileUpdate: Encodable, Sendable {
    var updated_at: String
    var name: String?
    var location: String?
    var date_of_birth: String?
    var gender: String?
    var age: Int?
    var health_goal: String?
    var seeking_professional_help: Bool?
}

private struct ImageUpdate: Encodable, Sendable {
    var profile_image_url: String
    var updated_at: String
}

private struct DeleteAccountResponse: Decodable {
    let success: Bool
    let error: String?
    let deletionDueAt: String?
}

private struct ClearDeletionRequestUpdate: Encodable, Sendable {
    var account_deletion_requested_at: String?
    var account_deletion_due_at: String?
    var updated_at: String
}

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

    func deleteCurrentAccount() async throws {
        let session = try await supabase.auth.session

        var request = URLRequest(url: SupabaseSecrets.supabaseURL.appendingPathComponent("functions/v1/delete-account"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseSecrets.supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "UserVM", code: 900, userInfo: [NSLocalizedDescriptionKey: "Invalid server response while deleting account."])
        }

        if !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Delete account failed."
            throw NSError(domain: "UserVM", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        if let parsed = try? JSONDecoder().decode(DeleteAccountResponse.self, from: data), parsed.success == false {
            throw NSError(domain: "UserVM", code: 901, userInfo: [NSLocalizedDescriptionKey: parsed.error ?? "Delete account failed."])
        }

        try await supabase.auth.signOut()
        user = nil
    }

    func restoreScheduledAccountDeletionIfNeeded() async {
        guard let user,
              user.accountDeletionRequestedAt != nil,
              let dueAt = user.accountDeletionDueAt else {
            return
        }

        let formatter = ISO8601DateFormatter()
        guard let dueDate = formatter.date(from: dueAt), Date() < dueDate else {
            return
        }

        let update = ClearDeletionRequestUpdate(
            account_deletion_requested_at: nil,
            account_deletion_due_at: nil,
            updated_at: formatter.string(from: Date())
        )

        guard let session = try? await supabase.auth.session else { return }

        do {
            try await supabase.from("users")
                .update(update)
                .eq("id", value: session.user.id.uuidString)
                .execute()
            await fetchProfile()
        } catch {
            print("Failed to clear scheduled account deletion: \(error)")
        }
    }

    func purchasePetStyle(styleFileName: String, amount: Int) async throws {
        guard amount >= 0 else { return }
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "UserVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let params = PurchaseParams(p_user_id: session.user.id, p_amount: amount, p_style: styleFileName)
        
        do {
            // Assumes an RPC `purchase_pet_style` exists that atomically checks paws and appends to `owned_styles`
            try await supabase.rpc("purchase_pet_style", params: params).execute()
            await fetchProfile()
        } catch {
            // Fallback strategy if RPC isn't available yet: manually read/modify/write (can have race condition but works if no RPC)
            if user == nil { await fetchProfile() }
            let currentBalance = user?.pawsBalance ?? 0
            guard currentBalance >= amount else {
                throw NSError(domain: "UserVM", code: 402, userInfo: [NSLocalizedDescriptionKey: "Not enough paws"])
            }
            
            var currentStyles = user?.ownedStyles ?? []
            if !currentStyles.contains(styleFileName) {
                currentStyles.append(styleFileName)
            }
            
            let req = FallbackUpdate(
                paws_balance: currentBalance - amount,
                owned_styles: currentStyles,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase.from("users").update(req).eq("id", value: session.user.id.uuidString).execute()
            await fetchProfile()
        }
    }

    func spendPawsBalance(amount: Int) async throws {
        guard amount > 0 else { return }
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "UserVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let params = SpendParams(user_id: session.user.id, amount: amount)

        do {
            // Assume we have an RPC function `spend_paws` on the backend that atomically checks and decrements
            // If the RPC fails, it throws, ensuring balance doesn't go negative or overwrite concurrent rewards.
            try await supabase.rpc("spend_paws", params: params).execute()
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
