import Foundation
import Supabase

final class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    // MARK: - Compatibility Wrappers
    // These wrappers prevent us from having to change the explicitly defined response types
    // all over the ViewModels that relied on the mock implementation.
    struct Client {
        typealias UploadOptions = FileOptions
        
        struct QueryBuilder {
            typealias VoidResponse = Void
            
            // PostgREST internally returns PostgrestResponse<T> on .execute()
            typealias Response<T: Decodable & Sendable> = PostgrestResponse<T>
        }
    }
    
    // MARK: - Buckets
    static let avatarsBucket = "avatars"
    static let journalMediaBucket = "journal-media"
    static let postMediaBucket = "post-media"
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: SupabaseSecrets.supabaseURL,
            supabaseKey: SupabaseSecrets.supabaseKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: Constants.Auth.oauthRedirectURL,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
