import Foundation

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
        let targetRounds = max(1, settings.targetRounds)
        var steps: [SessionStep] = []

        for round in 1...targetRounds {
            steps.append(
                SessionStep(
                    id: UUID(),
                    phase: .focus,
                    roundNumber: round,
                    plannedDuration: settings.focusDuration
                )
            )

            let isFinalRound = round == targetRounds
            steps.append(
                SessionStep(
                    id: UUID(),
                    phase: isFinalRound ? .longBreak : .shortBreak,
                    roundNumber: round,
                    plannedDuration: isFinalRound ? settings.longBreakDuration : settings.shortBreakDuration
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

    func hasElapsedTime(now: Date) -> Bool {
        if !segments.isEmpty {
            return true
        }

        guard runState == .running, let currentSegmentStartDate else {
            return false
        }

        return now > currentSegmentStartDate
    }

    /// A focus block counts as completed only when it reached its full planned duration.
    static func isCompletedFocus(duration: TimeInterval, plannedDuration: TimeInterval) -> Bool {
        duration >= plannedDuration - 0.5
    }

    /// Whether the focus block of `round` has been recorded for its full planned duration.
    func isFocusRoundCompleted(_ round: Int) -> Bool {
        guard let step = steps.first(where: { $0.phase == .focus && $0.roundNumber == round }) else {
            return false
        }

        return Self.isCompletedFocus(duration: accumulatedDuration(for: step), plannedDuration: step.plannedDuration)
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
                if Self.isCompletedFocus(duration: actual, plannedDuration: step.plannedDuration) {
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

    var totalFocusTime: TimeInterval {
        totalDuration(for: .focus)
    }

    var totalShortBreakTime: TimeInterval {
        totalDuration(for: .shortBreak)
    }

    var totalLongBreakTime: TimeInterval {
        totalDuration(for: .longBreak)
    }

    var completedFocusCount: Int {
        completedFocusCompletionDates().count
    }

    func completedFocusCompletionDates() -> [Date] {
        let completionThreshold = max(0, settingsSnapshot.focusDuration - 0.5)
        guard completionThreshold > 0 else { return [] }

        let focusByRound = Dictionary(grouping: segments.filter { $0.phase == .focus }, by: \.roundNumber)

        return focusByRound.values.compactMap { roundSegments in
            let sortedSegments = roundSegments.sorted { lhs, rhs in
                if lhs.startDate == rhs.startDate {
                    return lhs.endDate < rhs.endDate
                }
                return lhs.startDate < rhs.startDate
            }

            var accumulated: TimeInterval = 0

            for segment in sortedSegments {
                let nextAccumulated = accumulated + segment.duration
                if nextAccumulated >= completionThreshold {
                    let remaining = max(0, completionThreshold - accumulated)
                    return segment.startDate.addingTimeInterval(min(segment.duration, remaining))
                }
                accumulated = nextAccumulated
            }

            return nil
        }
        .sorted()
    }

    private func totalDuration(for phase: SessionPhase) -> TimeInterval {
        segments.reduce(0) { total, segment in
            total + (segment.phase == phase ? segment.duration : 0)
        }
    }
}
