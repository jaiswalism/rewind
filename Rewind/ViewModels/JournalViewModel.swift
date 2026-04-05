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
    
    static let journalDidChangeNotification = Notification.Name("journalDidChangeNotification")
    
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
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let session = try? await supabase.auth.session else {
                error = "Not authenticated"
                return
            }
            
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
    }
    
    func createJournal(title: String, content: String, emotion: String? = nil, tags: [String]? = nil, mediaUrls: [String]? = nil, isFavorite: Bool = false, entryType: String? = nil, voiceRecordingUrl: String? = nil, transcriptionText: String? = nil, feelings: [String]? = nil, activities: [String]? = nil, createdAt: Date? = nil, journalId: UUID? = nil) async throws -> DBJournal {
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "JournalVM", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let createdAtDate = createdAt ?? Date()
        let createdAtIso = ISO8601DateFormatter().string(from: createdAtDate)
        let now = ISO8601DateFormatter().string(from: Date())
        
        let newJournal = DBJournal(
            id: journalId ?? UUID(),
            userId: session.user.id,
            title: title,
            content: content,
            emotion: emotion,
            tags: tags ?? [],
            mediaUrls: mediaUrls ?? [],
            isFavorite: isFavorite,
            entryType: entryType,
            voiceRecordingUrl: voiceRecordingUrl,
            transcriptionText: transcriptionText,
            feelings: feelings,
            activities: activities,
            createdAt: createdAtIso,
            updatedAt: now
        )

        struct ModernInsertReq: Encodable {
            var id: UUID
            var user_id: UUID
            var title: String
            var content: String
            var emotion: String?
            var tags: [String]
            var media_urls: [String]
            var is_favorite: Bool
            var entry_type: String?
            var voice_recording_url: String?
            var transcription_text: String?
            var feelings: [String]?
            var activities: [String]?
            var created_at: String
            var updated_at: String
        }

        struct LegacyInsertReq: Encodable {
            var id: UUID
            var user_id: UUID
            var title: String
            var content: String
            var media_urls: [String]
            var created_at: String
            var updated_at: String
        }

        do {
            let modernReq = ModernInsertReq(
                id: newJournal.id,
                user_id: newJournal.userId,
                title: newJournal.title,
                content: newJournal.content,
                emotion: newJournal.emotion,
                tags: newJournal.tags,
                media_urls: newJournal.mediaUrls,
                is_favorite: newJournal.isFavorite,
                entry_type: newJournal.entryType,
                voice_recording_url: newJournal.voiceRecordingUrl,
                transcription_text: newJournal.transcriptionText,
                feelings: newJournal.feelings,
                activities: newJournal.activities,
                created_at: newJournal.createdAt,
                updated_at: newJournal.updatedAt
            )
            try await supabase.from("journals").insert(modernReq).execute()
        } catch {
            // Backward compatibility for older DB schemas that don't include newer journal columns.
            let legacyReq = LegacyInsertReq(
                id: newJournal.id,
                user_id: newJournal.userId,
                title: newJournal.title,
                content: newJournal.content,
                media_urls: newJournal.mediaUrls,
                created_at: newJournal.createdAt,
                updated_at: newJournal.updatedAt
            )
            do {
                try await supabase.from("journals").insert(legacyReq).execute()
            } catch {
                throw error
            }
        }
        
        journals.insert(newJournal, at: 0)
        NotificationCenter.default.post(name: Self.journalDidChangeNotification, object: nil)
        
        return newJournal
    }
    
    func updateJournal(id: UUID, title: String, content: String, emotion: String? = nil, tags: [String]? = nil, mediaUrls: [String]? = nil, isFavorite: Bool? = nil, createdAt: Date? = nil) async throws {
        struct UpdateReq: Encodable {
            var title: String
            var content: String
            var emotion: String?
            var tags: [String]?
            var media_urls: [String]?
            var is_favorite: Bool?
            var created_at: String?
            var updated_at: String
        }
        let req = UpdateReq(
            title: title,
            content: content,
            emotion: emotion,
            tags: tags,
            media_urls: mediaUrls,
            is_favorite: isFavorite,
            created_at: createdAt.map { ISO8601DateFormatter().string(from: $0) },
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
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
                mediaUrls: mediaUrls ?? journals[index].mediaUrls,
                isFavorite: isFavorite ?? journals[index].isFavorite,
                entryType: journals[index].entryType,
                voiceRecordingUrl: journals[index].voiceRecordingUrl,
                transcriptionText: journals[index].transcriptionText,
                feelings: journals[index].feelings,
                activities: journals[index].activities,
                createdAt: req.created_at ?? journals[index].createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
        }

        NotificationCenter.default.post(name: Self.journalDidChangeNotification, object: nil)
    }

    func updateVoiceJournalMedia(id: UUID, voiceRecordingUrl: String, mediaUrls: [String]) async throws {
        struct VoiceUpdateReq: Encodable {
            var voice_recording_url: String
            var media_urls: [String]
            var updated_at: String
        }

        let req = VoiceUpdateReq(
            voice_recording_url: voiceRecordingUrl,
            media_urls: mediaUrls,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase.from("journals")
            .update(req)
            .eq("id", value: id.uuidString)
            .execute()

        if let index = journals.firstIndex(where: { $0.id == id }) {
            journals[index].voiceRecordingUrl = voiceRecordingUrl
            journals[index].mediaUrls = mediaUrls
            journals[index].updatedAt = req.updated_at
        }

        NotificationCenter.default.post(name: Self.journalDidChangeNotification, object: nil)
    }

    func fetchAllJournals(refresh: Bool = true) async {
        if refresh {
            currentPage = 1
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            guard let session = try? await supabase.auth.session else {
                error = "Not authenticated"
                return
            }

            var page = 1
            var combined: [DBJournal] = []

            while true {
                let from = (page - 1) * perPage
                let to = page * perPage - 1

                let pageResult: [DBJournal] = try await supabase.from("journals")
                    .select("*")
                    .eq("user_id", value: session.user.id.uuidString)
                    .order("created_at", ascending: false)
                    .range(from: from, to: to)
                    .execute()
                    .value

                combined.append(contentsOf: pageResult)

                if pageResult.count < perPage {
                    break
                }

                page += 1
            }

            journals = combined.sorted {
                ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast)
            }

            let total = journals.count
            pagination = PaginationInfo(
                page: 1,
                perPage: perPage,
                total: total,
                totalPages: (total + perPage - 1) / perPage,
                hasNext: false,
                hasPrev: false
            )

            currentPage = 1
        } catch {
            self.error = error.localizedDescription
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
        NotificationCenter.default.post(name: Self.journalDidChangeNotification, object: nil)
    }
    
    func uploadMedia(journalId: UUID, fileData: Data, fileName: String, contentType: String = "audio/m4a") async throws -> String {
        let session = try? await supabase.auth.session
        let userIdStr = session?.user.id.uuidString.lowercased() ?? UUID().uuidString.lowercased()
        let path = "\(userIdStr)/\(journalId.uuidString.lowercased())_\(fileName)"
        
        try await supabase.storage.from("journal-media").upload(
            path,
            data: fileData,
            options: SupabaseConfig.Client.UploadOptions(contentType: contentType, upsert: false)
        )
        
        return try supabase.storage.from("journal-media").getPublicURL(path: path).absoluteString
    }
}
