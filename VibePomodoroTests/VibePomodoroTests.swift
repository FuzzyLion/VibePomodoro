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

}
