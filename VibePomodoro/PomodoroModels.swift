import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case focus
    case productivity
    case settings

    var id: String { rawValue }
}

enum SessionPhase: String, Codable, CaseIterable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

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

    var detailTitle: String {
        switch self {
        case .focus:
            return "Focus Session"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    var systemImage: String {
        switch self {
        case .focus:
            return "timer"
        case .shortBreak:
            return "cup.and.saucer"
        case .longBreak:
            return "sparkles"
        }
    }
}

enum SessionRunState: String, Codable {
    case idle
    case running
    case paused
    case completed
}

enum SoundOption: String, Codable, CaseIterable, Identifiable {
    case chime
    case bell
    case glow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chime:
            return "Soft Chime"
        case .bell:
            return "Warm Bell"
        case .glow:
            return "Glass Glow"
        }
    }
}

struct PomodoroSettings: Codable, Equatable {
    var focusMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var targetRounds: Int = 4

    var keepScreenOn: Bool = true
    var notificationsEnabled: Bool = true
    var soundEnabled: Bool = true
    var selectedSound: SoundOption = .chime
    var hapticsEnabled: Bool = true

    var focusDuration: TimeInterval { TimeInterval(focusMinutes * 60) }
    var shortBreakDuration: TimeInterval { TimeInterval(shortBreakMinutes * 60) }
    var longBreakDuration: TimeInterval { TimeInterval(longBreakMinutes * 60) }

    static let `default` = PomodoroSettings()
}

struct SessionStep: Codable, Equatable, Identifiable {
    let id: UUID
    let phase: SessionPhase
    let roundNumber: Int
    let plannedDuration: TimeInterval
}

struct ActivitySegment: Codable, Equatable, Identifiable {
    let id: UUID
    let stepID: UUID
    let phase: SessionPhase
    let roundNumber: Int
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }
}

struct SessionStatistics: Equatable {
    let focusTime: TimeInterval
    let shortBreakTime: TimeInterval
    let longBreakTime: TimeInterval
    let completedFocusCount: Int

    var breakTime: TimeInterval {
        shortBreakTime + longBreakTime
    }

    var sessionTime: TimeInterval {
        focusTime + breakTime
    }
}

struct SessionSnapshot: Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let settingsSnapshot: PomodoroSettings
    var steps: [SessionStep]
    var currentStepIndex: Int
    var runState: SessionRunState
    var currentSegmentStartDate: Date?
    var targetEndDate: Date?
    var segments: [ActivitySegment]

    static func makeNew(settings: PomodoroSettings, now: Date = .now) -> SessionSnapshot {
        SessionSnapshot(
            id: UUID(),
            createdAt: now,
            settingsSnapshot: settings,
            steps: Self.buildSteps(from: settings),
            currentStepIndex: 0,
            runState: .idle,
            currentSegmentStartDate: nil,
            targetEndDate: nil,
            segments: []
        )
    }

    static func buildSteps(from settings: PomodoroSettings) -> [SessionStep] {
        var steps: [SessionStep] = []

        for round in 1...max(1, settings.targetRounds) {
            steps.append(
                SessionStep(
                    id: UUID(),
                    phase: .focus,
                    roundNumber: round,
                    plannedDuration: settings.focusDuration
                )
            )

            let breakPhase: SessionPhase = round == max(1, settings.targetRounds) ? .longBreak : .shortBreak
            let breakDuration = round == max(1, settings.targetRounds) ? settings.longBreakDuration : settings.shortBreakDuration

            steps.append(
                SessionStep(
                    id: UUID(),
                    phase: breakPhase,
                    roundNumber: round,
                    plannedDuration: breakDuration
                )
            )
        }

        return steps
    }

    var currentStep: SessionStep? {
        guard steps.indices.contains(currentStepIndex) else { return nil }
        return steps[currentStepIndex]
    }

    var currentPhase: SessionPhase? {
        currentStep?.phase
    }

    var targetRounds: Int {
        settingsSnapshot.targetRounds
    }

    func accumulatedDuration(for step: SessionStep) -> TimeInterval {
        min(step.plannedDuration, segments.filter { $0.stepID == step.id }.reduce(0) { $0 + $1.duration })
    }

    func elapsedDuration(now: Date) -> TimeInterval {
        guard let step = currentStep else { return 0 }

        let committed = accumulatedDuration(for: step)
        guard runState == .running, let segmentStart = currentSegmentStartDate else {
            return committed
        }

        let inFlight = max(0, now.timeIntervalSince(segmentStart))
        return min(step.plannedDuration, committed + inFlight)
    }

    func remainingDuration(now: Date) -> TimeInterval {
        guard let step = currentStep else { return 0 }
        return max(0, step.plannedDuration - elapsedDuration(now: now))
    }

    func statistics(now: Date) -> SessionStatistics {
        var durationsByStepID: [UUID: TimeInterval] = [:]

        for step in steps {
            durationsByStepID[step.id] = accumulatedDuration(for: step)
        }

        if runState == .running, let step = currentStep {
            durationsByStepID[step.id] = elapsedDuration(now: now)
        }

        var focusTime: TimeInterval = 0
        var shortBreakTime: TimeInterval = 0
        var longBreakTime: TimeInterval = 0
        var completedFocusCount = 0

        for step in steps {
            let actual = durationsByStepID[step.id] ?? 0

            switch step.phase {
            case .focus:
                focusTime += actual
                if actual >= step.plannedDuration - 0.5 {
                    completedFocusCount += 1
                }
            case .shortBreak:
                shortBreakTime += actual
            case .longBreak:
                longBreakTime += actual
            }
        }

        return SessionStatistics(
            focusTime: focusTime,
            shortBreakTime: shortBreakTime,
            longBreakTime: longBreakTime,
            completedFocusCount: completedFocusCount
        )
    }
}

struct CompletedSession: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let completedAt: Date
    let settingsSnapshot: PomodoroSettings
    let segments: [ActivitySegment]

    var completedFocusCount: Int {
        Set(segments.filter { $0.phase == .focus }.map(\.roundNumber)).count
    }
}

struct DailyStatisticsPoint: Identifiable, Equatable {
    let date: Date
    let focusTime: TimeInterval
    let shortBreakTime: TimeInterval
    let longBreakTime: TimeInterval

    var id: Date { date }

    var breakTime: TimeInterval {
        shortBreakTime + longBreakTime
    }

    var sessionTime: TimeInterval {
        focusTime + breakTime
    }
}

enum ProductivityRange: String, CaseIterable, Identifiable {
    case day = "D"
    case week = "W"
    case month = "M"
    case year = "Y"

    var id: String { rawValue }
}

enum PomodoroEvent: Equatable {
    case phaseStarted(SessionPhase, Int)
    case phaseCompleted(SessionPhase, Int)
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
        guard session.runState != .completed, session.currentStep != nil else { return [] }

        let shouldContinueRunning = session.runState == .running
        if shouldContinueRunning {
            commitRunningSegment(session: &session, endDate: now)
        }

        return advanceToNextStep(session: &session, startDate: now, shouldContinueRunning: shouldContinueRunning)
    }

    static func resetCurrentStep(session: inout SessionSnapshot, now: Date = .now) -> [PomodoroEvent] {
        guard session.runState != .completed, let step = session.currentStep else { return [] }

        session.segments.removeAll { $0.stepID == step.id }
        session.currentSegmentStartDate = nil
        session.targetEndDate = nil

        guard session.runState == .running else {
            session.runState = .idle
            return []
        }

        session.currentSegmentStartDate = now
        session.targetEndDate = now.addingTimeInterval(step.plannedDuration)
        return [.phaseStarted(step.phase, step.roundNumber)]
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

        if shouldContinueRunning {
            session.runState = .running
            session.currentSegmentStartDate = now
            session.targetEndDate = now.addingTimeInterval(session.steps[targetIndex].plannedDuration)
            return [.phaseStarted(session.steps[targetIndex].phase, session.steps[targetIndex].roundNumber)]
        }

        let hasAnyElapsed = session.steps.contains { session.accumulatedDuration(for: $0) > 0 }
        session.runState = hasAnyElapsed ? .paused : .idle
        return []
    }

    static func reconcile(session: inout SessionSnapshot, now: Date = .now) -> [PomodoroEvent] {
        guard session.runState == .running else { return [] }

        var events: [PomodoroEvent] = []

        while session.runState == .running, let step = session.currentStep,
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

    private static func advanceToNextStep(session: inout SessionSnapshot, startDate: Date, shouldContinueRunning: Bool) -> [PomodoroEvent] {
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
