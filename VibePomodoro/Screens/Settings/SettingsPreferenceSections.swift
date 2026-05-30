import SwiftUI

struct SettingsAlertsSection: View {
    @EnvironmentObject private var store: PomodoroStore

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

                    SettingsDivider()

                    SettingsToggleRow(
                        isOn: hapticsBinding,
                        title: "Haptics"
                    )
                }
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
    @EnvironmentObject private var store: PomodoroStore
    @State private var isShowingClearHistoryAlert = false

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

                    SettingsDivider()

                    Button {
                        isShowingClearHistoryAlert = true
                    } label: {
                        SettingsDestructiveActionRow(
                            title: "Clear Productivity History",
                            subtitle: hasProductivityHistory
                                ? "Delete all completed sessions and stats"
                                : "No history yet",
                            disabled: !hasProductivityHistory
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasProductivityHistory)
                    .accessibilityHint(
                        hasProductivityHistory
                            ? "Shows a final confirmation before deleting all completed sessions and stats."
                            : "No completed session history to delete."
                    )
                }
            }
        }
        .alert("Delete all productivity history?", isPresented: $isShowingClearHistoryAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete History", role: .destructive) {
                store.clearProductivityHistory()
            }
        } message: {
            Text("This action can't be undone. Current session and timer settings will stay as they are.")
        }
    }

    private var hasProductivityHistory: Bool {
        !store.completedSessions.isEmpty
            || store.productivityCache.completedSessionCount > 0
            || !store.productivityCache.dailySummaries.isEmpty
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

private struct SettingsDestructiveActionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let subtitle: String
    let disabled: Bool

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    labelStack
                    trailingIcon
                }
            } else {
                HStack(spacing: 14) {
                    labelStack
                    Spacer(minLength: 12)
                    trailingIcon
                }
            }
        }
        .padding(.vertical, SettingsLayout.rowVerticalPadding)
        .contentShape(Rectangle())
        .opacity(disabled ? 0.72 : 1)
    }

    private var labelStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(destructiveTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(SettingsTheme.secondaryTextColor(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var trailingIcon: some View {
        Image(systemName: "trash")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(disabled ? SettingsTheme.secondaryTextColor(for: colorScheme) : destructiveTextColor)
    }

    private var destructiveTextColor: Color {
        colorScheme == .dark ? Color.red.opacity(0.86) : Color.red.opacity(0.82)
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
