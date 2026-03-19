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

struct SettingStepperRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let valueText: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            settingIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 30, height: 30)
                }

                Text(valueText)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .monospacedDigit()

                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 30, height: 30)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.18))
            )
        }
    }

    private var settingIcon: some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 42, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.14))
            )
    }
}

struct SettingToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isOn ? VibePalette.focusTint : .secondary)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill((isOn ? VibePalette.focusTint : .white).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(VibePalette.focusTint)
        }
    }
}

struct SettingPickerRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var selection: SoundOption

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker(title, selection: $selection) {
                ForEach(SoundOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(VibePalette.focusTint)
        }
    }
}
