//
//  VibePomodoroTests.swift
//  VibePomodoroTests
//
//  Created by Qi Wu on 15.03.26.
//

import Foundation
import Testing
@testable import VibePomodoro

@MainActor
struct VibePomodoroTests {

    private enum TestStorageKey {
        static let activeSession = "vibe.activeSession"
        static let completedSessions = "vibe.completedSessions"
    }

    @Test func skipRecordsElapsedFocusButNotCompletedRound() async throws {
        var settings = PomodoroSettings.default
        settings.focusMinutes = 25
        settings.shortBreakMinutes = 5
        settings.longBreakMinutes = 15
        settings.targetRounds = 2

        let start = Date(timeIntervalSince1970: 1_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)

        let skipTime = start.addingTimeInterval(5 * 60)
        _ = PomodoroEngine.skip(session: &session, now: skipTime)

        let stats = session.statistics(now: skipTime)

        #expect(session.currentPhase == SessionPhase.shortBreak)
        #expect(session.runState == SessionRunState.running)
        #expect(stats.focusTime == 5 * 60)
        #expect(stats.completedFocusCount == 0)
    }

    @Test func backRollsBackPreviousStepStatistics() async throws {
        var settings = PomodoroSettings.default
        settings.targetRounds = 2

        let start = Date(timeIntervalSince1970: 10_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)

        let breakStart = start.addingTimeInterval(settings.focusDuration)
        _ = PomodoroEngine.reconcile(session: &session, now: breakStart)
        _ = PomodoroEngine.goBack(session: &session, now: breakStart.addingTimeInterval(60))

        let stats = session.statistics(now: breakStart.addingTimeInterval(60))

        #expect(session.currentPhase == SessionPhase.focus)
        #expect(stats.focusTime == 0)
        #expect(stats.breakTime == 0)
        #expect(stats.completedFocusCount == 0)
    }

    @Test func sessionCompletesOnlyAfterFinalLongBreak() async throws {
        var settings = PomodoroSettings.default
        settings.targetRounds = 1

        let start = Date(timeIntervalSince1970: 20_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)

        let finalTime = start.addingTimeInterval(settings.focusDuration + settings.longBreakDuration)
        let events = PomodoroEngine.reconcile(session: &session, now: finalTime)

        #expect(session.runState == SessionRunState.completed)
        #expect(session.currentStep == nil)
        #expect(events.contains(PomodoroEvent.sessionCompleted))
    }

    @Test func reconcileAutoAdvancesAcrossMultipleSteps() async throws {
        var settings = PomodoroSettings.default
        settings.focusMinutes = 25
        settings.shortBreakMinutes = 5
        settings.longBreakMinutes = 15
        settings.targetRounds = 2

        let start = Date(timeIntervalSince1970: 30_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)

        let awayTime = start.addingTimeInterval((25 + 5 + 10) * 60)
        _ = PomodoroEngine.reconcile(session: &session, now: awayTime)

        let stats = session.statistics(now: awayTime)

        #expect(session.currentPhase == SessionPhase.focus)
        #expect(session.currentStep?.roundNumber == 2)
        #expect(stats.focusTime == 35 * 60)
        #expect(stats.shortBreakTime == 5 * 60)
        #expect(stats.completedFocusCount == 1)
    }

    @Test func productivitySnapshotIgnoresActiveSessionUntilCompletion() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        let now = Date()
        let completedSession = makeCompletedSession(
            settings: .default,
            createdAt: now.addingTimeInterval(-86_400),
            completedAt: now.addingTimeInterval(-85_200),
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: now.addingTimeInterval(-86_400),
                    endDate: now.addingTimeInterval(-84_900)
                ),
                makeSegment(
                    phase: .longBreak,
                    roundNumber: 1,
                    startDate: now.addingTimeInterval(-84_900),
                    endDate: now.addingTimeInterval(-84_000)
                )
            ]
        )

        var activeSession = SessionSnapshot.makeNew(settings: .default, now: now.addingTimeInterval(-600))
        let currentStep = try #require(activeSession.currentStep)
        activeSession.runState = .running
        activeSession.segments = [
            ActivitySegment(
                id: UUID(),
                stepID: currentStep.id,
                phase: .focus,
                roundNumber: currentStep.roundNumber,
                startDate: now.addingTimeInterval(-600),
                endDate: now.addingTimeInterval(-300)
            )
        ]
        activeSession.currentSegmentStartDate = now.addingTimeInterval(-300)
        activeSession.targetEndDate = now.addingTimeInterval(1_200)

        saveValue([completedSession], for: TestStorageKey.completedSessions, defaults: defaults)
        saveValue(activeSession, for: TestStorageKey.activeSession, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)
        let snapshot = store.productivitySnapshot(for: .week, now: now)

        #expect(snapshot.completedSessionCount == 1)
        #expect(snapshot.completedFocusCount == completedSession.completedFocusCount)
        #expect(snapshot.totalFocusTime == completedSession.totalFocusTime)
        #expect(snapshot.totalBreakTime == completedSession.totalLongBreakTime)
        #expect(snapshot.totalSessionTime == completedSession.totalFocusTime + completedSession.totalLongBreakTime)

        let chartFocus = snapshot.chartPoints.reduce(0) { $0 + $1.focusTime }
        let chartCompletedFocus = snapshot.chartPoints.reduce(0) { $0 + $1.completedFocusCount }
        #expect(chartFocus == completedSession.totalFocusTime)
        #expect(chartCompletedFocus == completedSession.completedFocusCount)
    }

    @Test func productivityCacheRebuildsFromCompletedSessionsAndSplitsAcrossDays() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.focusMinutes = 20
        settings.targetRounds = 1

        let calendar = Calendar(identifier: .gregorian)
        let dayOne = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 23, minute: 50)))
        let dayTwo = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 11, hour: 0, minute: 10)))
        let completedSession = makeCompletedSession(
            settings: settings,
            createdAt: dayOne,
            completedAt: dayTwo,
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: dayOne,
                    endDate: dayTwo
                )
            ]
        )

        saveValue([completedSession], for: TestStorageKey.completedSessions, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)

        #expect(store.productivityCache.completedSessionCount == 1)
        #expect(store.productivityCache.totalFocusTime == 20 * 60)
        #expect(store.productivityCache.dailySummaries.count == 2)
        #expect(store.productivityCache.dailySummaries.map(\.focusTime) == [10.0 * 60.0, 10.0 * 60.0])
        #expect(store.productivityCache.dailySummaries.map(\.completedFocusCount) == [0, 1])
        #expect(abs(store.productivityCache.averageFocusHoursPerDay - (1.0 / 6.0)) < 0.0001)
    }

    @Test func sessionCompletionUpdatesCacheOnceAndDoesNotDoubleCountOnRelaunch() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.focusMinutes = 25
        settings.longBreakMinutes = 15
        settings.targetRounds = 1

        let start = Date().addingTimeInterval(-(settings.focusDuration + settings.longBreakDuration + 60))
        var activeSession = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &activeSession, now: start)

        saveValue(activeSession, for: TestStorageKey.activeSession, defaults: defaults)

        let firstStore = PomodoroStore(defaults: defaults)
        let firstSnapshot = firstStore.productivitySnapshot(for: .week, now: Date())

        #expect(firstStore.completedSessions.count == 1)
        #expect(firstSnapshot.completedSessionCount == 1)
        #expect(firstSnapshot.totalFocusTime == settings.focusDuration)
        #expect(firstSnapshot.totalBreakTime == settings.longBreakDuration)
        #expect(firstStore.productivityCache.accountedSessionIDs.count == 1)

        let secondStore = PomodoroStore(defaults: defaults)
        let secondSnapshot = secondStore.productivitySnapshot(for: .week, now: Date())

        #expect(secondStore.completedSessions.count == 1)
        #expect(secondSnapshot.completedSessionCount == 1)
        #expect(secondSnapshot.totalFocusTime == settings.focusDuration)
        #expect(secondSnapshot.totalBreakTime == settings.longBreakDuration)
        #expect(secondSnapshot.completedFocusCount == 1)
        #expect(secondStore.productivityCache.accountedSessionIDs.count == 1)
    }

    @Test func completedFocusCountCacheDoesNotCountSkippedRounds() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.focusMinutes = 25
        settings.shortBreakMinutes = 5
        settings.longBreakMinutes = 15
        settings.targetRounds = 2

        let start = Date()
        let completedSession = makeCompletedSession(
            settings: settings,
            createdAt: start,
            completedAt: start.addingTimeInterval(50 * 60),
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: start,
                    endDate: start.addingTimeInterval(5 * 60)
                ),
                makeSegment(
                    phase: .shortBreak,
                    roundNumber: 1,
                    startDate: start.addingTimeInterval(5 * 60),
                    endDate: start.addingTimeInterval(10 * 60)
                ),
                makeSegment(
                    phase: .focus,
                    roundNumber: 2,
                    startDate: start.addingTimeInterval(10 * 60),
                    endDate: start.addingTimeInterval(35 * 60)
                ),
                makeSegment(
                    phase: .longBreak,
                    roundNumber: 2,
                    startDate: start.addingTimeInterval(35 * 60),
                    endDate: start.addingTimeInterval(50 * 60)
                )
            ]
        )

        saveValue([completedSession], for: TestStorageKey.completedSessions, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)

        #expect(completedSession.completedFocusCount == 1)
        #expect(store.productivityCache.completedFocusCount == 1)
    }

    @Test func monthChartAggregatesDailyCache() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        let calendar = Calendar.autoupdatingCurrent
        let now = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12, minute: 0))
        )
        let completedSession = makeCompletedSession(
            settings: .default,
            createdAt: now.addingTimeInterval(-8_100),
            completedAt: now.addingTimeInterval(-1_800),
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: now.addingTimeInterval(-8_100),
                    endDate: now.addingTimeInterval(-2_700)
                ),
                makeSegment(
                    phase: .shortBreak,
                    roundNumber: 1,
                    startDate: now.addingTimeInterval(-2_700),
                    endDate: now.addingTimeInterval(-1_800)
                )
            ]
        )

        saveValue([completedSession], for: TestStorageKey.completedSessions, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)
        let points = store.chartPoints(for: .month, now: now)
        let todayStart = calendar.startOfDay(for: now)
        let pointForToday = points.first(where: { calendar.startOfDay(for: $0.startDate) == todayStart })

        #expect(points.count == 30)
        #expect(points.reduce(0) { $0 + $1.focusTime } == 90 * 60)
        #expect(points.reduce(0) { $0 + $1.breakTime } == 15 * 60)
        #expect(pointForToday?.focusTime == 90 * 60)
        #expect(pointForToday?.breakTime == 15 * 60)
        #expect(pointForToday?.completedFocusCount == 1)
    }

    @Test func yearChartAggregatesDailyCacheIntoMonths() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        let calendar = Calendar.autoupdatingCurrent
        let now = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 20, hour: 12, minute: 0))
        )
        let aprilSession = makeCompletedSession(
            settings: .default,
            createdAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 9, minute: 0))),
            completedAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 9, minute: 50))),
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 9, minute: 0))),
                    endDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 9, minute: 25)))
                ),
                makeSegment(
                    phase: .shortBreak,
                    roundNumber: 1,
                    startDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 9, minute: 25))),
                    endDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 10, hour: 9, minute: 30)))
                ),
                makeSegment(
                    phase: .focus,
                    roundNumber: 2,
                    startDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 12, hour: 18, minute: 0))),
                    endDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 12, hour: 18, minute: 25)))
                )
            ]
        )
        let maySession = makeCompletedSession(
            settings: .default,
            createdAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 2, hour: 8, minute: 0))),
            completedAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 2, hour: 8, minute: 30))),
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 2, hour: 8, minute: 0))),
                    endDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 2, hour: 8, minute: 20)))
                ),
                makeSegment(
                    phase: .longBreak,
                    roundNumber: 1,
                    startDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 2, hour: 8, minute: 20))),
                    endDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 2, hour: 8, minute: 30)))
                )
            ]
        )

        saveValue([maySession, aprilSession], for: TestStorageKey.completedSessions, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)
        let points = store.chartPoints(for: .year, now: now)
        let pointsByMonth = Dictionary(uniqueKeysWithValues: points.map { (calendar.component(.month, from: $0.startDate), $0) })

        #expect(points.reduce(0) { $0 + $1.focusTime } == 70 * 60)
        #expect(points.reduce(0) { $0 + $1.breakTime } == 15 * 60)
        #expect(points.reduce(0) { $0 + $1.completedFocusCount } == 3)
        #expect(pointsByMonth[4]?.focusTime == 50 * 60)
        #expect(pointsByMonth[4]?.breakTime == 5 * 60)
        #expect(pointsByMonth[4]?.completedFocusCount == 2)
        #expect(pointsByMonth[5]?.focusTime == 20 * 60)
        #expect(pointsByMonth[5]?.breakTime == 10 * 60)
        #expect(pointsByMonth[5]?.completedFocusCount == 1)
    }

    @Test func weekChartAggregatesSevenDailyBuckets() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        let calendar = Calendar.autoupdatingCurrent
        let now = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12, minute: 0))
        )
        let session = makeCompletedSession(
            settings: .default,
            createdAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 9, minute: 0))),
            completedAt: try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 9, minute: 30))),
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 9, minute: 0))),
                    endDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 9, minute: 25)))
                ),
                makeSegment(
                    phase: .longBreak,
                    roundNumber: 1,
                    startDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 9, minute: 25))),
                    endDate: try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 9, minute: 30)))
                )
            ]
        )

        saveValue([session], for: TestStorageKey.completedSessions, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)
        let points = store.chartPoints(for: .week, now: now)
        let march18 = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 18)))
        let pointForMarch18 = points.first(where: { calendar.startOfDay(for: $0.startDate) == march18 })

        #expect(points.count == 7)
        #expect(points.reduce(0) { $0 + $1.focusTime } == 25 * 60)
        #expect(points.reduce(0) { $0 + $1.breakTime } == 5 * 60)
        #expect(points.reduce(0) { $0 + $1.completedFocusCount } == 1)
        #expect(pointForMarch18?.sessionTime == 30 * 60)
    }

    @Test func completedFocusCountFallsOnCompletionDay() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.focusMinutes = 20
        settings.targetRounds = 1

        let calendar = Calendar(identifier: .gregorian)
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 23, minute: 50)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 11, hour: 0, minute: 10)))
        let completedSession = makeCompletedSession(
            settings: settings,
            createdAt: start,
            completedAt: end.addingTimeInterval(15 * 60),
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: start,
                    endDate: end
                ),
                makeSegment(
                    phase: .longBreak,
                    roundNumber: 1,
                    startDate: end,
                    endDate: end.addingTimeInterval(15 * 60)
                )
            ]
        )

        saveValue([completedSession], for: TestStorageKey.completedSessions, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)
        let summariesByDay = Dictionary(uniqueKeysWithValues: store.productivityCache.dailySummaries.map {
            (calendar.startOfDay(for: $0.date), $0)
        })
        let march10 = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)))
        let march11 = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 11)))

        #expect(summariesByDay[march10]?.completedFocusCount == 0)
        #expect(summariesByDay[march11]?.completedFocusCount == 1)
        #expect(store.productivityCache.completedFocusCount == 1)
    }

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "VibePomodoroTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func clear(_ defaults: UserDefaults, suiteName: String) {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func saveValue<T: Encodable>(_ value: T?, for key: String, defaults: UserDefaults) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }

        let encoder = JSONEncoder()
        defaults.set(try? encoder.encode(value), forKey: key)
    }

    private func makeCompletedSession(
        settings: PomodoroSettings,
        createdAt: Date,
        completedAt: Date,
        segments: [ActivitySegment]
    ) -> CompletedSession {
        CompletedSession(
            id: UUID(),
            createdAt: createdAt,
            completedAt: completedAt,
            settingsSnapshot: settings,
            segments: segments
        )
    }

    private func makeSegment(
        phase: SessionPhase,
        roundNumber: Int,
        startDate: Date,
        endDate: Date
    ) -> ActivitySegment {
        ActivitySegment(
            id: UUID(),
            stepID: UUID(),
            phase: phase,
            roundNumber: roundNumber,
            startDate: startDate,
            endDate: endDate
        )
    }

}
