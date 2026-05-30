import Foundation
import UserNotifications

extension PomodoroStore {
    func requestNotificationPermissionsIfNeeded() {
        guard !Self.isUITestingLaunch else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func syncNotifications() {
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
}

private extension PomodoroStore {
    func pendingNotificationIdentifiers() -> [String] {
        guard let session = activeSession else { return [] }
        return (0..<session.steps.count).map { notificationIdentifier(for: session.id, stepIndex: $0) }
    }

    func notificationIdentifier(for sessionID: UUID, stepIndex: Int) -> String {
        "vibe.\(sessionID.uuidString).\(stepIndex)"
    }
}
