import Foundation
import Supabase

private struct PetCompanionStateUpdatePayload: Encodable {
    let energy: Int
    let mood: Int
    let trust: Int
    let lastUpdated: String

    enum CodingKeys: String, CodingKey {
        case energy
        case mood
        case trust
        case lastUpdated = "last_updated"
    }
}

// MARK: - Pet Repository

/// Repository for pet companion data operations with Supabase
final class PetRepository {
    
    static let shared = PetRepository()
    
    private let supabase = SupabaseConfig.shared.client
    
    private init() {}
    
    // MARK: - Pet Companion State
    
    /// Get or create user's pet companion state
    /// - Parameter userId: User ID
    /// - Returns: Pet companion state
    func getOrCreatePetCompanionState(userId: String) async throws -> PetCompanionState {
        do {
            let states: [PetCompanionState] = try await supabase
                .from("pet_companion_states")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if let state = states.first {
                return state
            }
            
            // Create default state
            return try await createPetCompanionState(
                userId: userId,
                energy: 50,
                mood: 50,
                trust: 50
            )
        } catch {
            throw PetRepositoryError.getStateFailed(error)
        }
    }
    
    /// Create a new pet companion state
    /// - Parameters:
    ///   - userId: User ID
    ///   - energy: Initial energy (0-100)
    ///   - mood: Initial mood (0-100)
    ///   - trust: Initial trust (0-100)
    /// - Returns: Created state
    private func createPetCompanionState(
        userId: String,
        energy: Int,
        mood: Int,
        trust: Int
    ) async throws -> PetCompanionState {
        do {
            let state = PetCompanionState(
                userId: userId,
                energy: energy,
                mood: mood,
                trust: trust
            )
            
            let inserted: [PetCompanionState] = try await supabase
                .from("pet_companion_states")
                .insert(state, returning: .representation)
                .execute()
                .value
            
            guard let created = inserted.first else {
                throw PetRepositoryError.createStateFailed
            }
            
            return created
        } catch let error as PetRepositoryError {
            throw error
        } catch {
            throw PetRepositoryError.createStateFailedUnderlying(error)
        }
    }
    
    /// Update pet companion state
    /// - Parameter state: State to update
    /// - Returns: Updated state
    func updatePetCompanionState(_ state: PetCompanionState) async throws -> PetCompanionState {
        do {
            let updates = PetCompanionStateUpdatePayload(
                energy: state.energy,
                mood: state.mood,
                trust: state.trust,
                lastUpdated: ISO8601DateFormatter().string(from: Date())
            )
            
            let updated: [PetCompanionState] = try await supabase
                .from("pet_companion_states")
                .update(updates, returning: .representation)
                .eq("user_id", value: state.userId)
                .execute()
                .value
            
            guard let updatedState = updated.first else {
                throw PetRepositoryError.updateStateFailed
            }
            
            return updatedState
        } catch let error as PetRepositoryError {
            throw error
        } catch {
            throw PetRepositoryError.updateStateFailedUnderlying(error)
        }
    }
    
    /// Apply state delta and return updated state
    /// - Parameters:
    ///   - userId: User ID
    ///   - delta: State delta to apply
    ///   - smoothingAlpha: Smoothing factor
    /// - Returns: Updated state after applying delta
    func applyStateDelta(userId: String, delta: PetStateDelta, smoothingAlpha: Double = 0.3) async throws -> PetCompanionState {
        // Get current state
        let currentState = try await getOrCreatePetCompanionState(userId: userId)
        
        // Apply smoothing
        let smoothedState = PetStateManager.applySmoothing(current: currentState, delta: delta, alpha: smoothingAlpha)
        
        // Clip to valid range
        let clippedState = PetStateManager.clipState(smoothedState)
        
        // Update in database
        return try await updatePetCompanionState(clippedState)
    }
    
    // MARK: - Pet Companion Memory
    
    /// Get user's pet companion memory
    /// - Parameter userId: User ID
    /// - Returns: Pet companion memory or nil
    func getPetCompanionMemory(userId: String) async throws -> PetCompanionMemory? {
        do {
            let memories: [PetCompanionMemory] = try await supabase
                .from("pet_companion_memories")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            return memories.first
        } catch {
            throw PetRepositoryError.getMemoryFailed(error)
        }
    }
    
    /// Create or update pet companion memory
    /// - Parameter memory: Memory to upsert
    /// - Returns: Updated memory
    func upsertPetCompanionMemory(_ memory: PetCompanionMemory) async throws -> PetCompanionMemory {
        do {
            let inserted: [PetCompanionMemory] = try await supabase
                .from("pet_companion_memories")
                .upsert(memory, onConflict: "user_id", returning: .representation)
                .execute()
                .value
            
            guard let updated = inserted.first else {
                throw PetRepositoryError.upsertMemoryFailed
            }
            
            return updated
        } catch let error as PetRepositoryError {
            throw error
        } catch {
            throw PetRepositoryError.upsertMemoryFailedUnderlying(error)
        }
    }
    
    /// Update memory with partial fields
    /// - Parameters:
    ///   - userId: User ID
    ///   - weekAvgMood: Weekly average mood (optional)
    ///   - dominantEmotion: Dominant emotion (optional)
    ///   - talkPreference: Talk preference (optional)
    /// - Returns: Updated memory
    func updatePetCompanionMemory(
        userId: String,
        weekAvgMood: Double? = nil,
        dominantEmotion: String? = nil,
        talkPreference: String? = nil
    ) async throws -> PetCompanionMemory {
        do {
            // Get existing or create new
            var memory = try await getPetCompanionMemory(userId: userId) ?? PetCompanionMemory(userId: userId)
            
            // Update fields
            memory.weekAvgMood = weekAvgMood ?? memory.weekAvgMood
            memory.dominantEmotion = dominantEmotion ?? memory.dominantEmotion
            memory.talkPreference = talkPreference ?? memory.talkPreference
            
            // Upsert
            return try await upsertPetCompanionMemory(memory)
        } catch let error as PetRepositoryError {
            throw error
        } catch {
            throw PetRepositoryError.updateMemoryFailed(error)
        }
    }
    
    // MARK: - Pet Journals
    
    /// Create a new journal entry
    /// - Parameter entry: Journal entry to create
    /// - Returns: Created journal entry
    func createPetJournalEntry(_ entry: PetJournalEntry) async throws -> PetJournalEntry {
        do {
            let inserted: [PetJournalEntry] = try await supabase
                .from("pet_journals")
                .insert(entry, returning: .representation)
                .execute()
                .value
            
            guard let created = inserted.first else {
                throw PetRepositoryError.createJournalFailed
            }
            
            return created
        } catch let error as PetRepositoryError {
            throw error
        } catch {
            throw PetRepositoryError.createJournalFailedUnderlying(error)
        }
    }
    
    /// Get user's journal entries
    /// - Parameters:
    ///   - userId: User ID
    ///   - limit: Max entries to return
    ///   - offset: Offset for pagination
    /// - Returns: Array of journal entries
    func getPetJournalEntries(userId: String, limit: Int = 50, offset: Int = 0) async throws -> [PetJournalEntry] {
        do {
            let end = max(offset, offset + max(0, limit) - 1)
            let entries: [PetJournalEntry] = try await supabase
                .from("pet_journals")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .range(from: offset, to: end)
                .execute()
                .value
            
            return entries
        } catch {
            throw PetRepositoryError.getJournalsFailed(error)
        }
    }
    
    /// Get journal entries for a date range
    /// - Parameters:
    ///   - userId: User ID
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Array of journal entries
    func getPetJournalEntries(userId: String, startDate: Date, endDate: Date) async throws -> [PetJournalEntry] {
        do {
            let formatter = ISO8601DateFormatter()
            let entries: [PetJournalEntry] = try await supabase
                .from("pet_journals")
                .select()
                .eq("user_id", value: userId)
                .gte("created_at", value: formatter.string(from: startDate))
                .lte("created_at", value: formatter.string(from: endDate))
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return entries
        } catch {
            throw PetRepositoryError.getJournalsFailed(error)
        }
    }
    
    // MARK: - Days Inactive Calculation
    
    /// Calculate days since last state update
    /// - Parameter userId: User ID
    /// - Returns: Days inactive
    func calculateDaysInactive(userId: String) async throws -> Int {
        do {
            let state = try await getOrCreatePetCompanionState(userId: userId)
            
            guard let lastUpdated = state.lastUpdated else {
                return 0
            }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: lastUpdated, to: Date())
            return components.day ?? 0
        } catch {
            throw PetRepositoryError.calculateDaysInactiveFailed(error)
        }
    }
}

// MARK: - Repository Errors

enum PetRepositoryError: LocalizedError {
    case getStateFailed(Error)
    case createStateFailed
    case createStateFailedUnderlying(Error)
    case updateStateFailed
    case updateStateFailedUnderlying(Error)
    case getMemoryFailed(Error)
    case upsertMemoryFailed
    case upsertMemoryFailedUnderlying(Error)
    case updateMemoryFailed(Error)
    case createJournalFailed
    case createJournalFailedUnderlying(Error)
    case getJournalsFailed(Error)
    case calculateDaysInactiveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .getStateFailed(let error):
            return "Failed to get pet companion state: \(error.localizedDescription)"
        case .createStateFailed:
            return "Failed to create pet companion state"
        case .createStateFailedUnderlying(let error):
            return "Failed to create pet companion state: \(error.localizedDescription)"
        case .updateStateFailed:
            return "Failed to update pet companion state"
        case .updateStateFailedUnderlying(let error):
            return "Failed to update pet companion state: \(error.localizedDescription)"
        case .getMemoryFailed(let error):
            return "Failed to get pet companion memory: \(error.localizedDescription)"
        case .upsertMemoryFailed:
            return "Failed to upsert pet companion memory"
        case .upsertMemoryFailedUnderlying(let error):
            return "Failed to upsert pet companion memory: \(error.localizedDescription)"
        case .updateMemoryFailed(let error):
            return "Failed to update pet companion memory: \(error.localizedDescription)"
        case .createJournalFailed:
            return "Failed to create pet journal entry"
        case .createJournalFailedUnderlying(let error):
            return "Failed to create pet journal entry: \(error.localizedDescription)"
        case .getJournalsFailed(let error):
            return "Failed to get pet journal entries: \(error.localizedDescription)"
        case .calculateDaysInactiveFailed(let error):
            return "Failed to calculate days inactive: \(error.localizedDescription)"
        }
    }
}
