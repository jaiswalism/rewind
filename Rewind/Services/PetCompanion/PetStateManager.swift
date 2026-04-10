import Foundation

// MARK: - Pet State Manager

/// Manages pet companion state: delta computation, smoothing, decay, and clipping
final class PetStateManager {
    
    // MARK: - Public Methods
    
    /// Compute state delta from emotion and intensity
    /// - Parameters:
    ///   - emotion: The detected emotion
    ///   - intensity: The intensity of the emotion (0.0 to 1.0)
    /// - Returns: State delta with energy, mood, and trust changes
    static func computeStateDelta(emotion: PetEmotionType, intensity: Double) -> PetStateDelta {
        guard let baseDeltas = PetConstants.emotionDeltas[emotion] else {
            return PetStateDelta(energy: 0, mood: 0, trust: 0)
        }
        
        // Determine intensity multiplier
        let multiplier: Double
        if intensity < PetConstants.intensityThresholdLow {
            multiplier = PetConstants.intensityMultiplierLow
        } else if intensity >= PetConstants.intensityThresholdHigh {
            multiplier = PetConstants.intensityMultiplierHigh
        } else {
            multiplier = PetConstants.intensityMultiplierMedium
        }
        
        return PetStateDelta(
            energy: Int(round(Double(baseDeltas.energy) * multiplier)),
            mood: Int(round(Double(baseDeltas.mood) * multiplier)),
            trust: Int(round(Double(baseDeltas.trust) * multiplier))
        )
    }
    
    /// Apply exponential moving average smoothing
    /// - Parameters:
    ///   - current: Current state values
    ///   - delta: Delta to apply
    ///   - alpha: Smoothing factor (0.0 = no change, 1.0 = full delta)
    /// - Returns: Smoothed state
    static func applySmoothing(current: PetCompanionState, delta: PetStateDelta, alpha: Double = PetConstants.smoothingAlpha) -> PetCompanionState {
        return PetCompanionState(
            id: current.id,
            userId: current.userId,
            energy: Int(round(Double(current.energy) + Double(delta.energy) * alpha)),
            mood: Int(round(Double(current.mood) + Double(delta.mood) * alpha)),
            trust: Int(round(Double(current.trust) + Double(delta.trust) * alpha)),
            lastUpdated: current.lastUpdated,
            createdAt: current.createdAt
        )
    }
    
    /// Clip state values to valid range [0, 100]
    /// - Parameter state: State to clip
    /// - Returns: Clipped state
    static func clipState(_ state: PetCompanionState) -> PetCompanionState {
        return PetCompanionState(
            id: state.id,
            userId: state.userId,
            energy: max(PetConstants.stateMinValue, min(PetConstants.stateMaxValue, state.energy)),
            mood: max(PetConstants.stateMinValue, min(PetConstants.stateMaxValue, state.mood)),
            trust: max(PetConstants.stateMinValue, min(PetConstants.stateMaxValue, state.trust)),
            lastUpdated: state.lastUpdated,
            createdAt: state.createdAt
        )
    }
    
    /// Clip state snapshot to valid range [0, 100]
    /// - Parameter snapshot: Snapshot to clip
    /// - Returns: Clipped snapshot
    static func clipStateSnapshot(_ snapshot: PetCompanionStateSnapshot) -> PetCompanionStateSnapshot {
        return PetCompanionStateSnapshot(
            energy: max(PetConstants.stateMinValue, min(PetConstants.stateMaxValue, snapshot.energy)),
            mood: max(PetConstants.stateMinValue, min(PetConstants.stateMaxValue, snapshot.mood)),
            trust: max(PetConstants.stateMinValue, min(PetConstants.stateMaxValue, snapshot.trust))
        )
    }
    
    /// Apply decay for inactive users
    /// - Parameters:
    ///   - state: Current state
    ///   - daysInactive: Number of days since last interaction
    /// - Returns: State with decay applied
    static func applyDecay(state: PetCompanionState, daysInactive: Int) -> PetCompanionState {
        if daysInactive <= PetConstants.decayThresholdDays {
            return state
        }
        
        let daysOverThreshold = daysInactive - PetConstants.decayThresholdDays
        
        return PetCompanionState(
            id: state.id,
            userId: state.userId,
            energy: max(PetConstants.stateMinValue, state.energy + PetConstants.decayEnergyPerDay * daysOverThreshold),
            mood: max(PetConstants.stateMinValue, state.mood + PetConstants.decayMoodPerDay * daysOverThreshold),
            trust: max(PetConstants.stateMinValue, state.trust + PetConstants.decayTrustPerDay * daysOverThreshold),
            lastUpdated: state.lastUpdated,
            createdAt: state.createdAt
        )
    }
    
    /// Apply decay to state snapshot for inactive users
    /// - Parameters:
    ///   - snapshot: Current state snapshot
    ///   - daysInactive: Number of days since last interaction
    /// - Returns: Snapshot with decay applied
    static func applyDecayToSnapshot(_ snapshot: PetCompanionStateSnapshot, daysInactive: Int) -> PetCompanionStateSnapshot {
        if daysInactive <= PetConstants.decayThresholdDays {
            return snapshot
        }
        
        let daysOverThreshold = daysInactive - PetConstants.decayThresholdDays
        
        return PetCompanionStateSnapshot(
            energy: max(PetConstants.stateMinValue, snapshot.energy + PetConstants.decayEnergyPerDay * daysOverThreshold),
            mood: max(PetConstants.stateMinValue, snapshot.mood + PetConstants.decayMoodPerDay * daysOverThreshold),
            trust: max(PetConstants.stateMinValue, snapshot.trust + PetConstants.decayTrustPerDay * daysOverThreshold)
        )
    }
    
    /// Calculate actual delta between current and target state
    /// - Parameters:
    ///   - current: Current state
    ///   - target: Target state after smoothing
    /// - Returns: Actual delta
    static func computeActualDelta(current: PetCompanionState, target: PetCompanionState) -> PetStateDelta {
        return PetStateDelta(
            energy: target.energy - current.energy,
            mood: target.mood - current.mood,
            trust: target.trust - current.trust
        )
    }
}
