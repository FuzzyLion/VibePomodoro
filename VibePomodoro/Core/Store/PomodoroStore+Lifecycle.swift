import Foundation
import SwiftUI
import UIKit

extension PomodoroStore {
    func handleScenePhaseChange(_ phase: ScenePhase) {
        currentScenePhase = phase

        switch phase {
        case .active:
            reconcileNow(deliverForegroundFeedback: false)
            syncIdleTimer()
            syncNotifications()
        case .inactive, .background:
            persist()
        @unknown default:
            break
        }

        syncStepBoundaryTimer()
    }

    func startNewSession() {
        activeSession = SessionSnapshot.makeNew(settings: settings, now: .now)
        togglePrimaryAction()
    }

    func reconcileNow(deliverForegroundFeedback: Bool = true) {
        guard var session = activeSession else { return }
        let previousSession = session
        let events = PomodoroEngine.reconcile(session: &session, now: .now)
        guard session != previousSession || !events.isEmpty else { return }
        activeSession = session
        handle(events: events, deliverForegroundFeedback: deliverForegroundFeedback)
    }

    func handle(events: [PomodoroEvent], deliverForegroundFeedback: Bool = true) {
        guard !events.isEmpty else {
            refreshRuntimeSideEffects()
            return
        }

        let completedSession = events.contains(.sessionCompleted) ? activeSession : nil

        if deliverForegroundFeedback {
            let actions = ReminderFeedbackPlan.actions(
                for: events,
                isForeground: currentScenePhase == .active,
                soundEnabled: settings.soundEnabled,
                hapticsEnabled: settings.hapticsEnabled
            )
            if !actions.isEmpty {
                feedbackPlayer.play(actions)
            }
        }

        guard let completedSession else {
            refreshRuntimeSideEffects()
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            storeCompletedSessionIfNeeded(from: completedSession)
        }
        refreshRuntimeSideEffects()
    }

    func syncIdleTimer() {
        let keepAwake = settings.keepScreenOn && activeSession?.runState == .running
        UIApplication.shared.isIdleTimerDisabled = keepAwake
    }

    func refreshRuntimeSideEffects() {
        persist()
        syncIdleTimer()
        syncNotifications()
        syncStepBoundaryTimer()
        syncLiveActivity()
    }

    func syncLiveActivity() {
        liveActivityCoordinator.refresh(session: activeSession, now: .now)
    }

    func syncStepBoundaryTimer() {
        stepBoundaryTimer?.invalidate()
        stepBoundaryTimer = nil

        guard let session = activeSession,
              session.runState == .running,
              session.currentStep != nil,
              let targetEndDate = session.targetEndDate else {
            return
        }

        let interval = max(0.05, targetEndDate.timeIntervalSinceNow)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.reconcileNow()
            }
        }
        timer.tolerance = min(0.25, interval * 0.05)
        stepBoundaryTimer = timer
    }

    private func storeCompletedSessionIfNeeded(from session: SessionSnapshot) {
        guard session.runState == .completed else { return }
        let completedSession: CompletedSession

        if let existing = completedSessions.first(where: { $0.id == session.id }) {
            completedSession = existing
        } else {
            completedSession = CompletedSession(
                id: session.id,
                createdAt: session.createdAt,
                completedAt: .now,
                settingsSnapshot: session.settingsSnapshot,
                segments: session.segments
            )
            completedSessions.insert(completedSession, at: 0)
        }

        productivityCache.apply(completedSession)
    }

}
