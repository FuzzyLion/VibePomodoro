import SwiftUI
import UIKit

struct SettingsAlertsSection: View {
    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        let presentation = SettingsAlertsPresentation(
            notificationsEnabled: store.settings.notificationsEnabled,
            permission: store.notificationPermission
        )

        VStack(alignment: .leading, spacing: SettingsLayout.sectionHeaderBottomSpacing) {
            SettingsSectionHeader(title: "ALERTS")

            SettingsCard(
                style: .secondary(
                    contentInset: SettingsLayout.cardContentInset,
                    cornerRadius: SettingsLayout.secondaryCardCornerRadius
                ),
                accentOverlay: { EmptyView() }
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    if presentation.opensSystemSettings {
                        SettingsSystemSettingsRow(
                            title: "Notifications",
                            detail: SettingsAlertsPresentation.blockedNotificationsDetail,
                            openSettings: openNotificationSettings
                        )
                    } else {
                        SettingsToggleRow(
                            isOn: notificationsBinding,
                            title: "Notifications"
                        )
                    }

                    SettingsDivider()

                    SettingsToggleRow(
                        isOn: soundBinding,
                        title: "Sound",
                        subtitle: presentation.soundDetail
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

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        openURL(url)
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
                VStack(alignment: .leading, spacing: 0) {
                    appearanceMenu

                    SettingsDivider()

                    SettingsToggleRow(
                        isOn: keepScreenOnBinding,
                        title: "Keep Screen On",
                        subtitle: "Active sessions only"
                    )
                }
            }
        }
    }

    private var keepScreenOnBinding: Binding<Bool> {
        Binding(
            get: { store.settings.keepScreenOn },
            set: store.setKeepScreenOn
        )
    }

    private var appearanceMenu: some View {
        Menu {
            // Each choice is a toggle, so the system draws its checkmark. A checkmark image in a
            // button's label disappears at accessibility text sizes, where menus drop images.
            ForEach(PomodoroAppearanceMode.allCases) { mode in
                Toggle(mode.title, isOn: appearanceSelection(mode))
                    .accessibilityIdentifier("settings.appearance.\(mode.rawValue)")
            }
        } label: {
            SettingsMenuRow(
                title: "Appearance",
                value: store.settings.appearanceMode.title
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Appearance")
        .accessibilityValue(store.settings.appearanceMode.title)
        .accessibilityHint("Opens appearance mode choices.")
        .accessibilityIdentifier("settings.appearance")
    }

    /// Choosing the current mode again leaves it chosen.
    private func appearanceSelection(_ mode: PomodoroAppearanceMode) -> Binding<Bool> {
        Binding(
            get: { store.settings.appearanceMode == mode },
            set: { isOn in
                if isOn {
                    store.setAppearanceMode(mode)
                }
            }
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
                VStack(alignment: .leading, spacing: 0) {
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
                    .buttonStyle(SettingsRowButtonStyle())
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

/// A capsule that shows a value or an action at the trailing end of a row.
private struct SettingsValuePill: View {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .body) private var minHeight = SettingsLayout.pickerValuePillHeight
    @ScaledMetric(relativeTo: .body) private var symbolSize: CGFloat = 10

    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.86)

            Image(systemName: systemImage)
                .font(.system(size: symbolSize, weight: .bold))
                .foregroundStyle(SettingsTheme.secondaryTextColor(for: colorScheme).opacity(0.55))
                .accessibilityHidden(true)
        }
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .frame(minHeight: minHeight)
        .background(
            Capsule(style: .continuous)
                .fill(SettingsTheme.valuePillFill(for: colorScheme))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(SettingsTheme.valuePillStroke(for: colorScheme), lineWidth: 1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct SettingsMenuRow: View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SettingsLayout.rowVerticalPadding)
        .contentShape(Rectangle())
    }

    private var titleLabel: some View {
        Text(title)
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var valueLabel: some View {
        SettingsValuePill(text: value, systemImage: "chevron.up.chevron.down")
    }
}

/// A row for a setting iOS controls. It says where the setting lives and opens iOS Settings there.
private struct SettingsSystemSettingsRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let detail: String
    let openSettings: () -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    labelStack
                    openButton
                }
            } else {
                HStack(spacing: 14) {
                    labelStack
                    Spacer(minLength: 12)
                    openButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SettingsLayout.rowVerticalPadding)
    }

    private var labelStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(SettingsTheme.secondaryTextColor(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var openButton: some View {
        Button(action: openSettings) {
            SettingsValuePill(text: "Open Settings", systemImage: "arrow.up.forward")
        }
        .buttonStyle(SettingsRowButtonStyle())
        .accessibilityHint("Opens VibePomodoro in iOS Settings.")
        .accessibilityIdentifier("settings.notifications.openSettings")
    }
}

private struct SettingsToggleRow: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var isOn: Bool

    let title: String
    var subtitle: String? = nil

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
        .accessibilityIdentifier(title)
    }
}

/// Keeps a row's own colors while it's disabled, so the row can draw a readable disabled look
/// instead of being faded by the system.
private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.62 : 1)
            .contentShape(Rectangle())
    }
}

private struct SettingsDestructiveActionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 14

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SettingsLayout.rowVerticalPadding)
        .contentShape(Rectangle())
    }

    private var labelStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(accentColor)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(SettingsTheme.secondaryTextColor(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var trailingIcon: some View {
        Image(systemName: "trash")
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundStyle(accentColor)
            .accessibilityHidden(true)
    }

    /// With nothing to delete, the row reads as ordinary secondary text rather than a faded warning.
    private var accentColor: ContrastAdaptiveColor {
        disabled
            ? SettingsTheme.secondaryTextColor(for: colorScheme)
            : SettingsTheme.destructiveTextColor(for: colorScheme)
    }
}

private struct SettingsPlaceholderRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption2) private var statusSize: CGFloat = 11

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SettingsLayout.rowVerticalPadding)
    }

    private var titleLabel: some View {
        Text(title)
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
    }

    private var statusLabel: some View {
        Text(status.uppercased())
            .font(.system(size: statusSize, weight: .semibold))
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
