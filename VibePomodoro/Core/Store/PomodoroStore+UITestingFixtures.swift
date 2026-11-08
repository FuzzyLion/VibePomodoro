import Foundation

extension PomodoroStore {
    static func seedUITestingProductivityFixtureIfRequested(using defaults: UserDefaults) {
        guard isUITestingLaunch,
              ProcessInfo.processInfo.environment[productivityFixtureEnvironmentKey] == "long-extreme" else {
            return
        }

        let sessions = makeLongExtremeProductivityFixture(now: .now)
        saveValue(sessions, for: StorageKey.completedSessions, using: defaults, encoder: JSONEncoder())
        defaults.removeObject(forKey: StorageKey.productivityCache)
    }

    /// Seeds an active session for screenshots, for example `focus-2-0.5` (paused halfway through
    /// the second focus block) or `shortBreak-1-0.3-running`. Earlier steps count as completed.
    static func seedUITestingFocusFixtureIfRequested(using defaults: UserDefaults) {
        guard isUITestingLaunch,
              let fixture = ProcessInfo.processInfo.environment[focusFixtureEnvironmentKey],
              let session = makeFocusFixture(fixture, now: .now) else {
            return
        }

        saveValue(session, for: StorageKey.activeSession, using: defaults, encoder: JSONEncoder())
    }
}

private extension PomodoroStore {
    static func makeFocusFixture(_ fixture: String, now: Date) -> SessionSnapshot? {
        let parts = fixture.split(separator: "-").map(String.init)
        guard parts.count >= 3,
              let phase = SessionPhase(rawValue: parts[0]),
              let round = Int(parts[1]),
              let progress = Double(parts[2]) else {
            return nil
        }

        let isRunning = parts.count > 3 && parts[3] == "running"
        var session = SessionSnapshot.makeNew(settings: .default, now: now.addingTimeInterval(-24 * 3_600))
        guard let targetIndex = session.steps.firstIndex(where: { $0.phase == phase && $0.roundNumber == round }) else {
            return nil
        }

        let target = session.steps[targetIndex]
        let elapsed = target.plannedDuration * min(max(progress, 0.001), 0.999)
        var segmentEnd = now
        var segments: [ActivitySegment] = []

        for step in session.steps[...targetIndex].reversed() {
            let duration = step.id == target.id ? elapsed : step.plannedDuration
            let segmentStart = segmentEnd.addingTimeInterval(-duration)
            segments.insert(
                ActivitySegment(
                    id: UUID(),
                    stepID: step.id,
                    phase: step.phase,
                    roundNumber: step.roundNumber,
                    startDate: segmentStart,
                    endDate: segmentEnd
                ),
                at: 0
            )
            segmentEnd = segmentStart
        }

        session.segments = segments
        session.currentStepIndex = targetIndex
        session.runState = isRunning ? .running : .paused
        session.currentSegmentStartDate = isRunning ? now : nil
        session.targetEndDate = isRunning ? now.addingTimeInterval(target.plannedDuration - elapsed) : nil
        return session
    }

    static func makeLongExtremeProductivityFixture(
        now: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [CompletedSession] {
        var settings = PomodoroSettings.default
        settings.focusMinutes = 90
        settings.shortBreakMinutes = 15
        settings.longBreakMinutes = 60
        settings.targetRounds = 1

        let today = calendar.startOfDay(for: now)
        let recentSessions = (0..<30).compactMap { offset -> CompletedSession? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let focusDuration = TimeInterval((90 + (offset % 5) * 30) * 60)
            let breakDuration = TimeInterval((30 + (offset % 3) * 15) * 60)
            return makeFixtureSession(
                settings: settings,
                start: day.addingTimeInterval(9 * 3_600),
                focusDuration: focusDuration,
                breakDuration: breakDuration
            )
        }

        let olderMonthlySessions = (1..<12).compactMap { offset -> CompletedSession? in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: today),
                  let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
                return nil
            }
            let focusDuration = TimeInterval((120 + (offset % 4) * 45) * 60)
            let breakDuration = TimeInterval((45 + (offset % 2) * 30) * 60)
            return makeFixtureSession(
                settings: settings,
                start: monthStart.addingTimeInterval(10 * 24 * 3_600 + 8 * 3_600),
                focusDuration: focusDuration,
                breakDuration: breakDuration
            )
        }

        return recentSessions + olderMonthlySessions
    }

    static func makeFixtureSession(
        settings: PomodoroSettings,
        start: Date,
        focusDuration: TimeInterval,
        breakDuration: TimeInterval
    ) -> CompletedSession {
        let focusStepID = UUID()
        let breakStepID = UUID()
        let focusEnd = start.addingTimeInterval(focusDuration)
        let breakEnd = focusEnd.addingTimeInterval(breakDuration)

        return CompletedSession(
            id: UUID(),
            createdAt: start,
            completedAt: breakEnd,
            settingsSnapshot: settings,
            segments: [
                ActivitySegment(
                    id: UUID(),
                    stepID: focusStepID,
                    phase: .focus,
                    roundNumber: 1,
                    startDate: start,
                    endDate: focusEnd
                ),
                ActivitySegment(
                    id: UUID(),
                    stepID: breakStepID,
                    phase: .longBreak,
                    roundNumber: 1,
                    startDate: focusEnd,
                    endDate: breakEnd
                )
            ]
        )
    }
}
