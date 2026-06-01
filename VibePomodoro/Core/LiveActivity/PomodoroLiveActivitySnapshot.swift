import Foundation

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
