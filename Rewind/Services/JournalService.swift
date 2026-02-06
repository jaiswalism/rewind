import Foundation

class JournalService {
    static let shared = JournalService()
    private init() {}
    
    // fetching the user's journal entries
    func getJournals(page: Int = 1, perPage: Int = 10, completion: @escaping (Result<[Journal], Error>) -> Void) {
        let endpoint = "/journals?page=\(page)&per_page=\(perPage)"
        
        APIService.shared.makeRequest(endpoint: endpoint, method: "GET") { (result: Result<JournalListResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Create Journal
    func createJournal(title: String, content: String, type: EntryType, moodTags: [String]? = nil, voiceUrl: String? = nil, mediaUrls: [String]? = nil, transcription: String? = nil, completion: @escaping (Result<Journal, Error>) -> Void) {
        
        let request = CreateJournalRequest(
            title: title,
            content: content,
            entryType: type.rawValue,
            moodTags: moodTags,
            voiceRecordingUrl: voiceUrl,
            mediaUrls: mediaUrls,
            transcriptionText: transcription
        )
        
        APIService.shared.makeRequest(endpoint: "/journals", method: "POST", body: request) { (result: Result<JournalResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // finding a specific entry
    func getJournal(id: String, completion: @escaping (Result<Journal, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/journals/\(id)", method: "GET") { (result: Result<JournalResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Delete Journal
    func deleteJournal(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        APIService.shared.makeRequest(endpoint: "/journals/\(id)", method: "DELETE") { (result: Result<APIResponse<String>, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // attaching media

    func uploadMedia(journalId: String, fileUrl: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let endpoint = "/journals/\(journalId)/media"
        let fileName = fileUrl.lastPathComponent
        
        APIService.shared.uploadRequest(endpoint: endpoint, method: "POST", fileUrl: fileUrl, fileName: fileName) { (result: Result<APIResponse<UploadMediaResponse>, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
