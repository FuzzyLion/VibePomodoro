import Foundation
import UserNotifications

struct PomodoroNotificationPlan: Equatable {
    let identifier: String
    let title: String
    let body: String
    let timeInterval: TimeInterval
    let soundResource: ReminderSoundResource?

    var soundName: String? {
        soundResource?.notificationSoundName
    }
}

extension NotificationPermission {
    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized, .provisional, .ephemeral:
            self = .allowed
        @unknown default:
            self = .allowed
        }
    }
}

extension PomodoroStore {
    /// Asks iOS once, while notifications are on in the app and iOS hasn't been asked yet. Called on the
    /// first Start and when Notifications is turned on, so the prompt arrives when its reason is visible.
    func requestNotificationPermissionsIfNeeded() {
        guard !Self.isUITestingLaunch,
              settings.notificationsEnabled,
              notificationPermission == .unknown || notificationPermission == .notDetermined else {
            return
        }

        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await updateNotificationPermission()
            // Reminders for a session that started before the answer.
            syncNotifications()
        }
    }

    /// Reads what iOS allows now. Called at launch and whenever the app returns to the foreground,
    /// since people change it in iOS Settings.
    func refreshNotificationPermission() {
        Task {
            await updateNotificationPermission()
        }
    }

    func updateNotificationPermission() async {
        let permission: NotificationPermission
        if Self.isUITestingLaunch {
            permission = Self.uiTestingNotificationPermission ?? .notDetermined
        } else {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            permission = NotificationPermission(status)
        }

        // Publishing redraws every view that watches the store, the Focus bubble included.
        if notificationPermission != permission {
            notificationPermission = permission
        }
    }

    func syncNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: pendingNotificationIdentifiers())

        let plans = notificationPlans(now: .now)

        for plan in plans {
            let content = UNMutableNotificationContent()
            content.title = plan.title
            content.body = plan.body
            if let soundName = plan.soundName {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: plan.timeInterval, repeats: false)
            let request = UNNotificationRequest(
                identifier: plan.identifier,
                content: content,
                trigger: trigger
            )

            center.add(request, withCompletionHandler: nil)
        }
    }

    func notificationPlans(now: Date = .now) -> [PomodoroNotificationPlan] {
        guard settings.notificationsEnabled,
              let session = activeSession,
              session.runState == .running,
              let firstBoundary = session.targetEndDate,
              session.currentStep != nil else {
            return []
        }

        var boundaryDate = firstBoundary
        var plans: [PomodoroNotificationPlan] = []

        for index in session.currentStepIndex..<session.steps.count {
            let step = session.steps[index]
            if index > session.currentStepIndex {
                boundaryDate = boundaryDate.addingTimeInterval(step.plannedDuration)
            }

            let nextStepIndex = index + 1
            let nextStep = session.steps.indices.contains(nextStepIndex) ? session.steps[nextStepIndex] : nil

            let title: String
            let body: String
            if let nextStep {
                title = "\(step.phase.title) complete"
                body = "\(nextStep.phase.title) begins now."
            } else {
                title = "\(step.phase.title) complete"
                body = "Session complete. Take a breath."
            }

            let soundResource: ReminderSoundResource?
            if settings.soundEnabled {
                soundResource = nextStep == nil ? .sessionCompleteThud : .nextPhaseWhoosh
            } else {
                soundResource = nil
            }

            plans.append(PomodoroNotificationPlan(
                identifier: notificationIdentifier(for: session.id, stepIndex: index),
                title: title,
                body: body,
                timeInterval: max(1, boundaryDate.timeIntervalSince(now)),
                soundResource: soundResource
            ))
        }

        return plans
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
