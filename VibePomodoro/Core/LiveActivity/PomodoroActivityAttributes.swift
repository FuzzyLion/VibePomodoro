import ActivityKit
import Foundation

struct PomodoroActivityAttributes: ActivityAttributes, Equatable {
    struct ContentState: Codable, Equatable, Hashable {
        let sessionID: String
        let phase: PomodoroActivityPhase
        let roundNumber: Int
        let targetRounds: Int
        let runState: PomodoroActivityRunState
        let targetEndDate: Date?
        let pausedRemainingDuration: TimeInterval?
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
}

enum PomodoroActivityRunState: String, Codable, Equatable, Hashable {
    case running
    case paused
    case completed
}

struct PomodoroLiveActivitySnapshot: Equatable {
    let attributes: PomodoroActivityAttributes
    let contentState: PomodoroActivityAttributes.ContentState

    init?(session: SessionSnapshot?, now: Date = .now) {
        guard let session,
              session.runState != .idle else {
            return nil
        }

        let displayStep: SessionStep?
        if let currentStep = session.currentStep {
            displayStep = currentStep
        } else if session.runState == .completed {
            displayStep = session.steps.last
        } else {
            displayStep = nil
        }

        guard let step = displayStep else {
            return nil
        }

        let runState: PomodoroActivityRunState
        let targetEndDate: Date?
        let pausedRemainingDuration: TimeInterval?

        switch session.runState {
        case .running:
            runState = .running
            targetEndDate = session.targetEndDate
            pausedRemainingDuration = nil
        case .paused:
            runState = .paused
            targetEndDate = nil
            pausedRemainingDuration = session.remainingDuration(now: now)
        case .completed:
            runState = .completed
            targetEndDate = nil
            pausedRemainingDuration = 0
        case .idle:
            return nil
        }

        self.attributes = PomodoroActivityAttributes()
        self.contentState = PomodoroActivityAttributes.ContentState(
            sessionID: session.id.uuidString,
            phase: PomodoroActivityPhase(sessionPhase: step.phase),
            roundNumber: step.roundNumber,
            targetRounds: session.targetRounds,
            runState: runState,
            targetEndDate: targetEndDate,
            pausedRemainingDuration: pausedRemainingDuration
        )
    }
}

extension PomodoroActivityPhase {
    init(sessionPhase: SessionPhase) {
        switch sessionPhase {
        case .focus:
            self = .focus
        case .shortBreak:
            self = .shortBreak
        case .longBreak:
            self = .longBreak
        }
    }
}
