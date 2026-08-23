import UIKit

extension PomodoroStore {
    func normalizeSettingsIfNeeded() {
        var normalizedSettings = settings
        normalizedSettings.focusMinutes = SettingsTimerField.focus.value(in: settings)
        normalizedSettings.shortBreakMinutes = SettingsTimerField.shortBreak.value(in: settings)
        normalizedSettings.longBreakMinutes = SettingsTimerField.longBreak.value(in: settings)
        normalizedSettings.targetRounds = SettingsTimerField.rounds.value(in: settings)

        guard normalizedSettings != settings else { return }

        settings = normalizedSettings
        persist(.settings)
    }

    func updateFocusMinutes(_ minutes: Int, fireFeedback: Bool = true) {
        guard settings.focusMinutes != minutes else { return }
        settings.focusMinutes = minutes
        persist(.settings)
        if fireFeedback {
            fireAdjustmentFeedback()
        }
    }

    func updateShortBreakMinutes(_ minutes: Int, fireFeedback: Bool = true) {
        guard settings.shortBreakMinutes != minutes else { return }
        settings.shortBreakMinutes = minutes
        persist(.settings)
        if fireFeedback {
            fireAdjustmentFeedback()
        }
    }

    func updateLongBreakMinutes(_ minutes: Int, fireFeedback: Bool = true) {
        guard settings.longBreakMinutes != minutes else { return }
        settings.longBreakMinutes = minutes
        persist(.settings)
        if fireFeedback {
            fireAdjustmentFeedback()
        }
    }

    func updateTargetRounds(_ rounds: Int, fireFeedback: Bool = true) {
        guard settings.targetRounds != rounds else { return }
        settings.targetRounds = rounds
        persist(.settings)
        if fireFeedback {
            fireAdjustmentFeedback()
        }
    }

    func setKeepScreenOn(_ enabled: Bool) {
        guard settings.keepScreenOn != enabled else { return }
        settings.keepScreenOn = enabled
        persist(.settings)
        syncIdleTimer()
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        guard settings.notificationsEnabled != enabled else { return }
        settings.notificationsEnabled = enabled
        if enabled {
            requestNotificationPermissionsIfNeeded()
        }
        persist(.settings)
        syncNotifications()
    }

    func setSoundEnabled(_ enabled: Bool) {
        guard settings.soundEnabled != enabled else { return }
        settings.soundEnabled = enabled
        persist(.settings)
        syncNotifications()
    }

    func setHapticsEnabled(_ enabled: Bool) {
        guard settings.hapticsEnabled != enabled else { return }
        settings.hapticsEnabled = enabled
        persist(.settings)
    }

    func setAppearanceMode(_ mode: PomodoroAppearanceMode) {
        guard settings.appearanceMode != mode else { return }
        settings.appearanceMode = mode
        persist(.settings)
        fireAdjustmentFeedback()
    }

    private func fireAdjustmentFeedback() {
        guard settings.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.82)
    }
}
