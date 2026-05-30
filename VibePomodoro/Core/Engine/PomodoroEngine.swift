import Foundation

enum PomodoroEvent: Equatable {
    case phaseStarted(SessionPhase, Int)
    case phaseCompleted(SessionPhase, Int)
    case phaseSkipped(SessionPhase, Int)
    case phaseRewound(SessionPhase, Int)
    case phaseReset(SessionPhase, Int)
    case sessionCompleted
}

enum PomodoroEngine {
    static func startOrResume(session: inout SessionSnapshot, now: Date = .now) -> [PomodoroEvent] {
        guard session.runState != .completed else { return [] }
        guard let step = session.currentStep else {
            session.runState = .completed
            return []
        }

        if session.runState == .running {
            return []
        }

        let remaining = session.remainingDuration(now: now)
        guard remaining > 0 else {
            return reconcile(session: &session, now: now)
        }

        session.runState = .running
        session.currentSegmentStartDate = now
        session.targetEndDate = now.addingTimeInterval(remaining)

        if session.accumulatedDuration(for: step) == 0 {
            return [.phaseStarted(step.phase, step.roundNumber)]
        }

        return []
    }

    static func pause(session: inout SessionSnapshot, now: Date = .now) {
        guard session.runState == .running else { return }
        commitRunningSegment(session: &session, endDate: now)
        session.runState = .paused
        session.currentSegmentStartDate = nil
        session.targetEndDate = nil
    }

    static func skip(session: inout SessionSnapshot, now: Date = .now) -> [PomodoroEvent] {
        guard session.runState != .completed, let step = session.currentStep else { return [] }

        let shouldContinueRunning = session.runState == .running
        if shouldContinueRunning {
            commitRunningSegment(session: &session, endDate: now)
        }

        return [.phaseSkipped(step.phase, step.roundNumber)]
            + advanceToNextStep(session: &session, startDate: now, shouldContinueRunning: shouldContinueRunning)
    }

    static func finishSessionEarly(session: inout SessionSnapshot, now: Date = .now) -> [PomodoroEvent] {
        guard session.runState != .completed else { return [] }
        guard session.hasElapsedTime(now: now) else { return [] }

        if session.runState == .running {
            commitRunningSegment(session: &session, endDate: now)
        }

        session.currentSegmentStartDate = nil
        session.targetEndDate = nil
        session.runState = .completed
        return [.sessionCompleted]
    }

    static func resetCurrentStep(session: inout SessionSnapshot, now: Date = .now) -> [PomodoroEvent] {
        guard session.runState != .completed, let step = session.currentStep else { return [] }

        session.segments.removeAll { $0.stepID == step.id }
        session.currentSegmentStartDate = nil
        session.targetEndDate = nil

        let resetEvent: [PomodoroEvent] = [.phaseReset(step.phase, step.roundNumber)]

        guard session.runState == .running else {
            session.runState = .idle
            return resetEvent
        }

        session.currentSegmentStartDate = now
        session.targetEndDate = now.addingTimeInterval(step.plannedDuration)
        return resetEvent + [.phaseStarted(step.phase, step.roundNumber)]
    }

    static func goBack(session: inout SessionSnapshot, now: Date = .now) -> [PomodoroEvent] {
        guard !session.steps.isEmpty else { return [] }

        let shouldContinueRunning = session.runState == .running
        let currentIndex = min(session.currentStepIndex, max(0, session.steps.count - 1))
        let targetIndex = max(0, currentIndex - 1)

        var stepIDsToClear: Set<UUID> = [session.steps[targetIndex].id]
        if session.steps.indices.contains(currentIndex), currentIndex != targetIndex {
            stepIDsToClear.insert(session.steps[currentIndex].id)
        }

        session.segments.removeAll { stepIDsToClear.contains($0.stepID) }
        session.currentStepIndex = targetIndex
        session.currentSegmentStartDate = nil
        session.targetEndDate = nil

        let targetStep = session.steps[targetIndex]
        let directionEvent: PomodoroEvent = currentIndex == targetIndex
            ? .phaseReset(targetStep.phase, targetStep.roundNumber)
            : .phaseRewound(targetStep.phase, targetStep.roundNumber)

        if shouldContinueRunning {
            session.runState = .running
            session.currentSegmentStartDate = now
            session.targetEndDate = now.addingTimeInterval(targetStep.plannedDuration)
            return [directionEvent, .phaseStarted(targetStep.phase, targetStep.roundNumber)]
        }

        let hasAnyElapsed = session.steps.contains { session.accumulatedDuration(for: $0) > 0 }
        session.runState = hasAnyElapsed ? .paused : .idle
        return [directionEvent]
    }

    static func reconcile(session: inout SessionSnapshot, now: Date = .now) -> [PomodoroEvent] {
        guard session.runState == .running else { return [] }

        var events: [PomodoroEvent] = []

        while session.runState == .running,
              let step = session.currentStep,
              let segmentStart = session.currentSegmentStartDate,
              let targetEndDate = session.targetEndDate {
            if now < targetEndDate {
                break
            }

            if targetEndDate > segmentStart {
                session.segments.append(
                    ActivitySegment(
                        id: UUID(),
                        stepID: step.id,
                        phase: step.phase,
                        roundNumber: step.roundNumber,
                        startDate: segmentStart,
                        endDate: targetEndDate
                    )
                )
            }

            events.append(.phaseCompleted(step.phase, step.roundNumber))
            events.append(contentsOf: advanceToNextStep(session: &session, startDate: targetEndDate, shouldContinueRunning: true))
        }

        return events
    }

    private static func commitRunningSegment(session: inout SessionSnapshot, endDate: Date) {
        guard session.runState == .running,
              let step = session.currentStep,
              let startDate = session.currentSegmentStartDate else {
            return
        }

        let actualEndDate: Date
        if let targetEndDate = session.targetEndDate {
            actualEndDate = min(endDate, targetEndDate)
        } else {
            actualEndDate = endDate
        }

        guard actualEndDate > startDate else { return }

        session.segments.append(
            ActivitySegment(
                id: UUID(),
                stepID: step.id,
                phase: step.phase,
                roundNumber: step.roundNumber,
                startDate: startDate,
                endDate: actualEndDate
            )
        )
    }

    private static func advanceToNextStep(
        session: inout SessionSnapshot,
        startDate: Date,
        shouldContinueRunning: Bool
    ) -> [PomodoroEvent] {
        session.currentSegmentStartDate = nil
        session.targetEndDate = nil

        let nextIndex = session.currentStepIndex + 1
        guard session.steps.indices.contains(nextIndex) else {
            session.currentStepIndex = session.steps.count
            session.runState = .completed
            return [.sessionCompleted]
        }

        session.currentStepIndex = nextIndex
        session.runState = shouldContinueRunning ? .running : .paused

        guard shouldContinueRunning else { return [] }

        let nextStep = session.steps[nextIndex]
        session.currentSegmentStartDate = startDate
        session.targetEndDate = startDate.addingTimeInterval(nextStep.plannedDuration)
        return [.phaseStarted(nextStep.phase, nextStep.roundNumber)]
    }
}
