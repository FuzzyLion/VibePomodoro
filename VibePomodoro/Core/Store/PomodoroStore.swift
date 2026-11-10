import Combine
import Foundation
import SwiftUI

@MainActor
final class PomodoroStore: ObservableObject {
    static let openProductivityArgument = "--open-productivity"
    static let openSettingsArgument = "--open-settings"
    static let resetStorageArgument = "--reset-vibe-store"
    static let uiTestingArgument = "--ui-testing"
    static let appearanceLightArgument = "--appearance-light"
    static let appearanceDarkArgument = "--appearance-dark"
    static let appearanceSystemArgument = "--appearance-system"
    static let defaultsSuiteNameEnvironmentKey = "VIBE_DEFAULTS_SUITE"
    static let productivityFixtureEnvironmentKey = "VIBE_PRODUCTIVITY_FIXTURE"
    static let focusFixtureEnvironmentKey = "VIBE_FOCUS_FIXTURE"
    static let notificationPermissionFixtureEnvironmentKey = "VIBE_NOTIFICATION_PERMISSION"
    static let resetStorageEnvironmentKey = "VIBE_RESET_STORE"
    static let uiTestingEnvironmentKey = "VIBE_UI_TESTING"

    @Published var selectedTab: AppTab = .focus
    @Published var settings: PomodoroSettings
    @Published var activeSession: SessionSnapshot?
    @Published var completedSessions: [CompletedSession]
    @Published var productivityCache: ProductivityAggregateCache
    @Published var notificationPermission: NotificationPermission = .unknown

    let defaults: UserDefaults
    let feedbackPlayer: ReminderFeedbackPlaying
    let encoder = JSONEncoder()
    var stepBoundaryTimer: Timer?
    var currentScenePhase: ScenePhase = .active

    enum StorageKey {
        static let settings = "vibe.settings"
        static let activeSession = "vibe.activeSession"
        static let completedSessions = "vibe.completedSessions"
        static let productivityCache = "vibe.productivityCache"
    }

    init(defaults: UserDefaults = .standard, feedbackPlayer: ReminderFeedbackPlaying? = nil) {
        self.defaults = defaults
        self.feedbackPlayer = feedbackPlayer ?? ReminderFeedbackPlayer()
        Self.resetStorageIfRequested(using: defaults)
        Self.seedUITestingProductivityFixtureIfRequested(using: defaults)
        Self.seedUITestingFocusFixtureIfRequested(using: defaults)
        var loadedSettings: PomodoroSettings = Self.loadValue(for: StorageKey.settings, using: defaults) ?? .default
        Self.applyLaunchAppearanceOverride(to: &loadedSettings)
        self.settings = loadedSettings
        self.activeSession = Self.loadValue(for: StorageKey.activeSession, using: defaults)
        self.completedSessions = Self.loadValue(for: StorageKey.completedSessions, using: defaults) ?? []
        self.productivityCache = Self.loadValue(for: StorageKey.productivityCache, using: defaults) ?? .empty
        self.selectedTab = Self.initialSelectedTab()

        reconcileNow(deliverForegroundFeedback: false)
        repairProductivityCacheIfNeeded()
        syncIdleTimer()
        refreshNotificationPermission()
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

        if ProcessInfo.processInfo.arguments.contains(openSettingsArgument) {
            return .settings
        }

        return .focus
    }

    private static func applyLaunchAppearanceOverride(to settings: inout PomodoroSettings) {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains(appearanceLightArgument) {
            settings.appearanceMode = .light
        } else if arguments.contains(appearanceDarkArgument) {
            settings.appearanceMode = .dark
        } else if arguments.contains(appearanceSystemArgument) {
            settings.appearanceMode = .system
        }
    }

    private static func resetStorageIfRequested(using defaults: UserDefaults) {
        guard shouldResetStorage else { return }

        defaults.removeObject(forKey: StorageKey.settings)
        defaults.removeObject(forKey: StorageKey.activeSession)
        defaults.removeObject(forKey: StorageKey.completedSessions)
        defaults.removeObject(forKey: StorageKey.productivityCache)
    }

    static func runtimeDefaults() -> UserDefaults {
        guard let suiteName = ProcessInfo.processInfo.environment[defaultsSuiteNameEnvironmentKey],
              let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }

        return defaults
    }

    static var isUITestingLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestingArgument)
            || ProcessInfo.processInfo.environment[uiTestingEnvironmentKey] == "1"
    }

    private static var shouldResetStorage: Bool {
        ProcessInfo.processInfo.arguments.contains(resetStorageArgument)
            || ProcessInfo.processInfo.environment[resetStorageEnvironmentKey] == "1"
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
            // Asked here rather than at launch, so the prompt arrives when its reason is on screen.
            requestNotificationPermissionsIfNeeded()
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
