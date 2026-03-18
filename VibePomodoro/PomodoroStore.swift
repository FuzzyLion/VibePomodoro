import Combine
import Foundation
import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class PomodoroStore: ObservableObject {
    @Published var selectedTab: AppTab = .focus
    @Published private(set) var settings: PomodoroSettings
    @Published private(set) var activeSession: SessionSnapshot?
    @Published private(set) var completedSessions: [CompletedSession]

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var timer: Timer?

    private enum StorageKey {
        static let settings = "vibe.settings"
        static let activeSession = "vibe.activeSession"
        static let completedSessions = "vibe.completedSessions"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = Self.loadValue(for: StorageKey.settings, using: defaults) ?? .default
        self.activeSession = Self.loadValue(for: StorageKey.activeSession, using: defaults)
        self.completedSessions = Self.loadValue(for: StorageKey.completedSessions, using: defaults) ?? []

        reconcileNow()
        startTicker()
        syncIdleTimer()
        requestNotificationPermissionsIfNeeded()
        syncNotifications()
    }

    deinit {
        timer?.invalidate()
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
        return session.currentStepIndex > 0 || session.statistics(now: .now).sessionTime > 0
    }

    var shouldShowBackAction: Bool {
        guard let session = activeSession else { return false }

        switch session.runState {
        case .idle:
            return session.statistics(now: .now).sessionTime > 0
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

        if session.runState == .completed {
            return "COMPLETE"
        }

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
            persist()
        case .completed:
            startNewSession()
        }

        syncIdleTimer()
        syncNotifications()
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

    func updateFocusMinutes(_ minutes: Int) {
        guard settings.focusMinutes != minutes else { return }
        settings.focusMinutes = minutes
        persist()
        fireAdjustmentFeedback()
    }

    func updateShortBreakMinutes(_ minutes: Int) {
        guard settings.shortBreakMinutes != minutes else { return }
        settings.shortBreakMinutes = minutes
        persist()
        fireAdjustmentFeedback()
    }

    func updateLongBreakMinutes(_ minutes: Int) {
        guard settings.longBreakMinutes != minutes else { return }
        settings.longBreakMinutes = minutes
        persist()
        fireAdjustmentFeedback()
    }

    func updateTargetRounds(_ rounds: Int) {
        guard settings.targetRounds != rounds else { return }
        settings.targetRounds = rounds
        persist()
        fireAdjustmentFeedback()
    }

    func setKeepScreenOn(_ enabled: Bool) {
        settings.keepScreenOn = enabled
        persist()
        syncIdleTimer()
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
        if enabled {
            requestNotificationPermissionsIfNeeded()
        }
        persist()
        syncNotifications()
    }

    func setSoundEnabled(_ enabled: Bool) {
        settings.soundEnabled = enabled
        persist()
        syncNotifications()
    }

    func setHapticsEnabled(_ enabled: Bool) {
        settings.hapticsEnabled = enabled
        persist()
    }

    func setSelectedSound(_ option: SoundOption) {
        settings.selectedSound = option
        persist()
        syncNotifications()
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            reconcileNow()
            syncIdleTimer()
            syncNotifications()
        case .inactive, .background:
            persist()
        @unknown default:
            break
        }
    }

    func chartPoints(for range: ProductivityRange, now: Date = .now) -> [ProductivityChartPoint] {
        let calendar = Calendar.autoupdatingCurrent
        let config = bucketConfiguration(for: range, calendar: calendar, now: now)
        var buckets: [Date: ProductivityChartPoint] = [:]

        for bucketStart in config.bucketStarts {
            buckets[bucketStart] = ProductivityChartPoint(
                startDate: bucketStart,
                label: config.label(bucketStart),
                focusTime: 0,
                breakTime: 0
            )
        }

        for segment in allSegments(now: now) {
            let boundedStart = max(segment.startDate, config.rangeStart)
            let boundedEnd = min(segment.endDate, config.rangeEnd)
            guard boundedEnd > boundedStart else { continue }

            var cursor = boundedStart
            while cursor < boundedEnd {
                let bucketStart = config.floor(cursor)
                guard let point = buckets[bucketStart] else { break }
                let bucketEnd = config.next(bucketStart)
                let sliceEnd = min(bucketEnd, boundedEnd)
                let duration = sliceEnd.timeIntervalSince(cursor)

                let updatedPoint: ProductivityChartPoint
                if segment.phase == .focus {
                    updatedPoint = point.updating(focusTime: point.focusTime + duration, breakTime: point.breakTime)
                } else {
                    updatedPoint = point.updating(focusTime: point.focusTime, breakTime: point.breakTime + duration)
                }

                buckets[bucketStart] = updatedPoint
                cursor = sliceEnd
            }
        }

        return config.bucketStarts.compactMap { buckets[$0] }
    }

    func totalFocusTime(now: Date = .now) -> TimeInterval {
        allSegments(now: now).filter { $0.phase == .focus }.reduce(0) { $0 + $1.duration }
    }

    func totalBreakTime(now: Date = .now) -> TimeInterval {
        allSegments(now: now).filter { $0.phase != .focus }.reduce(0) { $0 + $1.duration }
    }

    func totalSessionTime(now: Date = .now) -> TimeInterval {
        allSegments(now: now).reduce(0) { $0 + $1.duration }
    }

    func completedSessionCount() -> Int {
        completedSessions.count
    }

    func streakLength(now: Date = .now) -> Int {
        let calendar = Calendar.autoupdatingCurrent
        let dailyFocus = Dictionary(grouping: allSegments(now: now).filter { $0.phase == .focus }) {
            calendar.startOfDay(for: $0.startDate)
        }

        var streak = 0
        var day = calendar.startOfDay(for: now)

        while let segments = dailyFocus[day], !segments.isEmpty {
            let total = segments.reduce(0) { $0 + $1.duration }
            guard total > 0 else { break }

            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return streak
    }

    func averageFocusHoursPerDay(now: Date = .now) -> Double {
        let calendar = Calendar.autoupdatingCurrent
        let grouped = Dictionary(grouping: allSegments(now: now).filter { $0.phase == .focus }) {
            calendar.startOfDay(for: $0.startDate)
        }

        guard !grouped.isEmpty else { return 0 }
        let total = grouped.values.flatMap { $0 }.reduce(0) { $0 + $1.duration }
        return total / Double(grouped.count) / 3600
    }

    private func startNewSession() {
        activeSession = SessionSnapshot.makeNew(settings: settings, now: .now)
        togglePrimaryAction()
    }

    private func reconcileNow() {
        guard var session = activeSession else { return }
        let events = PomodoroEngine.reconcile(session: &session, now: .now)
        activeSession = session
        handle(events: events)
    }

    private func handle(events: [PomodoroEvent]) {
        guard !events.isEmpty else {
            persist()
            syncIdleTimer()
            syncNotifications()
            return
        }

        for event in events {
            switch event {
            case .phaseStarted:
                fireForegroundFeedback(type: .success)
            case .phaseCompleted:
                fireForegroundFeedback(type: .warning)
            case .sessionCompleted:
                fireForegroundFeedback(type: .success)
                storeCompletedSessionIfNeeded()
            }
        }

        persist()
        syncIdleTimer()
        syncNotifications()
    }

    private func storeCompletedSessionIfNeeded() {
        guard let session = activeSession, session.runState == .completed else { return }
        guard !completedSessions.contains(where: { $0.id == session.id }) else { return }

        completedSessions.insert(
            CompletedSession(
                id: session.id,
                createdAt: session.createdAt,
                completedAt: .now,
                settingsSnapshot: session.settingsSnapshot,
                segments: session.segments
            ),
            at: 0
        )
    }

    private func fireForegroundFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard settings.hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    private func fireAdjustmentFeedback() {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.82)
    }

    private func syncIdleTimer() {
        let keepAwake = settings.keepScreenOn && activeSession?.runState == .running
        UIApplication.shared.isIdleTimerDisabled = keepAwake
    }

    private func persist() {
        Self.saveValue(settings, for: StorageKey.settings, using: defaults, encoder: encoder)
        Self.saveValue(activeSession, for: StorageKey.activeSession, using: defaults, encoder: encoder)
        Self.saveValue(completedSessions, for: StorageKey.completedSessions, using: defaults, encoder: encoder)
    }

    private func startTicker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.reconcileNow()
            }
        }
    }

    private func allSegments(now: Date) -> [ActivitySegment] {
        var segments = completedSessions.flatMap(\.segments)

        if let session = activeSession {
            segments.append(contentsOf: session.segments)

            if session.runState == .running,
               let step = session.currentStep,
               let startDate = session.currentSegmentStartDate {
                let endDate = min(now, session.targetEndDate ?? now)
                if endDate > startDate {
                    segments.append(
                        ActivitySegment(
                            id: UUID(),
                            stepID: step.id,
                            phase: step.phase,
                            roundNumber: step.roundNumber,
                            startDate: startDate,
                            endDate: endDate
                        )
                    )
                }
            }
        }

        return segments
    }

    private func requestNotificationPermissionsIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func syncNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: pendingNotificationIdentifiers())

        guard settings.notificationsEnabled,
              let session = activeSession,
              session.runState == .running,
              let firstBoundary = session.targetEndDate,
              session.currentStep != nil else {
            return
        }

        var boundaryDate = firstBoundary

        for index in session.currentStepIndex..<session.steps.count {
            let step = session.steps[index]
            if index > session.currentStepIndex {
                boundaryDate = boundaryDate.addingTimeInterval(step.plannedDuration)
            }

            let nextStepIndex = index + 1
            let nextStep = session.steps.indices.contains(nextStepIndex) ? session.steps[nextStepIndex] : nil

            let content = UNMutableNotificationContent()
            if let nextStep {
                content.title = "\(step.phase.title) complete"
                content.body = "\(nextStep.phase.title) begins now."
            } else {
                content.title = "\(step.phase.title) complete"
                content.body = "Session complete. Take a breath."
            }
            if settings.soundEnabled {
                content.sound = .default
            }

            let interval = max(1, boundaryDate.timeIntervalSinceNow)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationIdentifier(for: session.id, stepIndex: index),
                content: content,
                trigger: trigger
            )

            center.add(request, withCompletionHandler: nil)
        }
    }

    private func pendingNotificationIdentifiers() -> [String] {
        guard let session = activeSession else { return [] }
        return (0..<session.steps.count).map { notificationIdentifier(for: session.id, stepIndex: $0) }
    }

    private func notificationIdentifier(for sessionID: UUID, stepIndex: Int) -> String {
        "vibe.\(sessionID.uuidString).\(stepIndex)"
    }

    private func bucketConfiguration(for range: ProductivityRange, calendar: Calendar, now: Date) -> BucketConfiguration {
        switch range {
        case .day:
            let hour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
            let starts = (0..<8).compactMap { calendar.date(byAdding: .hour, value: -7 + $0, to: hour) }

            return BucketConfiguration(
                rangeStart: starts.first ?? hour,
                rangeEnd: calendar.date(byAdding: .hour, value: 1, to: starts.last ?? hour) ?? now,
                bucketStarts: starts,
                floor: { date in calendar.dateInterval(of: .hour, for: date)?.start ?? date },
                next: { date in calendar.date(byAdding: .hour, value: 1, to: date) ?? date },
                label: { date in
                    date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)))
                }
            )
        case .week:
            let today = calendar.startOfDay(for: now)
            let starts = (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }

            return BucketConfiguration(
                rangeStart: starts.first ?? today,
                rangeEnd: calendar.date(byAdding: .day, value: 1, to: starts.last ?? today) ?? now,
                bucketStarts: starts,
                floor: { calendar.startOfDay(for: $0) },
                next: { date in calendar.date(byAdding: .day, value: 1, to: date) ?? date },
                label: { date in
                    date.formatted(.dateTime.weekday(.abbreviated))
                }
            )
        case .month:
            let today = calendar.startOfDay(for: now)
            let starts = (0..<30).compactMap { calendar.date(byAdding: .day, value: -29 + $0, to: today) }

            return BucketConfiguration(
                rangeStart: starts.first ?? today,
                rangeEnd: calendar.date(byAdding: .day, value: 1, to: starts.last ?? today) ?? now,
                bucketStarts: starts,
                floor: { calendar.startOfDay(for: $0) },
                next: { date in calendar.date(byAdding: .day, value: 1, to: date) ?? date },
                label: { date in
                    date.formatted(.dateTime.day())
                }
            )
        case .year:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let starts = (0..<12).compactMap { calendar.date(byAdding: .month, value: -11 + $0, to: monthStart) }

            return BucketConfiguration(
                rangeStart: starts.first ?? monthStart,
                rangeEnd: calendar.date(byAdding: .month, value: 1, to: starts.last ?? monthStart) ?? now,
                bucketStarts: starts,
                floor: { date in
                    calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
                },
                next: { date in calendar.date(byAdding: .month, value: 1, to: date) ?? date },
                label: { date in
                    date.formatted(.dateTime.month(.abbreviated))
                }
            )
        }
    }

    private static func saveValue<T: Encodable>(_ value: T?, for key: String, using defaults: UserDefaults, encoder: JSONEncoder) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }

        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadValue<T: Decodable>(for key: String, using defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

struct ProductivityChartPoint: Identifiable, Equatable {
    let startDate: Date
    let label: String
    let focusTime: TimeInterval
    let breakTime: TimeInterval

    var id: Date { startDate }

    func updating(focusTime: TimeInterval, breakTime: TimeInterval) -> ProductivityChartPoint {
        ProductivityChartPoint(startDate: startDate, label: label, focusTime: focusTime, breakTime: breakTime)
    }
}

private struct BucketConfiguration {
    let rangeStart: Date
    let rangeEnd: Date
    let bucketStarts: [Date]
    let floor: (Date) -> Date
    let next: (Date) -> Date
    let label: (Date) -> String
}
