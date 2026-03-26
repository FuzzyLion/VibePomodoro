import UIKit

extension PomodoroStore {
    func updateFocusMinutes(_ minutes: Int, fireFeedback: Bool = true) {
        guard settings.focusMinutes != minutes else { return }
        settings.focusMinutes = minutes
        persist()
        if fireFeedback {
            fireAdjustmentFeedback()
        }
    }

    func updateShortBreakMinutes(_ minutes: Int, fireFeedback: Bool = true) {
        guard settings.shortBreakMinutes != minutes else { return }
        settings.shortBreakMinutes = minutes
        persist()
        if fireFeedback {
            fireAdjustmentFeedback()
        }
    }

    func updateLongBreakMinutes(_ minutes: Int, fireFeedback: Bool = true) {
        guard settings.longBreakMinutes != minutes else { return }
        settings.longBreakMinutes = minutes
        persist()
        if fireFeedback {
            fireAdjustmentFeedback()
        }
    }

    func updateTargetRounds(_ rounds: Int, fireFeedback: Bool = true) {
        guard settings.targetRounds != rounds else { return }
        settings.targetRounds = rounds
        persist()
        if fireFeedback {
            fireAdjustmentFeedback()
        }
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

    private func fireAdjustmentFeedback() {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.82)
    }
}
