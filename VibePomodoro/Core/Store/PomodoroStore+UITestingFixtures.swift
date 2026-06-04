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

    static func seedUITestingTimerFixtureIfRequested(using defaults: UserDefaults) {
        guard isUITestingLaunch,
              ProcessInfo.processInfo.environment[timerFixtureEnvironmentKey] == "live-activity-boundary"
                || ProcessInfo.processInfo.arguments.contains(liveActivityBoundaryFixtureArgument) else {
            return
        }

        let now = Date.now
        let settings = makeLiveActivityBoundarySettings()
        var session = SessionSnapshot.makeNew(settings: settings, now: now)
        _ = PomodoroEngine.startOrResume(session: &session, now: now)

        saveValue(settings, for: StorageKey.settings, using: defaults, encoder: JSONEncoder())
        saveValue(session, for: StorageKey.activeSession, using: defaults, encoder: JSONEncoder())
        defaults.removeObject(forKey: StorageKey.completedSessions)
        defaults.removeObject(forKey: StorageKey.productivityCache)
    }
}

private extension PomodoroStore {
    static func makeLiveActivityBoundarySettings() -> PomodoroSettings {
        var settings = PomodoroSettings.default
        settings.focusMinutes = 1
        settings.shortBreakMinutes = 1
        settings.longBreakMinutes = 1
        settings.targetRounds = 2
        settings.notificationsEnabled = false
        settings.soundEnabled = false
        settings.hapticsEnabled = false
        return settings
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
