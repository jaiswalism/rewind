import Foundation
import Supabase
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [DBNotification] = []
    @Published var unreadCount = 0
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
    
    func fetchNotifications(page: Int = 1, refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            notifications = []
        }
        
        isLoading = true
        
        do {
            guard let session = try? await supabase.auth.session else { return }
            
            let from = (page - 1) * perPage
            let to = page * perPage - 1
            
            let responseResp: [DBNotification] = try await supabase.from("notifications")
                .select("*")
                .eq("user_id", value: session.user.id.uuidString)
                .order("created_at", ascending: false)
                .range(from: from, to: to)
                .execute()
                .value
            
            let newNotifications = responseResp
            
            if page == 1 {
                notifications = newNotifications
            } else {
                notifications.append(contentsOf: newNotifications)
            }
            
            let total = newNotifications.count
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
    
    func fetchUnreadCount() async {
        do {
            guard let session = try? await supabase.auth.session else { return }
            
            let response = try await supabase.from("notifications")
                .select("*", head: true)
                .eq("user_id", value: session.user.id.uuidString)
                .eq("is_read", value: false)
                .execute()
            
            unreadCount = response.count ?? 0
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func markAsRead(id: UUID) async throws {
        struct ReadUpdate: Encodable { var is_read: Bool }
        try await supabase.from("notifications")
            .update(ReadUpdate(is_read: true))
            .eq("id", value: id.uuidString)
            .execute()
        
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index] = DBNotification(
                id: notifications[index].id,
                userId: notifications[index].userId,
                title: notifications[index].title,
                body: notifications[index].body,
                type: notifications[index].type,
                isRead: true,
                referenceId: notifications[index].referenceId,
                createdAt: notifications[index].createdAt
            )
        }
        
        await fetchUnreadCount()
    }
    
    func markAllAsRead() async throws {
        guard let session = try? await supabase.auth.session else { return }
        
        struct ReadUpdate: Encodable { var is_read: Bool }
        try await supabase.from("notifications")
            .update(ReadUpdate(is_read: true))
            .eq("user_id", value: session.user.id.uuidString)
            .eq("is_read", value: false)
            .execute()
        
        for i in 0..<notifications.count {
            notifications[i] = DBNotification(
                id: notifications[i].id,
                userId: notifications[i].userId,
                title: notifications[i].title,
                body: notifications[i].body,
                type: notifications[i].type,
                isRead: true,
                referenceId: notifications[i].referenceId,
                createdAt: notifications[i].createdAt
            )
        }
        
        unreadCount = 0
    }
    
    func deleteNotification(id: UUID) async throws {
        try await supabase.from("notifications")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        notifications.removeAll { $0.id == id }
        await fetchUnreadCount()
    }
}
