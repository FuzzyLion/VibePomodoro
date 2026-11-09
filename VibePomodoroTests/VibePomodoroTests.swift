//
//  VibePomodoroTests.swift
//  VibePomodoroTests
//
//  Created by Qi Wu on 15.03.26.
//

import Foundation
import SwiftUI
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
        let events = PomodoroEngine.skip(session: &session, now: skipTime)

        let stats = session.statistics(now: skipTime)

        #expect(session.currentPhase == SessionPhase.shortBreak)
        #expect(session.runState == SessionRunState.running)
        #expect(events == [
            .phaseSkipped(.focus, 1),
            .phaseStarted(.shortBreak, 1)
        ])
        #expect(stats.focusTime == 5 * 60)
        #expect(stats.completedFocusCount == 0)
    }

    @Test func focusRoundCompletionSeparatesFinishedAndSkippedBlocks() async throws {
        var settings = PomodoroSettings.default
        settings.targetRounds = 2

        let start = Date(timeIntervalSince1970: 3_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)

        // Round 1 runs its full duration; round 2 is skipped after five minutes.
        let firstBreakStart = start.addingTimeInterval(settings.focusDuration)
        _ = PomodoroEngine.reconcile(session: &session, now: firstBreakStart)
        let secondFocusStart = firstBreakStart.addingTimeInterval(60)
        _ = PomodoroEngine.skip(session: &session, now: secondFocusStart)
        let secondFocusSkip = secondFocusStart.addingTimeInterval(5 * 60)
        _ = PomodoroEngine.skip(session: &session, now: secondFocusSkip)

        #expect(session.currentPhase == .longBreak)
        #expect(session.isFocusRoundCompleted(1))
        #expect(!session.isFocusRoundCompleted(2))
        #expect(session.statistics(now: secondFocusSkip).completedFocusCount == 1)
    }

    @Test func skipFinalRunningStepEmitsPhaseSkippedBeforeSessionComplete() async throws {
        var settings = PomodoroSettings.default
        settings.targetRounds = 1

        let start = Date(timeIntervalSince1970: 2_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)
        _ = PomodoroEngine.reconcile(session: &session, now: start.addingTimeInterval(settings.focusDuration))

        let events = PomodoroEngine.skip(session: &session, now: start.addingTimeInterval(settings.focusDuration + 60))

        #expect(session.runState == .completed)
        #expect(events == [
            .phaseSkipped(.longBreak, 1),
            .sessionCompleted
        ])
    }

    @Test func backRollsBackPreviousStepStatistics() async throws {
        var settings = PomodoroSettings.default
        settings.targetRounds = 2

        let start = Date(timeIntervalSince1970: 10_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)

        let breakStart = start.addingTimeInterval(settings.focusDuration)
        _ = PomodoroEngine.reconcile(session: &session, now: breakStart)
        let events = PomodoroEngine.goBack(session: &session, now: breakStart.addingTimeInterval(60))

        let stats = session.statistics(now: breakStart.addingTimeInterval(60))

        #expect(session.currentPhase == SessionPhase.focus)
        #expect(events == [
            .phaseRewound(.focus, 1),
            .phaseStarted(.focus, 1)
        ])
        #expect(stats.focusTime == 0)
        #expect(stats.breakTime == 0)
        #expect(stats.completedFocusCount == 0)
    }

    @Test func resetCurrentRunningStepEmitsPhaseResetBeforePhaseStarted() async throws {
        var settings = PomodoroSettings.default
        settings.targetRounds = 1

        let start = Date(timeIntervalSince1970: 11_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)

        let events = PomodoroEngine.resetCurrentStep(session: &session, now: start.addingTimeInterval(60))

        #expect(session.currentPhase == .focus)
        #expect(session.runState == .running)
        #expect(events == [
            .phaseReset(.focus, 1),
            .phaseStarted(.focus, 1)
        ])
    }

    @Test func firstStepGoBackEmitsPhaseResetWhenReturningToCurrentStepStart() async throws {
        var settings = PomodoroSettings.default
        settings.targetRounds = 1

        let start = Date(timeIntervalSince1970: 12_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)

        let events = PomodoroEngine.goBack(session: &session, now: start.addingTimeInterval(60))

        #expect(session.currentPhase == .focus)
        #expect(session.runState == .running)
        #expect(events == [
            .phaseReset(.focus, 1),
            .phaseStarted(.focus, 1)
        ])
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
        let pointForToday = try #require(points.first(where: { calendar.startOfDay(for: $0.startDate) == todayStart }))

        #expect(points.count == 30)
        #expect(points.reduce(0) { $0 + $1.focusTime } == 90 * 60)
        #expect(points.reduce(0) { $0 + $1.breakTime } == 15 * 60)
        #expect(abs(pointForToday.focusTime - 90 * 60) < 0.0001)
        #expect(abs(pointForToday.breakTime - 15 * 60) < 0.0001)
        #expect(pointForToday.completedFocusCount == 1)
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
        var maySettings = PomodoroSettings.default
        maySettings.focusMinutes = 20
        let maySession = makeCompletedSession(
            settings: maySettings,
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
        let aprilPoint = try #require(pointsByMonth[4])
        let mayPoint = try #require(pointsByMonth[5])

        #expect(points.reduce(0) { $0 + $1.focusTime } == 70 * 60)
        #expect(points.reduce(0) { $0 + $1.breakTime } == 15 * 60)
        #expect(points.reduce(0) { $0 + $1.completedFocusCount } == 3)
        #expect(abs(aprilPoint.focusTime - 50 * 60) < 0.0001)
        #expect(abs(aprilPoint.breakTime - 5 * 60) < 0.0001)
        #expect(aprilPoint.completedFocusCount == 2)
        #expect(abs(mayPoint.focusTime - 20 * 60) < 0.0001)
        #expect(abs(mayPoint.breakTime - 10 * 60) < 0.0001)
        #expect(mayPoint.completedFocusCount == 1)
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
        let pointForMarch18 = try #require(points.first(where: { calendar.startOfDay(for: $0.startDate) == march18 }))

        #expect(points.count == 7)
        #expect(points.reduce(0) { $0 + $1.focusTime } == 25 * 60)
        #expect(points.reduce(0) { $0 + $1.breakTime } == 5 * 60)
        #expect(points.reduce(0) { $0 + $1.completedFocusCount } == 1)
        #expect(abs(pointForMarch18.sessionTime - 30 * 60) < 0.0001)
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

    @Test func clearProductivityHistoryRemovesPersistedHistoryButKeepsActiveSessionAndSettings() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.focusMinutes = 45
        settings.keepScreenOn = false

        let start = Date(timeIntervalSince1970: 40_000)
        let completedSession = makeCompletedSession(
            settings: settings,
            createdAt: start.addingTimeInterval(-5_400),
            completedAt: start.addingTimeInterval(-1_800),
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: start.addingTimeInterval(-5_400),
                    endDate: start.addingTimeInterval(-2_700)
                ),
                makeSegment(
                    phase: .longBreak,
                    roundNumber: 1,
                    startDate: start.addingTimeInterval(-2_700),
                    endDate: start.addingTimeInterval(-1_800)
                )
            ]
        )

        var activeSession = SessionSnapshot.makeNew(settings: settings, now: start)
        let currentStep = try #require(activeSession.currentStep)
        activeSession.runState = .paused
        activeSession.segments = [
            ActivitySegment(
                id: UUID(),
                stepID: currentStep.id,
                phase: .focus,
                roundNumber: currentStep.roundNumber,
                startDate: start,
                endDate: start.addingTimeInterval(600)
            )
        ]

        saveValue(settings, for: PomodoroStore.StorageKey.settings, defaults: defaults)
        saveValue(activeSession, for: TestStorageKey.activeSession, defaults: defaults)
        saveValue([completedSession], for: TestStorageKey.completedSessions, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)
        let preservedSettings = store.settings
        let preservedActiveSession = try #require(store.activeSession)

        #expect(store.completedSessions.count == 1)
        #expect(store.productivityCache.completedSessionCount == 1)

        store.clearProductivityHistory()

        #expect(store.completedSessions.isEmpty)
        #expect(store.productivityCache == .empty)
        #expect(store.settings == preservedSettings)
        #expect(store.activeSession == preservedActiveSession)

        let reloadedStore = PomodoroStore(defaults: defaults)
        #expect(reloadedStore.completedSessions.isEmpty)
        #expect(reloadedStore.productivityCache == .empty)
        #expect(reloadedStore.settings == preservedSettings)
        #expect(reloadedStore.activeSession == preservedActiveSession)
    }

    @Test func settingsPersistenceDoesNotRewriteProductivityDomains() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        let start = Date(timeIntervalSince1970: 45_000)
        let completedSession = makeCompletedSession(
            settings: .default,
            createdAt: start,
            completedAt: start.addingTimeInterval(1_500),
            segments: [
                makeSegment(
                    phase: .focus,
                    roundNumber: 1,
                    startDate: start,
                    endDate: start.addingTimeInterval(1_500)
                )
            ]
        )
        saveValue([completedSession], for: TestStorageKey.completedSessions, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)
        #expect(store.completedSessions.map(\.id) == [completedSession.id])

        store.completedSessions = []
        store.productivityCache = .empty
        store.updateFocusMinutes(30)

        let reloadedStore = PomodoroStore(defaults: defaults)
        #expect(reloadedStore.settings.focusMinutes == 30)
        #expect(reloadedStore.completedSessions.map(\.id) == [completedSession.id])
        #expect(reloadedStore.productivityCache.completedSessionCount == 1)
    }

    @Test func focusDurationNormalizationRemovesQaMinuteOptionForRelease() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.focusMinutes = 1
        saveValue(settings, for: PomodoroStore.StorageKey.settings, defaults: defaults)

        let store = PomodoroStore(defaults: defaults)
        store.normalizeSettingsIfNeeded()

        #expect(SettingsTimerField.focus.allowedValues.first == 15)
        #expect(SettingsTimerField.focus.allowedValues.contains(1) == false)
        #expect(store.settings.focusMinutes == 15)
    }

    @Test func bubbleRenderingPolicyKeepsLowPowerAnimationAtTwelveHertz() async throws {
        let normalPolicy = BubbleRenderingPolicy(
            isAnimating: true,
            reduceMotion: false,
            lowPowerModeEnabled: false
        )
        let lowPowerPolicy = BubbleRenderingPolicy(
            isAnimating: true,
            reduceMotion: false,
            lowPowerModeEnabled: true
        )
        let reduceMotionPolicy = BubbleRenderingPolicy(
            isAnimating: true,
            reduceMotion: true,
            lowPowerModeEnabled: false
        )

        #expect(BubbleRenderState.visibleAnimationRefreshInterval == 1.0 / 12.0)
        #expect(normalPolicy.animatesSurface)
        #expect(normalPolicy.rendersCaustic)
        #expect(lowPowerPolicy.animatesSurface)
        #expect(!lowPowerPolicy.rendersCaustic)
        #expect(!reduceMotionPolicy.animatesSurface)
    }

    @Test func finishedSessionSummaryCountsBlocksBreaksAndFocusShare() async throws {
        var settings = PomodoroSettings.default
        settings.focusMinutes = 25
        settings.shortBreakMinutes = 5
        settings.longBreakMinutes = 15
        settings.targetRounds = 3

        let start = Date(timeIntervalSince1970: 40_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)

        // The first focus block and its break, then ten minutes into the second block.
        let finish = start.addingTimeInterval((25 + 5 + 10) * 60)
        _ = PomodoroEngine.reconcile(session: &session, now: finish)
        #expect(FocusRenderState.nodeStates(for: session, fallbackRounds: 3) == [.filled, .half, .inactive])

        // Finishing early stops the second block, so its marker shows it as unfinished.
        _ = PomodoroEngine.finishSessionEarly(session: &session, now: finish)
        #expect(FocusRenderState.nodeStates(for: session, fallbackRounds: 3) == [.filled, .skipped, .inactive])

        let statistics = session.statistics(now: finish)
        let summary = BubbleSessionSummary(session: session, statistics: statistics)
        #expect(abs(summary.focusTime - 35 * 60) < 1)
        #expect(abs(summary.focusShare - 35.0 / 75.0) < 0.001)
        #expect(FocusRenderState.summaryCaption(for: statistics, targetRounds: 3) == "1 of 3 focus blocks · 5m break")

        let single = SessionStatistics(focusTime: 25 * 60, shortBreakTime: 0, longBreakTime: 0, completedFocusCount: 1)
        #expect(FocusRenderState.summaryCaption(for: single, targetRounds: 1) == "1 of 1 focus block")
    }

    @Test func finishedSessionVesselRestsBelowTheRimWithACalmSurface() async throws {
        func summaryState(focusShare: Double) -> BubbleRenderState {
            BubbleRenderState(
                phase: .longBreak,
                targetEndDate: nil,
                remainingDuration: 0,
                progress: 0,
                plannedDuration: 15 * 60,
                isAnimating: false,
                shouldTickSeconds: false,
                summary: BubbleSessionSummary(focusTime: 100 * 60 * focusShare, focusShare: focusShare)
            )
        }

        let full = BubbleLiquidVisualState(renderState: summaryState(focusShare: 1), at: .now)
        #expect(abs(full.fillRatio - BubbleLiquidVisualState.fullRestingFillRatio) < 0.0001)
        #expect(full.surfaceCalm == 1)
        #expect(full.stepBoundaryCueProgress == 0)

        let empty = BubbleLiquidVisualState(renderState: summaryState(focusShare: 0), at: .now)
        #expect(abs(empty.fillRatio - 0.12) < 0.0001)

        let half = BubbleLiquidVisualState(renderState: summaryState(focusShare: 0.5), at: .now)
        #expect(half.fillRatio > 0.12 && half.fillRatio < full.fillRatio)

        // The last step's final second overfills the vessel; the summary never does.
        let ending = BubbleRenderState(
            phase: .longBreak,
            targetEndDate: nil,
            remainingDuration: 0,
            progress: 0,
            plannedDuration: 15 * 60,
            isAnimating: false,
            shouldTickSeconds: false,
            summary: nil
        )
        #expect(BubbleLiquidVisualState(renderState: ending, at: .now).fillRatio > 1)
        #expect(full.fillRatio < 0.9)
    }

    @Test func completionDurationsSplitIntoNumbersAndUnits() async throws {
        let parts = FocusCompletionFormatting.durationParts(100 * 60)
        #expect(parts == [
            FocusCompletionFormatting.DurationPart(value: "1", unit: "h"),
            FocusCompletionFormatting.DurationPart(value: "40", unit: "m")
        ])
        #expect(FocusCompletionFormatting.durationText(100 * 60) == "1h 40m")
        #expect(FocusCompletionFormatting.durationText(2 * 3_600) == "2h")
        #expect(FocusCompletionFormatting.durationText(25 * 60) == "25m")
        #expect(FocusCompletionFormatting.durationText(45) == "45s")
    }

    @Test func vesselCrossSectionAndSurfaceFollowTheWaterLine() async throws {
        let rect = CGRect(x: 0, y: 0, width: 280, height: 280)
        let outline = BubbleVessel.polygon(of: Path(ellipseIn: rect.insetBy(dx: 40, dy: 40)))

        // A circle of radius 100 centered in the frame is 200 wide at its middle.
        let middle = try #require(BubbleVessel.horizontalExtent(of: outline, atY: 140))
        #expect(abs(middle.lowerBound - 40) < 1)
        #expect(abs(middle.upperBound - 240) < 1)
        #expect(BubbleVessel.horizontalExtent(of: outline, atY: 20) == nil)

        // Half full: the surface spans the vessel around the middle; full or empty: no surface.
        let surface = try #require(BubbleVessel.surface(in: rect, innerOutline: outline, fillRatio: 0.5))
        #expect(abs(surface.waterlineY - 140) < 1)
        #expect(abs(surface.centerX - 140) < 1)
        #expect(surface.radius * 2 > 195)
        #expect(surface.depth > 0 && surface.depth <= 12)
        #expect(BubbleVessel.surface(in: rect, innerOutline: outline, fillRatio: 1.08) == nil)
        #expect(BubbleVessel.surface(in: rect, innerOutline: outline, fillRatio: 0) == nil)

        // The shader's cross-sections span the inside of the glass: rows from its top to its
        // bottom, then columns from its left to its right.
        let sections = BubbleVessel.crossSections(of: outline, count: 5)
        #expect(abs(sections.bounds.minY - 40) < 1 && abs(sections.bounds.maxY - 240) < 1)
        #expect(abs(sections.bounds.minX - 40) < 1 && abs(sections.bounds.maxX - 240) < 1)
        #expect(sections.values.count == 20)
        // The middle row and the middle column cross the circle at its widest.
        #expect(abs(Double(sections.values[4]) - 40) < 1 && abs(Double(sections.values[5]) - 240) < 1)
        #expect(abs(Double(sections.values[14]) - 40) < 1 && abs(Double(sections.values[15]) - 240) < 1)
        // The first row sits just inside the top of the circle, around its middle.
        #expect(abs(Double(sections.values[0] + sections.values[1]) / 2 - 140) < 1)
        #expect(sections.values[1] - sections.values[0] < 30)
    }

    @Test func appearanceModeDefaultsToSystemAndPersistsUpdates() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        let store = PomodoroStore(defaults: defaults)

        #expect(store.settings.appearanceMode == .system)

        store.setAppearanceMode(.dark)
        #expect(store.settings.appearanceMode == .dark)

        let reloadedStore = PomodoroStore(defaults: defaults)
        #expect(reloadedStore.settings.appearanceMode == .dark)
    }

    @Test func legacySettingsDecodeWithSystemAppearanceMode() async throws {
        let legacySettingsJSON = Data("""
        {
            "focusMinutes": 45,
            "shortBreakMinutes": 10,
            "longBreakMinutes": 20,
            "targetRounds": 3,
            "keepScreenOn": false,
            "notificationsEnabled": true,
            "soundEnabled": false,
            "hapticsEnabled": true
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(PomodoroSettings.self, from: legacySettingsJSON)

        #expect(decoded.focusMinutes == 45)
        #expect(decoded.shortBreakMinutes == 10)
        #expect(decoded.longBreakMinutes == 20)
        #expect(decoded.targetRounds == 3)
        #expect(decoded.keepScreenOn == false)
        #expect(decoded.soundEnabled == false)
        #expect(decoded.appearanceMode == .system)
    }

    @Test func productivityEmptyCacheProducesZeroBucketsForAllRanges() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        let store = PomodoroStore(defaults: defaults)
        let now = try #require(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12)))

        let week = store.chartPoints(for: .week, now: now)
        let month = store.chartPoints(for: .month, now: now)
        let year = store.chartPoints(for: .year, now: now)

        #expect(week.count == 7)
        #expect(month.count == 30)
        #expect(year.count == 12)
        #expect((week + month + year).allSatisfy { point in
            point.focusTime == 0
                && point.breakTime == 0
                && point.completedFocusCount == 0
        })
    }

    @Test func productivityEmptySummaryFormattingUsesZeroStateText() async throws {
        #expect(ProductivityValueFormatting.summarySessionTimeText(0) == "0m")
        #expect(ProductivityValueFormatting.summaryAverageFocusText(0) == "0m")
        #expect(ProductivityValueFormatting.summaryStreakText(0) == "0d")
        #expect(ProductivityValueFormatting.summaryMetaText(completedSessionCount: 0, completedFocusCount: 0) == "No finished sessions yet")
    }

    @Test func productivityMonthDisplayBucketsKeepOneSlotPerDay() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 2, day: 20)))
        let points = (0..<30).map { offset in
            ProductivityChartPoint(
                startDate: calendar.date(byAdding: .day, value: offset, to: start)!,
                label: "",
                focusTime: Double(offset + 1) * 60,
                breakTime: Double(offset % 2) * 60,
                completedFocusCount: offset.isMultiple(of: 3) ? 1 : 0
            )
        }
        let buckets = ProductivityChartDisplay.displayBuckets(from: points, range: .month)
        let expectedLastDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 21)))

        #expect(buckets.count == 30)
        #expect(buckets.map(\.focusTime) == points.map(\.focusTime))
        #expect(buckets.map(\.breakTime) == points.map(\.breakTime))
        #expect(buckets.map(\.completedFocusCount) == points.map(\.completedFocusCount))
        #expect(buckets.first?.labelDate == points.first?.startDate)
        #expect(buckets.last?.labelDate == expectedLastDay)
    }

    @Test func productivityLongMonthDisplayBucketsPreserveDenseThirtyDayTotals() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let points = (0..<30).map { offset in
            ProductivityChartPoint(
                startDate: calendar.date(byAdding: .day, value: offset, to: start)!,
                label: "",
                focusTime: Double(12 + offset) * 60,
                breakTime: Double((offset % 5) + 1) * 60,
                completedFocusCount: offset.isMultiple(of: 2) ? 2 : 1
            )
        }

        let buckets = ProductivityChartDisplay.displayBuckets(from: points, range: .month)

        #expect(buckets.count == 30)
        #expect(buckets.map(\.slotIndex) == Array(0..<30))
        #expect(buckets.reduce(0) { $0 + $1.focusTime } == points.reduce(0) { $0 + $1.focusTime })
        #expect(buckets.reduce(0) { $0 + $1.breakTime } == points.reduce(0) { $0 + $1.breakTime })
        #expect(buckets.reduce(0) { $0 + $1.completedFocusCount } == points.reduce(0) { $0 + $1.completedFocusCount })
    }

    @Test func productivityYearDisplayBucketsPreserveTwelveMonthTotals() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let start = try #require(calendar.date(from: DateComponents(year: 2025, month: 6, day: 1)))
        let points = (0..<12).map { offset in
            ProductivityChartPoint(
                startDate: calendar.date(byAdding: .month, value: offset, to: start)!,
                label: "",
                focusTime: Double(offset + 1) * 3_600,
                breakTime: Double(offset + 2) * 1_200,
                completedFocusCount: offset + 1
            )
        }

        let buckets = ProductivityChartDisplay.displayBuckets(from: points, range: .year)

        #expect(buckets.count == 12)
        #expect(buckets.map(\.slotIndex) == Array(0..<12))
        #expect(buckets.reduce(0) { $0 + $1.focusTime } == points.reduce(0) { $0 + $1.focusTime })
        #expect(buckets.reduce(0) { $0 + $1.breakTime } == points.reduce(0) { $0 + $1.breakTime })
        #expect(buckets.reduce(0) { $0 + $1.completedFocusCount } == points.reduce(0) { $0 + $1.completedFocusCount })
    }

    @Test func productivityMonthAxisLabelsEveryWeekBackFromToday() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 2, day: 20)))
        let points = (0..<30).map { offset in
            ProductivityChartPoint(
                startDate: calendar.date(byAdding: .day, value: offset, to: start)!,
                label: "",
                focusTime: 0,
                breakTime: 0,
                completedFocusCount: 0
            )
        }
        let buckets = ProductivityChartDisplay.displayBuckets(from: points, range: .month)
        let labels = buckets.enumerated()
            .filter { ProductivityRange.month.showsAxisLabel(atSlot: $0.offset, slotCount: buckets.count) }
            .map { ProductivityChartFormatting.xAxisLabel(for: $0.element.labelDate, range: .month) }

        #expect(labels == ["21 Feb", "28 Feb", "7 Mar", "14 Mar", "21 Mar"])
        #expect((0..<7).allSatisfy { ProductivityRange.week.showsAxisLabel(atSlot: $0, slotCount: 7) })
        #expect((0..<12).allSatisfy { ProductivityRange.year.showsAxisLabel(atSlot: $0, slotCount: 12) })
    }

    @Test func productivityYearAxisUsesSingleLetterEnglishMonths() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let january = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))
        let september = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))
        let november = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))

        let buckets = [
            ProductivityDisplayBucket(
                slotIndex: 0,
                startDate: january,
                endDate: calendar.date(byAdding: .month, value: 1, to: january)!,
                xDate: january.addingTimeInterval(15 * 24 * 3600),
                labelDate: january,
                focusTime: 0,
                breakTime: 0,
                completedFocusCount: 0
            ),
            ProductivityDisplayBucket(
                slotIndex: 1,
                startDate: september,
                endDate: calendar.date(byAdding: .month, value: 1, to: september)!,
                xDate: september.addingTimeInterval(15 * 24 * 3600),
                labelDate: september,
                focusTime: 0,
                breakTime: 0,
                completedFocusCount: 0
            ),
            ProductivityDisplayBucket(
                slotIndex: 2,
                startDate: november,
                endDate: calendar.date(byAdding: .month, value: 1, to: november)!,
                xDate: november.addingTimeInterval(15 * 24 * 3600),
                labelDate: november,
                focusTime: 0,
                breakTime: 0,
                completedFocusCount: 0
            )
        ]

        #expect(ProductivityChartFormatting.xAxisLabel(for: buckets[0].labelDate, range: .year) == "J")
        #expect(ProductivityChartFormatting.xAxisLabel(for: buckets[1].labelDate, range: .year) == "S")
        #expect(ProductivityChartFormatting.xAxisLabel(for: buckets[2].labelDate, range: .year) == "N")
    }

    @Test func productivityFormattingHandlesExtremeDurations() async throws {
        #expect(ProductivityValueFormatting.compactDurationText(-42) == "0m")
        #expect(ProductivityValueFormatting.compactDurationText(42) == "42s")
        #expect(ProductivityValueFormatting.compactDurationText((27 * 3_600) + (14 * 60)) == "27h 14m")
        #expect(ProductivityValueFormatting.summarySessionTimeText(27 * 3_600 + 14 * 60) == "27h 14m")
        #expect(ProductivityValueFormatting.summarySessionTimeText(99 * 3_600 + 59 * 60) == "99h 59m")
        #expect(ProductivityValueFormatting.summarySessionTimeText(460 * 3_600 + 12 * 60) == "460h")
        #expect(ProductivityValueFormatting.summarySessionTimeText(100 * 24 * 3_600 + 23 * 3_600) == "2423h")
        #expect(ProductivityValueFormatting.summarySessionTimeAccessibilityValue(460 * 3_600 + 12 * 60) == "460 hours")
        #expect(ProductivityValueFormatting.summarySessionTimeAccessibilityValue(3_600 + 60) == "1 hour 1 minute")
        #expect(ProductivityValueFormatting.summaryAverageFocusText(12.5) == "12h 30m")
        #expect(ProductivityValueFormatting.summaryStreakText(-8) == "0d")
        #expect(ProductivityValueFormatting.summaryMetaText(completedSessionCount: 24_000, completedFocusCount: 123_456) == "24000 finished sessions • 123456 focus blocks")
    }

    @Test func productivityCountAxisHandlesZeroAndLargeCounts() async throws {
        let zero = ProductivityChartMetricKind.focusSessions.axisStyle(for: [])
        let low = ProductivityChartMetricKind.focusSessions.axisStyle(for: [
            makeDisplayBucket(completedFocusCount: 4)
        ])
        let medium = ProductivityChartMetricKind.focusSessions.axisStyle(for: [
            makeDisplayBucket(completedFocusCount: 17)
        ])
        let high = ProductivityChartMetricKind.focusSessions.axisStyle(for: [
            makeDisplayBucket(completedFocusCount: 123)
        ])

        #expect(zero.step == 1)
        #expect(zero.upperBound == 4)
        #expect(low.step == 1)
        #expect(low.upperBound == 4)
        #expect(medium.step == 5)
        #expect(medium.upperBound == 20)
        #expect(high.step == 50)
        #expect(high.upperBound == 150)
    }

    @Test func productivityTimeAxisUsesRoundSteps() async throws {
        let underHour = ProductivityChartFormatting.timeAxisStyle(for: 59 * 60)
        let underTwoHours = ProductivityChartFormatting.timeAxisStyle(for: 90 * 60)
        let overTwoHours = ProductivityChartFormatting.timeAxisStyle(for: 2 * 3_600 + 10 * 60)
        let busyWeek = ProductivityChartFormatting.timeAxisStyle(for: 17 * 3_600 + 5 * 60)
        let busyMonth = ProductivityChartFormatting.timeAxisStyle(for: 66 * 3_600 + 35 * 60)

        #expect(underHour.step == 20 * 60)
        #expect(underHour.values == [0, 1_200, 2_400, 3_600])

        #expect(underTwoHours.step == 3_600)
        #expect(underTwoHours.values == [0, 3_600, 7_200])

        #expect(overTwoHours.step == 3_600)
        #expect(overTwoHours.values == [0, 3_600, 7_200, 10_800])

        #expect(busyWeek.step == 5 * 3_600)
        #expect(busyWeek.upperBound == 20 * 3_600)

        #expect(busyMonth.step == 20 * 3_600)
        #expect(busyMonth.upperBound == 80 * 3_600)
    }

    @Test func productivityTimeAxisHandlesLargeDurations() async throws {
        let zero = ProductivityChartFormatting.timeAxisStyle(for: 0)
        let dayPlus = ProductivityChartFormatting.timeAxisStyle(for: 27 * 3_600 + 17 * 60)

        #expect(zero.step == 1_200)
        #expect(zero.values == [0, 1_200, 2_400, 3_600])
        #expect(dayPlus.step == 10 * 3_600)
        #expect(dayPlus.upperBound == 30 * 3_600)
        #expect(dayPlus.values.last == 30.0 * 3_600)
    }

    @Test func productivityAxesStayReadableForAnyBucketSize() async throws {
        let durations = (0...220).map { 60 * pow(1.07, Double($0)) }
        let counts = (0...200).map { pow(1.06, Double($0)).rounded(.up) }

        for duration in durations {
            let style = ProductivityChartFormatting.timeAxisStyle(for: duration)
            let labels = style.values.map(ProductivityChartFormatting.axisDurationText)

            #expect(style.values.count <= 5, "\(duration)s gave \(style.values.count) ticks")
            #expect(style.upperBound >= duration)
            if duration > 3_600 {
                #expect(style.step.truncatingRemainder(dividingBy: 3_600) == 0)
                #expect(labels.allSatisfy { !$0.contains("m") }, "\(labels)")
            }
        }

        for count in counts {
            let style = ProductivityChartFormatting.countAxisStyle(for: count)

            #expect(style.values.count <= 5, "\(count) gave \(style.values.count) ticks")
            #expect(style.upperBound >= count)
            #expect(style.step == style.step.rounded())
        }
    }

    @Test func productivityChartLabelsStayShort() async throws {
        #expect(ProductivityChartMetricKind.focusTime.valueText(for: 2 * 3_600) == "2h")
        #expect(ProductivityChartMetricKind.breakTime.valueText(for: 3_600 + 5 * 60) == "1h 5m")
        #expect(ProductivityChartMetricKind.breakTime.valueText(for: 0) == "0m")
        #expect(ProductivityChartMetricKind.focusSessions.valueText(for: 12) == "12")
        #expect(ProductivityChartMetricKind.focusSessions.title == "Focus Blocks")
        #expect(ProductivityChartMetricKind.focusTime.axisLabelText(for: 0) == "0")
        #expect(ProductivityChartMetricKind.breakTime.axisLabelText(for: 40 * 60) == "40m")
        #expect(ProductivityChartMetricKind.focusTime.axisLabelText(for: 25 * 3_600) == "25h")
    }

    @Test func productivityBarsReadTheirValueForVoiceOver() async throws {
        #expect(ProductivityChartMetricKind.focusSessions.valueAccessibilityText(for: 1) == "1 focus block")
        #expect(ProductivityChartMetricKind.focusSessions.valueAccessibilityText(for: 12) == "12 focus blocks")
        #expect(ProductivityChartMetricKind.focusTime.valueAccessibilityText(for: 5 * 3_600) == "5 hours")
        #expect(ProductivityChartMetricKind.breakTime.valueAccessibilityText(for: 3_600 + 30 * 60) == "1 hour 30 minutes")
        #expect(ProductivityChartMetricKind.breakTime.valueAccessibilityText(for: 0) == "0 minutes")
    }

    @Test func productivityRangeCaptionNamesTheDatesCovered() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let weekStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 3)))
        let splitWeekStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 28)))
        let monthStart = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 11)))
        let yearStart = try #require(calendar.date(from: DateComponents(year: 2025, month: 12, day: 1)))

        let week = makeChartBuckets(from: weekStart, count: 7, component: .day, range: .week, calendar: calendar)
        let splitWeek = makeChartBuckets(from: splitWeekStart, count: 7, component: .day, range: .week, calendar: calendar)
        let month = makeChartBuckets(from: monthStart, count: 30, component: .day, range: .month, calendar: calendar)
        let year = makeChartBuckets(from: yearStart, count: 12, component: .month, range: .year, calendar: calendar)

        #expect(ProductivityRange.week.windowTitle == "Last 7 days")
        #expect(ProductivityChartFormatting.rangeDatesText(for: week, range: .week, calendar: calendar) == "3–9 Nov")
        #expect(ProductivityChartFormatting.rangeDatesText(for: splitWeek, range: .week, calendar: calendar) == "28 Oct – 3 Nov")
        #expect(ProductivityChartFormatting.rangeDatesText(for: month, range: .month, calendar: calendar) == "11 Oct – 9 Nov")
        #expect(ProductivityChartFormatting.rangeDatesText(for: year, range: .year, calendar: calendar) == "Dec 2025 – Nov 2026")
        #expect(ProductivityChartFormatting.rangeDatesText(for: [], range: .week, calendar: calendar) == "")
    }

    @Test func productivitySelectionNamesTheTappedDayOrMonth() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let friday = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 6)))
        let october = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let november = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let ninthNoon = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 12)))
        let firstMorning = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 9)))

        let day = try #require(makeChartBuckets(from: friday, count: 1, component: .day, range: .week, calendar: calendar).first)
        let months = makeChartBuckets(from: october, count: 2, component: .month, range: .year, calendar: calendar)
        let pastMonth = try #require(months.first)
        let currentMonth = try #require(months.last)

        #expect(currentMonth.startDate == november)
        #expect(ProductivityChartFormatting.selectionText(for: day, range: .week, now: ninthNoon, calendar: calendar) == "Fri 6 Nov")
        #expect(ProductivityChartFormatting.selectionText(for: day, range: .month, now: ninthNoon, calendar: calendar) == "Fri 6 Nov")
        #expect(ProductivityChartFormatting.selectionText(for: pastMonth, range: .year, now: ninthNoon, calendar: calendar) == "Oct 2026")
        #expect(ProductivityChartFormatting.selectionText(for: currentMonth, range: .year, now: ninthNoon, calendar: calendar) == "1–9 Nov")
        #expect(ProductivityChartFormatting.selectionText(for: currentMonth, range: .year, now: firstMorning, calendar: calendar) == "1 Nov")
        #expect(ProductivityChartFormatting.selectionAccessibilityText(for: day, range: .week, now: ninthNoon) == "Friday 6 November")
        #expect(ProductivityChartFormatting.selectionAccessibilityText(for: currentMonth, range: .year, now: ninthNoon) == "November 2026 so far")
    }

    @Test func productivityTapFindsTheSlotUnderTheFinger() async throws {
        #expect(ProductivityChartDisplay.slotIndex(atX: 0, plotWidth: 280, slotCount: 7) == 0)
        #expect(ProductivityChartDisplay.slotIndex(atX: 39.9, plotWidth: 280, slotCount: 7) == 0)
        #expect(ProductivityChartDisplay.slotIndex(atX: 40, plotWidth: 280, slotCount: 7) == 1)
        #expect(ProductivityChartDisplay.slotIndex(atX: 279.9, plotWidth: 280, slotCount: 7) == 6)
        #expect(ProductivityChartDisplay.slotIndex(atX: 280, plotWidth: 280, slotCount: 7) == nil)
        #expect(ProductivityChartDisplay.slotIndex(atX: -1, plotWidth: 280, slotCount: 7) == nil)
        #expect(ProductivityChartDisplay.slotIndex(atX: 140, plotWidth: 280, slotCount: 0) == nil)
        #expect(ProductivityChartDisplay.slotIndex(atX: 141, plotWidth: 285, slotCount: 30) == 14)
    }

    @Test func productivityXAxisLabelsAreStableAcrossRangesAndBoundaries() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let monday = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 16)))
        let monthBoundary = try #require(calendar.date(from: DateComponents(year: 2026, month: 2, day: 27)))
        let december = try #require(calendar.date(from: DateComponents(year: 2025, month: 12, day: 1)))
        let january = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))

        #expect(ProductivityChartFormatting.xAxisLabel(for: monday, range: .week) == "Mon")
        #expect(ProductivityChartFormatting.xAxisLabel(for: monthBoundary, range: .month) == "27 Feb")
        #expect(ProductivityChartFormatting.xAxisLabel(for: december, range: .year) == "D")
        #expect(ProductivityChartFormatting.xAxisLabel(for: january, range: .year) == "J")
    }

    @Test func intermediateNotificationsUseNextPhaseSound() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.focusMinutes = 25
        settings.shortBreakMinutes = 5
        settings.longBreakMinutes = 15
        settings.targetRounds = 2
        settings.soundEnabled = true

        let start = Date(timeIntervalSince1970: 50_000)
        let store = makeStoreWithRunningSession(settings: settings, start: start, defaults: defaults)
        let plans = store.notificationPlans(now: start)

        #expect(plans.count == 4)
        #expect(plans.first?.soundResource == .nextPhaseWhoosh)
        #expect(plans.first?.soundName == "next-phase-whoosh.caf")
        #expect(plans.dropLast().allSatisfy { $0.soundResource == .nextPhaseWhoosh })
    }

    @Test func finalNotificationUsesSessionCompleteSound() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.focusMinutes = 25
        settings.longBreakMinutes = 15
        settings.targetRounds = 1
        settings.soundEnabled = true

        let start = Date(timeIntervalSince1970: 60_000)
        let store = makeStoreWithRunningSession(settings: settings, start: start, defaults: defaults)
        let plans = store.notificationPlans(now: start)

        #expect(plans.count == 2)
        #expect(plans.last?.soundResource == .sessionCompleteThud)
        #expect(plans.last?.soundName == "session-complete-thud.caf")
    }

    @Test func notificationsOmitSoundWhenSoundIsDisabled() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.targetRounds = 1
        settings.soundEnabled = false

        let start = Date(timeIntervalSince1970: 70_000)
        let store = makeStoreWithRunningSession(settings: settings, start: start, defaults: defaults)
        let plans = store.notificationPlans(now: start)

        #expect(plans.isEmpty == false)
        #expect(plans.allSatisfy { $0.soundResource == nil })
        #expect(plans.allSatisfy { $0.soundName == nil })
    }

    @Test func foregroundBoundaryFeedbackUsesForwardWhooshOnly() async throws {
        let actions = ReminderFeedbackPlan.actions(
            for: [
                .phaseCompleted(.focus, 1),
                .phaseStarted(.shortBreak, 1)
            ],
            isForeground: true,
            soundEnabled: true,
            hapticsEnabled: true
        )

        #expect(actions == [
            .sound(.nextPhaseWhoosh),
            .haptic(.softImpact)
        ])
    }

    @Test func foregroundSessionCompleteFeedbackUsesOnlyThudAndSuccessHaptic() async throws {
        let actions = ReminderFeedbackPlan.actions(
            for: [
                .phaseCompleted(.longBreak, 1),
                .sessionCompleted
            ],
            isForeground: true,
            soundEnabled: true,
            hapticsEnabled: true
        )

        #expect(actions == [
            .sound(.sessionCompleteThud),
            .haptic(.success)
        ])
    }

    @Test func foregroundSkipBoundaryFeedbackUsesForwardWhooshOnly() async throws {
        let actions = ReminderFeedbackPlan.actions(
            for: [
                .phaseSkipped(.focus, 1),
                .phaseStarted(.shortBreak, 1)
            ],
            isForeground: true,
            soundEnabled: true,
            hapticsEnabled: true
        )

        #expect(actions == [
            .sound(.nextPhaseWhoosh),
            .haptic(.softImpact)
        ])
    }

    @Test func foregroundSkipSessionCompleteFeedbackUsesOnlyThudAndSuccessHaptic() async throws {
        let actions = ReminderFeedbackPlan.actions(
            for: [
                .phaseSkipped(.longBreak, 1),
                .sessionCompleted
            ],
            isForeground: true,
            soundEnabled: true,
            hapticsEnabled: true
        )

        #expect(actions == [
            .sound(.sessionCompleteThud),
            .haptic(.success)
        ])
    }

    @Test func foregroundPausedSkipFeedbackUsesForwardWhooshOnly() async throws {
        let actions = ReminderFeedbackPlan.actions(
            for: [
                .phaseSkipped(.focus, 1)
            ],
            isForeground: true,
            soundEnabled: true,
            hapticsEnabled: true
        )

        #expect(actions == [
            .sound(.nextPhaseWhoosh),
            .haptic(.softImpact)
        ])
    }

    @Test func foregroundBackFeedbackUsesPopAndRigidImpact() async throws {
        let actions = ReminderFeedbackPlan.actions(
            for: [
                .phaseRewound(.focus, 1),
                .phaseStarted(.focus, 1)
            ],
            isForeground: true,
            soundEnabled: true,
            hapticsEnabled: true
        )

        #expect(actions == [
            .sound(.phaseCompletePop),
            .haptic(.rigidImpact)
        ])
    }

    @Test func foregroundResetFeedbackUsesResetSoundAndSoftImpact() async throws {
        let actions = ReminderFeedbackPlan.actions(
            for: [
                .phaseReset(.focus, 1),
                .phaseStarted(.focus, 1)
            ],
            isForeground: true,
            soundEnabled: true,
            hapticsEnabled: true
        )

        #expect(actions == [
            .sound(.phaseResetNotification),
            .haptic(.softImpact)
        ])
    }

    @Test func manualStartFeedbackRemainsSilent() async throws {
        let actions = ReminderFeedbackPlan.actions(
            for: [
                .phaseStarted(.focus, 1)
            ],
            isForeground: true,
            soundEnabled: true,
            hapticsEnabled: true
        )

        #expect(actions.isEmpty)
    }

    @Test func skipCurrentStepPlaysForwardWhooshFeedback() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.targetRounds = 2

        let player = RecordingReminderFeedbackPlayer()
        let store = makeStoreWithRunningSession(
            settings: settings,
            start: Date(),
            defaults: defaults,
            feedbackPlayer: player
        )

        store.skipCurrentStep()

        #expect(player.playedActionBatches == [[
            .sound(.nextPhaseWhoosh),
            .haptic(.softImpact)
        ]])
    }

    @Test func skipFinalStepPlaysSessionCompleteFeedback() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.targetRounds = 1

        let start = Date(timeIntervalSince1970: 80_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)
        _ = PomodoroEngine.reconcile(session: &session, now: start.addingTimeInterval(settings.focusDuration))

        let player = RecordingReminderFeedbackPlayer()
        let store = PomodoroStore(defaults: defaults, feedbackPlayer: player)
        store.settings = settings
        store.activeSession = session

        store.skipCurrentStep()

        #expect(store.activeSession?.runState == .completed)
        #expect(player.playedActionBatches == [[
            .sound(.sessionCompleteThud),
            .haptic(.success)
        ]])
    }

    @Test func goBackOneStepPlaysPopFeedback() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.targetRounds = 2

        let start = Date(timeIntervalSince1970: 90_000)
        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)
        _ = PomodoroEngine.reconcile(session: &session, now: start.addingTimeInterval(settings.focusDuration))

        let player = RecordingReminderFeedbackPlayer()
        let store = PomodoroStore(defaults: defaults, feedbackPlayer: player)
        store.settings = settings
        store.activeSession = session

        store.goBackOneStep()

        #expect(player.playedActionBatches == [[
            .sound(.phaseCompletePop),
            .haptic(.rigidImpact)
        ]])
    }

    @Test func resetCurrentStepPlaysResetFeedback() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.targetRounds = 1

        let player = RecordingReminderFeedbackPlayer()
        let store = makeStoreWithRunningSession(
            settings: settings,
            start: Date(),
            defaults: defaults,
            feedbackPlayer: player
        )

        store.resetCurrentStep()

        #expect(player.playedActionBatches == [[
            .sound(.phaseResetNotification),
            .haptic(.softImpact)
        ]])
    }

    @Test func backgroundReconcileDoesNotReplayMissedForegroundFeedback() async throws {
        let (defaults, suiteName) = makeDefaults()
        defer { clear(defaults, suiteName: suiteName) }

        var settings = PomodoroSettings.default
        settings.focusMinutes = 15
        settings.longBreakMinutes = 15
        settings.targetRounds = 1

        let player = RecordingReminderFeedbackPlayer()
        let now = Date()
        let start = now.addingTimeInterval(-(settings.focusDuration + settings.longBreakDuration + 60))
        let store = makeStoreWithRunningSession(
            settings: settings,
            start: start,
            defaults: defaults,
            feedbackPlayer: player
        )

        store.currentScenePhase = .background
        store.handleScenePhaseChange(.active)

        #expect(store.activeSession?.runState == .completed)
        #expect(store.completedSessions.count == 1)
        #expect(player.playedActionBatches.isEmpty)
    }

    @Test func bundledReminderSoundResourcesExist() async throws {
        for resource in ReminderSoundResource.allCases {
            #expect(resource.bundleURL != nil)
        }
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

    private func makeChartBuckets(
        from start: Date,
        count: Int,
        component: Calendar.Component,
        range: ProductivityRange,
        calendar: Calendar
    ) -> [ProductivityDisplayBucket] {
        let points = (0..<count).map { offset in
            ProductivityChartPoint(
                startDate: calendar.date(byAdding: component, value: offset, to: start)!,
                label: "",
                focusTime: 0,
                breakTime: 0,
                completedFocusCount: 0
            )
        }
        return ProductivityChartDisplay.displayBuckets(from: points, range: range)
    }

    private func makeDisplayBucket(
        focusTime: TimeInterval = 0,
        breakTime: TimeInterval = 0,
        completedFocusCount: Int = 0
    ) -> ProductivityDisplayBucket {
        let start = Date(timeIntervalSince1970: 123_456)
        return ProductivityDisplayBucket(
            slotIndex: 0,
            startDate: start,
            endDate: start.addingTimeInterval(86_400),
            xDate: start.addingTimeInterval(43_200),
            labelDate: start,
            focusTime: focusTime,
            breakTime: breakTime,
            completedFocusCount: completedFocusCount
        )
    }

    private func makeStoreWithRunningSession(
        settings: PomodoroSettings,
        start: Date,
        defaults: UserDefaults,
        feedbackPlayer: ReminderFeedbackPlaying? = nil
    ) -> PomodoroStore {
        let store = PomodoroStore(defaults: defaults, feedbackPlayer: feedbackPlayer ?? RecordingReminderFeedbackPlayer())
        store.settings = settings

        var session = SessionSnapshot.makeNew(settings: settings, now: start)
        _ = PomodoroEngine.startOrResume(session: &session, now: start)
        store.activeSession = session

        return store
    }

    private final class RecordingReminderFeedbackPlayer: ReminderFeedbackPlaying {
        var playedActionBatches: [[ReminderFeedbackAction]] = []

        func play(_ actions: [ReminderFeedbackAction]) {
            playedActionBatches.append(actions)
        }
    }

}
