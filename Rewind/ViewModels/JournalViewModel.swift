import Foundation
import Supabase
import Combine

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var journals: [DBJournal] = []
    @Published var currentJournal: DBJournal?
    @Published var isLoading = false
    @Published var error: String?
    @Published var pagination: PaginationInfo?
    
    private let supabase = SupabaseConfig.shared.client
    var currentPage = 1
    let perPage = 20
    
    struct PaginationInfo {
        let page: Int
        let perPage: Int
        let total: Int
        let totalPages: Int
        let hasNext: Bool
        let hasPrev: Bool
    }
    
    func fetchJournals(page: Int = 1, refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            journals = []
        }
        
        isLoading = true
        
        do {
            guard let session = try? await supabase.auth.session else { return }
            
            let from = (page - 1) * perPage
            let to = page * perPage - 1
            
            let responseResp: [DBJournal] = try await supabase.from("journals")
                .select("*")
                .eq("user_id", value: session.user.id.uuidString)
                .order("created_at", ascending: false)
                .range(from: from, to: to)
                .execute()
                .value
            
            let newJournals = responseResp
            
            if page == 1 {
                journals = newJournals
            } else {
                journals.append(contentsOf: newJournals)
            }
            
            let total = newJournals.count
            pagination = PaginationInfo(
                page: page,
                perPage: perPage,
                total: total,
                totalPages: (total + perPage - 1) / perPage,
                hasNext: page * perPage < total,
                hasPrev: page > 1
            )
            
            currentPage = page
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createJournal(title: String, content: String, emotion: String? = nil, tags: [String]? = nil, mediaUrls: [String]? = nil, isFavorite: Bool = false) async throws -> DBJournal {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "JournalVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let now = ISO8601DateFormatter().string(from: Date())
        
        let newJournal = DBJournal(
            id: UUID(),
            userId: session.user.id,
            title: title,
            content: content,
            emotion: emotion,
            tags: tags ?? [],
            mediaUrls: mediaUrls ?? [],
            isFavorite: isFavorite,
            createdAt: now,
            updatedAt: now
        )
        
        try await supabase.from("journals").insert(newJournal).execute()
        
        journals.insert(newJournal, at: 0)
        
        return newJournal
    }
    
    func updateJournal(id: UUID, title: String, content: String, emotion: String? = nil, tags: [String]? = nil, isFavorite: Bool? = nil) async throws {
        struct UpdateReq: Encodable {
            var title: String
            var content: String
            var emotion: String?
            var tags: [String]?
            var is_favorite: Bool?
            var updated_at: String
        }
        let req = UpdateReq(title: title, content: content, emotion: emotion, tags: tags, is_favorite: isFavorite, updated_at: ISO8601DateFormatter().string(from: Date()))
        try await supabase.from("journals")
            .update(req)
            .eq("id", value: id.uuidString)
            .execute()
        
        if let index = journals.firstIndex(where: { $0.id == id }) {
            journals[index] = DBJournal(
                id: id,
                userId: journals[index].userId,
                title: title,
                content: content,
                emotion: emotion ?? journals[index].emotion,
                tags: tags ?? journals[index].tags,
                mediaUrls: journals[index].mediaUrls,
                isFavorite: isFavorite ?? journals[index].isFavorite,
                createdAt: journals[index].createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
        }
    }
    
    func deleteJournal(id: UUID) async throws {
        guard let session = try? await supabase.auth.session else { return }
        _ = session
        
        // Delete associated media files from storage before deleting the journal
        if let journal = journals.first(where: { $0.id == id }) {
            let mediaUrls = journal.mediaUrls
            if !mediaUrls.isEmpty {
                let bucket = SupabaseConfig.shared.client.storage.from("journal-media")
                var pathsToDelete: [String] = []
                
                for urlStr in mediaUrls {
                    if let url = URL(string: urlStr) {
                        let pathComponents = url.pathComponents
                        if let bucketIndex = pathComponents.lastIndex(of: "journal-media"),
                           bucketIndex + 1 < pathComponents.count {
                            let relativePath = pathComponents[(bucketIndex + 1)...].joined(separator: "/")
                            pathsToDelete.append(relativePath)
                        }
                    }
                }
                
                if !pathsToDelete.isEmpty {
                    do {
                        _ = try await bucket.remove(paths: pathsToDelete)
                    } catch {
                        print("Error deleting journal media files: \(error)")
                    }
                }
            }
        }
        
        try await supabase.from("journals")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        journals.removeAll { $0.id == id }
    }
    
    func uploadMedia(journalId: UUID, fileData: Data, fileName: String) async throws -> String {
        let session = try? await supabase.auth.session
        let userIdStr = session?.user.id.uuidString.lowercased() ?? UUID().uuidString.lowercased()
        let path = "\(userIdStr)/\(journalId.uuidString.lowercased())_\(fileName)"
        
        try await supabase.storage.from("journal-media").upload(
            path: path,
            file: fileData,
            options: SupabaseConfig.Client.UploadOptions(contentType: "audio/m4a", upsert: false)
        )
        
        return try supabase.storage.from("journal-media").getPublicURL(path: path).absoluteString
    }
}
