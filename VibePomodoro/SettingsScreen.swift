import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: PomodoroStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 10)

                SectionTitle(
                    title: "Settings",
                    subtitle: "Precision, rhythm, and a few gentle preferences."
                )

                GlassPanel {
                    VStack(alignment: .leading, spacing: 18) {
                        sectionLabel("TIMER")

                        SettingStepperRow(
                            icon: "sun.max",
                            title: "Focus Duration",
                            subtitle: "Applied to the next session",
                            valueText: "\(store.settings.focusMinutes) min",
                            onDecrement: { store.updateFocusMinutes(max(5, store.settings.focusMinutes - 5)) },
                            onIncrement: { store.updateFocusMinutes(min(120, store.settings.focusMinutes + 5)) }
                        )

                        Divider().opacity(0.18)

                        SettingStepperRow(
                            icon: "cup.and.saucer",
                            title: "Short Break",
                            subtitle: "Between focus rounds",
                            valueText: "\(store.settings.shortBreakMinutes) min",
                            onDecrement: { store.updateShortBreakMinutes(max(1, store.settings.shortBreakMinutes - 1)) },
                            onIncrement: { store.updateShortBreakMinutes(min(30, store.settings.shortBreakMinutes + 1)) }
                        )

                        Divider().opacity(0.18)

                        SettingStepperRow(
                            icon: "sparkles",
                            title: "Long Break",
                            subtitle: "After the final focus round",
                            valueText: "\(store.settings.longBreakMinutes) min",
                            onDecrement: { store.updateLongBreakMinutes(max(5, store.settings.longBreakMinutes - 5)) },
                            onIncrement: { store.updateLongBreakMinutes(min(60, store.settings.longBreakMinutes + 5)) }
                        )

                        Divider().opacity(0.18)

                        SettingStepperRow(
                            icon: "repeat",
                            title: "Focus Rounds",
                            subtitle: "One session ends after the long break",
                            valueText: "\(store.settings.targetRounds)",
                            onDecrement: { store.updateTargetRounds(max(1, store.settings.targetRounds - 1)) },
                            onIncrement: { store.updateTargetRounds(min(12, store.settings.targetRounds + 1)) }
                        )
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 18) {
                        sectionLabel("ALERTS")

                        SettingToggleRow(
                            icon: "bell.badge",
                            title: "Notifications",
                            subtitle: "Step start and end reminders",
                            isOn: Binding(
                                get: { store.settings.notificationsEnabled },
                                set: store.setNotificationsEnabled
                            )
                        )

                        Divider().opacity(0.18)

                        SettingToggleRow(
                            icon: "speaker.wave.2",
                            title: "Sound",
                            subtitle: "Use sound in reminders",
                            isOn: Binding(
                                get: { store.settings.soundEnabled },
                                set: store.setSoundEnabled
                            )
                        )

                        if store.settings.soundEnabled {
                            Divider().opacity(0.18)

                            SettingPickerRow(
                                icon: "music.note",
                                title: "Sound Setting",
                                subtitle: "Curated app sounds for the MVP",
                                selection: Binding(
                                    get: { store.settings.selectedSound },
                                    set: store.setSelectedSound
                                )
                            )
                        }

                        Divider().opacity(0.18)

                        SettingToggleRow(
                            icon: "iphone.radiowaves.left.and.right",
                            title: "Haptics",
                            subtitle: "Foreground vibration feedback",
                            isOn: Binding(
                                get: { store.settings.hapticsEnabled },
                                set: store.setHapticsEnabled
                            )
                        )
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 18) {
                        sectionLabel("DISPLAY")

                        SettingToggleRow(
                            icon: "display",
                            title: "Keep Screen On",
                            subtitle: "Only while a session is actively running",
                            isOn: Binding(
                                get: { store.settings.keepScreenOn },
                                set: store.setKeepScreenOn
                            )
                        )
                    }
                }

                Text("Changes here affect the next session. Your current run keeps its original timing snapshot.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    private func sectionLabel(_ label: String) -> some View {
        Text(label)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .tracking(2)
            .foregroundStyle(.secondary)
    }
}

