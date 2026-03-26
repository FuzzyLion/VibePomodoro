import SwiftUI

struct SettingsAlertsSection: View {
    @EnvironmentObject private var store: PomodoroStore
    @State private var isPresentingSoundChoice = false

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.sectionHeaderBottomSpacing) {
            SettingsSectionHeader(title: "ALERTS")

            SettingsCard(
                style: .secondary(
                    contentInset: SettingsLayout.cardContentInset,
                    cornerRadius: SettingsLayout.secondaryCardCornerRadius
                ),
                accentOverlay: { EmptyView() }
            ) {
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

                        Button {
                            isPresentingSoundChoice = true
                        } label: {
                            SettingsNavigationValueRow(
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
        .navigationDestination(isPresented: $isPresentingSoundChoice) {
            SettingsSoundChoiceScreen()
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
        VStack(alignment: .leading, spacing: SettingsLayout.sectionHeaderBottomSpacing) {
            SettingsSectionHeader(title: "DISPLAY")

            SettingsCard(
                style: .secondary(
                    contentInset: SettingsLayout.cardContentInset,
                    cornerRadius: SettingsLayout.secondaryCardCornerRadius
                ),
                accentOverlay: { EmptyView() }
            ) {
                SettingsToggleRow(
                    isOn: keepScreenOnBinding,
                    title: "Keep Screen On",
                    subtitle: "Active sessions only"
                )
            }
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
        VStack(alignment: .leading, spacing: SettingsLayout.sectionHeaderBottomSpacing) {
            SettingsSectionHeader(title: "OTHER")

            SettingsCard(
                style: .secondary(
                    contentInset: SettingsLayout.cardContentInset,
                    cornerRadius: SettingsLayout.secondaryCardCornerRadius
                ),
                accentOverlay: { EmptyView() }
            ) {
                VStack(spacing: 0) {
                    SettingsPlaceholderRow(title: "Send Feedback", status: "Soon")

                    SettingsDivider()

                    SettingsPlaceholderRow(title: "Share App", status: "Soon")
                }
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

private struct SettingsNavigationValueRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let value: String

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    titleLabel
                    trailingValue
                }
            } else {
                HStack(spacing: 14) {
                    titleLabel
                    Spacer(minLength: 12)
                    trailingValue
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

    private var trailingValue: some View {
        HStack(spacing: 8) {
            Text(value)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
                .multilineTextAlignment(.trailing)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SettingsTheme.secondaryTextColor(for: colorScheme))
        }
    }
}

private struct SettingsSoundChoiceScreen: View {
    @EnvironmentObject private var store: PomodoroStore

    private var soundOptions: [SoundOption] {
        SoundOption.allCases
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsCard(
                style: .secondary(
                    contentInset: SettingsLayout.cardContentInset,
                    cornerRadius: SettingsLayout.secondaryCardCornerRadius
                ),
                accentOverlay: { EmptyView() }
            ) {
                VStack(spacing: 0) {
                    ForEach(Array(soundOptions.enumerated()), id: \.element.id) { index, option in
                        Button {
                            store.setSelectedSound(option)
                        } label: {
                            SettingsSoundChoiceOptionRow(
                                title: option.title,
                                isSelected: store.settings.selectedSound == option
                            )
                        }
                        .buttonStyle(.plain)

                        if index < soundOptions.count - 1 {
                            SettingsDivider()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, SettingsLayout.pageHorizontalInset)
        .padding(.top, SettingsLayout.pageTopInset)
        .padding(.bottom, SettingsLayout.pageBottomInset)
        .navigationTitle("Reminder Sound")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsSoundChoiceOptionRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))

            Spacer(minLength: 12)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SettingsTheme.sectionAccentColor(for: colorScheme))
            }
        }
        .padding(.vertical, SettingsLayout.rowVerticalPadding)
        .contentShape(Rectangle())
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
