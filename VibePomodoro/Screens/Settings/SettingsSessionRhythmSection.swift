import SwiftUI

struct SettingsSessionRhythmSection: View {
    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.colorScheme) private var colorScheme

    private let timerFields = SettingsTimerField.allCases

    var body: some View {
        SettingsCard(
            style: .summary(
                contentInset: SettingsLayout.cardContentInset,
                cornerRadius: SettingsLayout.summaryCardCornerRadius
            ),
            topInset: SettingsLayout.summaryCardTopInset,
            bottomInset: SettingsLayout.summaryCardBottomInset,
            accentOverlay: {
                LinearGradient(
                    colors: [
                        VibePalette.focusTint.opacity(colorScheme == .dark ? 0.04 : 0.016),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        ) {
            SettingsCardHeader(
                title: "SESSION RHYTHM",
                trailingText: "Next session only"
            )

            VStack(spacing: 0) {
                ForEach(Array(timerFields.enumerated()), id: \.element.id) { index, field in
                    timerRow(for: field)

                    if index < timerFields.count - 1 {
                        SettingsDivider()
                    }
                }
            }
        }
    }

    private func timerRow(for field: SettingsTimerField) -> some View {
        SettingsStepperRow(
            indicator: field.indicator,
            title: field.title,
            valueText: field.valueText(in: store.settings),
            accessibilityValue: field.accessibilityValue(in: store.settings),
            onDecrement: { updateTimerField(field, direction: .decrement) },
            onIncrement: { updateTimerField(field, direction: .increment) },
            canDecrement: field.canAdjust(in: store.settings, direction: .decrement),
            canIncrement: field.canAdjust(in: store.settings, direction: .increment),
            decrementLabel: "Decrease \(field.title.lowercased())",
            incrementLabel: "Increase \(field.title.lowercased())"
        )
    }

    private func updateTimerField(_ field: SettingsTimerField, direction: SettingsAdjustmentDirection) {
        let updatedValue = field.adjustedValue(in: store.settings, direction: direction)

        switch field {
        case .focus:
            store.updateFocusMinutes(updatedValue)
        case .shortBreak:
            store.updateShortBreakMinutes(updatedValue)
        case .longBreak:
            store.updateLongBreakMinutes(updatedValue)
        case .rounds:
            store.updateTargetRounds(updatedValue)
        }
    }
}

private struct SettingsStepperRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let indicator: SettingsIndicator
    let title: String
    let valueText: String
    let accessibilityValue: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let canDecrement: Bool
    let canIncrement: Bool
    let decrementLabel: String
    let incrementLabel: String

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    label
                    controlPill
                }
            } else {
                HStack(spacing: 12) {
                    label
                    Spacer(minLength: 8)
                    controlPill
                }
            }
        }
        .padding(.vertical, SettingsLayout.rowVerticalPadding)
        .accessibilityElement(children: .contain)
    }

    private var label: some View {
        HStack(spacing: 12) {
            indicatorView

            Text(title)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
                .lineLimit(1)
                .layoutPriority(1)
                .minimumScaleFactor(0.94)
        }
    }

    private var controlPill: some View {
        HStack(spacing: 0) {
            button(
                systemImage: "minus",
                action: onDecrement,
                disabled: !canDecrement,
                accessibilityLabel: decrementLabel
            )

            Text(valueText)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
                .monospacedDigit()
                .frame(width: SettingsLayout.controlValueWidth)
                .padding(.horizontal, SettingsLayout.controlValueHorizontalPadding)
                .accessibilityLabel(title)
                .accessibilityValue(accessibilityValue)

            button(
                systemImage: "plus",
                action: onIncrement,
                disabled: !canIncrement,
                accessibilityLabel: incrementLabel
            )
        }
        .frame(height: SettingsLayout.controlPillHeight)
        .background(
            Capsule(style: .continuous)
                .fill(SettingsTheme.controlFill(for: colorScheme))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(SettingsTheme.controlStroke(for: colorScheme), lineWidth: 1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private var indicatorView: some View {
        switch indicator {
        case let .dot(color):
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
        case let .symbol(systemName, color):
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 12, height: 12)
        }
    }

    private func button(
        systemImage: String,
        action: @escaping () -> Void,
        disabled: Bool,
        accessibilityLabel: String
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(
                    disabled
                        ? SettingsTheme.secondaryTextColor(for: colorScheme).opacity(0.5)
                        : SettingsTheme.primaryTextColor(for: colorScheme)
                )
                .frame(width: SettingsLayout.controlButtonWidth, height: SettingsLayout.controlPillHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(accessibilityLabel)
    }
}
