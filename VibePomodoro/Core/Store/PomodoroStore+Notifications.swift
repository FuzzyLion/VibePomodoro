import Foundation
import UserNotifications

enum PomodoroNotificationDeliveryKind: Equatable {
    case phaseChange
    case sessionCompletion
}

struct PomodoroNotificationPlan: Equatable {
    let identifier: String
    let title: String
    let body: String
    let timeInterval: TimeInterval
    let soundResource: ReminderSoundResource?
    let phase: SessionPhase
    let roundNumber: Int
    let targetRounds: Int
    let deliveryKind: PomodoroNotificationDeliveryKind

    var soundName: String? {
        soundResource?.notificationSoundName
    }
}

extension PomodoroStore {
    func requestNotificationPermissionsIfNeeded() {
        guard !Self.isUITestingLaunch else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
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
            let deliveryKind: PomodoroNotificationDeliveryKind
            if let nextStep {
                title = "\(step.phase.title) complete"
                body = "\(nextStep.phase.title) - Round \(nextStep.roundNumber) of \(session.targetRounds)"
                deliveryKind = .phaseChange
            } else {
                title = "Session complete"
                body = "\(session.targetRounds) rounds finished. Take a breath."
                deliveryKind = .sessionCompletion
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
                soundResource: soundResource,
                phase: step.phase,
                roundNumber: step.roundNumber,
                targetRounds: session.targetRounds,
                deliveryKind: deliveryKind
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
