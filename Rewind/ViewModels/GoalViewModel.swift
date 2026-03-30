import Foundation
import Combine

@MainActor
final class GoalViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    // Add real database methods here once Supabase integration is mapped
    
    func createGoal(title: String, description: String, category: String?, targetDate: String?) async throws -> Bool {
        // Placeholder for compilation
        return true
    }
}
