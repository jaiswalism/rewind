import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://YOUR_PROJECT.supabase.co")!,
            supabaseKey: "YOUR_ANON_KEY"
        )
    }

    var currentUserID: String? {
        get async {
            try? await client.auth.session.user.id.uuidString
        }
    }

    var isAuthenticated: Bool {
        get async {
            do {
                _ = try await client.auth.session
                return true
            } catch {
                return false
            }
        }
    }
}
