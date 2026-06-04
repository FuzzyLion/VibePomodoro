import ActivityKit
import Foundation

struct PomodoroActivityAttributes: ActivityAttributes, Equatable {
    struct ScheduledStep: Codable, Equatable, Hashable {
        let phase: PomodoroActivityPhase
        let roundNumber: Int
        let stepDuration: TimeInterval
        let startDate: Date
        let endDate: Date
    }

    struct ContentState: Codable, Equatable, Hashable {
        let sessionID: String
        let phase: PomodoroActivityPhase
        let roundNumber: Int
        let targetRounds: Int
        let runState: PomodoroActivityRunState
        let stepDuration: TimeInterval
        let targetEndDate: Date?
        let pausedRemainingDuration: TimeInterval?
        let scheduledSteps: [ScheduledStep]
    }
}

extension PomodoroActivityAttributes.ContentState {
    var shouldUseTimelineDisplay: Bool {
        runState == .running && !scheduledSteps.isEmpty
    }

    func displayStep(at date: Date) -> PomodoroActivityAttributes.ScheduledStep? {
        guard shouldUseTimelineDisplay else { return nil }

        if let step = scheduledSteps.first(where: { date < $0.endDate }) {
            return step
        }

        return scheduledSteps.last
    }

    func displayRunState(at date: Date) -> PomodoroActivityRunState {
        guard shouldUseTimelineDisplay,
              let lastStep = scheduledSteps.last else {
            return runState
        }

        return date >= lastStep.endDate ? .completed : .running
    }

    func displayPhase(at date: Date) -> PomodoroActivityPhase {
        displayStep(at: date)?.phase ?? phase
    }

    func displayRoundNumber(at date: Date) -> Int {
        displayStep(at: date)?.roundNumber ?? roundNumber
    }

    func displayStepDuration(at date: Date) -> TimeInterval {
        displayStep(at: date)?.stepDuration ?? stepDuration
    }

    func displayTargetEndDate(at date: Date) -> Date? {
        guard displayRunState(at: date) == .running else { return nil }
        return displayStep(at: date)?.endDate ?? targetEndDate
    }

    func displayTimerInterval(at date: Date) -> ClosedRange<Date>? {
        guard let targetEndDate = displayTargetEndDate(at: date),
              targetEndDate > date else {
            return nil
        }

        return date...targetEndDate
    }

    func displayTimerPauseTime(at date: Date) -> Date? {
        nil
    }

    func roundText(at date: Date = .now) -> String {
        "Round \(displayRoundNumber(at: date))/\(targetRounds)"
    }

    func remainingDuration(at date: Date) -> TimeInterval {
        switch displayRunState(at: date) {
        case .running:
            guard let targetEndDate = displayTargetEndDate(at: date) else { return 0 }
            return max(0, targetEndDate.timeIntervalSince(date))
        case .paused:
            return max(0, pausedRemainingDuration ?? 0)
        case .completed:
            return 0
        }
    }

    func stepProgress(at date: Date) -> Double {
        let displayRunState = displayRunState(at: date)
        let duration = displayStepDuration(at: date)
        guard duration > 0 else { return displayRunState == .completed ? 1 : 0 }
        guard displayRunState != .completed else { return 1 }

        if let step = displayStep(at: date) {
            return min(1, max(0, date.timeIntervalSince(step.startDate) / duration))
        }

        let remaining = remainingDuration(at: date)
        return min(1, max(0, 1 - (remaining / duration)))
    }
}

enum PomodoroActivityPhase: String, Codable, Equatable, Hashable {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus:
            return "Focus"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    var compactTitle: String {
        switch self {
        case .focus:
            return "Focus"
        case .shortBreak:
            return "Break"
        case .longBreak:
            return "Rest"
        }
    }
}

enum PomodoroActivityRunState: String, Codable, Equatable, Hashable {
    case running
    case paused
    case completed
}
