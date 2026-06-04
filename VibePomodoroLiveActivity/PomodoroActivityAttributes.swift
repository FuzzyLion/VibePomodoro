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
