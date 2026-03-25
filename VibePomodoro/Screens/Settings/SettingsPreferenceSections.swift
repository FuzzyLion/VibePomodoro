import SwiftUI

struct SettingsAlertsSection: View {
    @EnvironmentObject private var store: PomodoroStore

    var body: some View {
        SettingsCard(
            style: .secondary(
                contentInset: SettingsLayout.cardContentInset,
                cornerRadius: SettingsLayout.secondaryCardCornerRadius
            ),
            accentOverlay: { EmptyView() }
        ) {
            SettingsCardHeader(title: "ALERTS")

            VStack(spacing: 0) {
                SettingsToggleRow(
                    isOn: notificationsBinding,
                    title: "Notifications"
                )

                SettingsDivider()

                SettingsToggleRow(
                    isOn: soundBinding,
                    title: "Sound",
                    subtitle: store.settings.notificationsEnabled ? nil : "Requires Notifications",
                    disabled: !store.settings.notificationsEnabled
                )

                if store.settings.notificationsEnabled && store.settings.soundEnabled {
                    SettingsDivider()

                    Menu {
                        Picker(
                            "Reminder Sound",
                            selection: soundSelectionBinding
                        ) {
                            ForEach(SoundOption.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    } label: {
                        SettingsValueRow(
                            title: "Sound Choice",
                            value: store.settings.selectedSound.title
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reminder Sound")
                    .accessibilityValue(store.settings.selectedSound.title)
                }

                SettingsDivider()

                SettingsToggleRow(
                    isOn: hapticsBinding,
                    title: "Haptics"
                )
            }
        }
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { store.settings.notificationsEnabled },
            set: store.setNotificationsEnabled
        )
    }

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { store.settings.soundEnabled },
            set: store.setSoundEnabled
        )
    }

    private var soundSelectionBinding: Binding<SoundOption> {
        Binding(
            get: { store.settings.selectedSound },
            set: store.setSelectedSound
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { store.settings.hapticsEnabled },
            set: store.setHapticsEnabled
        )
    }
}

struct SettingsDisplaySection: View {
    @EnvironmentObject private var store: PomodoroStore

    var body: some View {
        SettingsCard(
            style: .secondary(
                contentInset: SettingsLayout.cardContentInset,
                cornerRadius: SettingsLayout.secondaryCardCornerRadius
            ),
            accentOverlay: { EmptyView() }
        ) {
            SettingsCardHeader(title: "DISPLAY")

            SettingsToggleRow(
                isOn: keepScreenOnBinding,
                title: "Keep Screen On",
                subtitle: "Active sessions only"
            )
        }
    }

    private var keepScreenOnBinding: Binding<Bool> {
        Binding(
            get: { store.settings.keepScreenOn },
            set: store.setKeepScreenOn
        )
    }
}

struct SettingsOtherSection: View {
    var body: some View {
        SettingsCard(
            style: .secondary(
                contentInset: SettingsLayout.cardContentInset,
                cornerRadius: SettingsLayout.secondaryCardCornerRadius
            ),
            accentOverlay: { EmptyView() }
        ) {
            SettingsCardHeader(title: "OTHER")

            VStack(spacing: 0) {
                SettingsPlaceholderRow(title: "Send Feedback", status: "Soon")

                SettingsDivider()

                SettingsPlaceholderRow(title: "Share App", status: "Soon")
            }
        }
    }
}

private struct SettingsToggleRow: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var isOn: Bool

    let title: String
    var subtitle: String? = nil
    var disabled: Bool = false

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 4) {
                Text(title)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(.footnote, weight: .medium))
                        .foregroundStyle(SettingsTheme.secondaryTextColor(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, SettingsLayout.rowVerticalPadding)
        }
        .tint(VibePalette.focusTint)
        .disabled(disabled)
        .opacity(disabled ? 0.72 : 1)
    }
}

private struct SettingsValueRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let value: String

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    titleLabel
                    valueLabel
                }
            } else {
                HStack(spacing: 14) {
                    titleLabel
                    Spacer(minLength: 12)
                    valueLabel
                }
            }
        }
        .padding(.vertical, SettingsLayout.rowVerticalPadding)
        .contentShape(Rectangle())
    }

    private var titleLabel: some View {
        Text(title)
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
    }

    private var valueLabel: some View {
        HStack(spacing: 10) {
            Text(value)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
                .multilineTextAlignment(.trailing)

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SettingsTheme.secondaryTextColor(for: colorScheme))
        }
    }
}

private struct SettingsPlaceholderRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let status: String

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    titleLabel
                    statusLabel
                }
            } else {
                HStack(spacing: 14) {
                    titleLabel
                    Spacer(minLength: 12)
                    statusLabel
                }
            }
        }
        .padding(.vertical, SettingsLayout.rowVerticalPadding)
    }

    private var titleLabel: some View {
        Text(title)
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
    }

    private var statusLabel: some View {
        Text(status.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.9)
            .foregroundStyle(SettingsTheme.secondaryTextColor(for: colorScheme))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(SettingsTheme.placeholderFill(for: colorScheme))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(SettingsTheme.placeholderStroke(for: colorScheme), lineWidth: 1)
            }
    }
}
