import Combine
import Foundation
import SwiftUI

@MainActor
final class PomodoroStore: ObservableObject {
    static let openProductivityArgument = "--open-productivity"

    @Published var selectedTab: AppTab = .focus
    @Published var settings: PomodoroSettings
    @Published var activeSession: SessionSnapshot?
    @Published var completedSessions: [CompletedSession]
    @Published var productivityCache: ProductivityAggregateCache

    let defaults: UserDefaults
    let encoder = JSONEncoder()
    var stepBoundaryTimer: Timer?
    var currentScenePhase: ScenePhase = .active

    enum StorageKey {
        static let settings = "vibe.settings"
        static let activeSession = "vibe.activeSession"
        static let completedSessions = "vibe.completedSessions"
        static let productivityCache = "vibe.productivityCache"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = Self.loadValue(for: StorageKey.settings, using: defaults) ?? .default
        self.activeSession = Self.loadValue(for: StorageKey.activeSession, using: defaults)
        self.completedSessions = Self.loadValue(for: StorageKey.completedSessions, using: defaults) ?? []
        self.productivityCache = Self.loadValue(for: StorageKey.productivityCache, using: defaults) ?? .empty
        self.selectedTab = Self.initialSelectedTab()

        reconcileNow()
        repairProductivityCacheIfNeeded()
        syncIdleTimer()
        requestNotificationPermissionsIfNeeded()
        syncNotifications()
        syncStepBoundaryTimer()
    }

    deinit {
        stepBoundaryTimer?.invalidate()
    }

    private static func initialSelectedTab() -> AppTab {
        if ProcessInfo.processInfo.arguments.contains(openProductivityArgument) {
            return .productivity
        }

        return .focus
    }

    var currentPhase: SessionPhase {
        activeSession?.currentPhase ?? .focus
    }

    var currentRunState: SessionRunState {
        activeSession?.runState ?? .idle
    }

    var hasActiveSession: Bool {
        activeSession != nil
    }

    var canGoBack: Bool {
        guard let session = activeSession else { return false }
        return session.currentStepIndex > 0 || session.hasElapsedTime(now: .now)
    }

    var shouldShowBackAction: Bool {
        guard let session = activeSession else { return false }

        switch session.runState {
        case .idle:
            return session.hasElapsedTime(now: .now)
        case .running, .paused, .completed:
            return true
        }
    }

    var canSkip: Bool {
        activeSession?.currentStep != nil
    }

    var canResetCurrentStep: Bool {
        guard let session = activeSession,
              session.runState != .completed,
              let step = session.currentStep else { return false }

        return session.runState == .running
            || session.runState == .paused
            || session.accumulatedDuration(for: step) > 0
    }

    var primaryActionTitle: String {
        guard let session = activeSession else { return "Start" }

        switch session.runState {
        case .idle:
            return "Start"
        case .running:
            return "Pause"
        case .paused:
            return "Resume"
        case .completed:
            return "Start Again"
        }
    }

    var currentStepTitle: String {
        activeSession?.currentPhase?.detailTitle ?? SessionPhase.focus.detailTitle
    }

    var progressLabel: String {
        guard let session = activeSession, let step = session.currentStep else {
            return "Round 1 of \(settings.targetRounds)"
        }

        return "Round \(step.roundNumber) of \(session.targetRounds)"
    }

    var statusText: String {
        guard let session = activeSession else { return "READY" }
        guard session.runState != .completed else { return "COMPLETE" }

        switch session.currentPhase ?? .focus {
        case .focus:
            return "FOCUS"
        case .shortBreak:
            return "SHORT BREAK"
        case .longBreak:
            return "LONG BREAK"
        }
    }

    func remainingDuration(now: Date = .now) -> TimeInterval {
        activeSession?.remainingDuration(now: now) ?? settings.focusDuration
    }

    func elapsedRatio(now: Date = .now) -> Double {
        guard let session = activeSession, let step = session.currentStep else { return 0 }
        guard step.plannedDuration > 0 else { return 0 }
        return min(1, max(0, session.elapsedDuration(now: now) / step.plannedDuration))
    }

    func currentStatistics(now: Date = .now) -> SessionStatistics {
        activeSession?.statistics(now: now) ?? SessionStatistics(
            focusTime: 0,
            shortBreakTime: 0,
            longBreakTime: 0,
            completedFocusCount: 0
        )
    }

    func togglePrimaryAction() {
        if activeSession == nil || activeSession?.runState == .completed {
            startNewSession()
            return
        }

        guard var session = activeSession else { return }

        switch session.runState {
        case .idle, .paused:
            let events = PomodoroEngine.startOrResume(session: &session, now: .now)
            activeSession = session
            handle(events: events)
        case .running:
            PomodoroEngine.pause(session: &session, now: .now)
            activeSession = session
            refreshRuntimeSideEffects()
        case .completed:
            startNewSession()
        }
    }

    func skipCurrentStep() {
        guard var session = activeSession else { return }
        let events = PomodoroEngine.skip(session: &session, now: .now)
        activeSession = session
        handle(events: events)
    }

    func resetCurrentStep() {
        guard var session = activeSession else { return }
        let events = PomodoroEngine.resetCurrentStep(session: &session, now: .now)
        activeSession = session
        handle(events: events)
    }

    func goBackOneStep() {
        guard var session = activeSession else { return }
        let events = PomodoroEngine.goBack(session: &session, now: .now)
        activeSession = session
        handle(events: events)
    }

    func finishSessionEarly() {
        guard var session = activeSession, session.runState != .completed else { return }
        let events = PomodoroEngine.finishSessionEarly(session: &session, now: .now)
        activeSession = session
        handle(events: events)
    }

    func dismissCompletedSession() {
        guard activeSession?.runState == .completed else { return }
        activeSession = nil
        refreshRuntimeSideEffects()
    }
}
