import Foundation

struct PawsCalculator {
    static func calculateBreathingPaws(durationSeconds: Int) -> Int {
        let minutes = durationSeconds / 60
        return minutes * Constants.Paws.breathingPawsPerMinute
    }

    static func calculateMeditationPaws(durationSeconds: Int) -> Int {
        let minutes = durationSeconds / 60
        return minutes * Constants.Paws.meditationPawsPerMinute
    }

    static func calculateChallengePaws() -> Int {
        return Constants.Paws.challengeCompletionPaws
    }

    static func formatDuration(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
