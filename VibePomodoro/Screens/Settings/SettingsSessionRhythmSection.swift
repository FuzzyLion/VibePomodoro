import SwiftUI

struct SettingsSessionRhythmSection: View {
    static let expandFocusPickerArgument = "--expand-focus-settings-picker"

    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedField = Self.initialExpandedField()

    private let timerFields = SettingsTimerField.allCases

    private static func initialExpandedField() -> SettingsTimerField? {
        if ProcessInfo.processInfo.arguments.contains(expandFocusPickerArgument) {
            return .focus
        }

        return nil
    }

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
        SettingsExpandablePickerRow(
            indicator: field.indicator,
            title: field.title,
            valueText: field.valueText(in: store.settings),
            accessibilityValue: field.accessibilityValue(in: store.settings),
            allowedValues: field.allowedValues,
            selectedValue: binding(for: field),
            textForValue: field.pickerText(for:),
            isExpanded: expandedField == field,
            rowAccessibilityIdentifier: "settings.sessionRhythm.\(field.id)",
            pickerAccessibilityIdentifier: "settings.sessionRhythm.\(field.id).picker",
            toggleExpansion: {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                    expandedField = expandedField == field ? nil : field
                }
            }
        )
    }

    private func binding(for field: SettingsTimerField) -> Binding<Int> {
        Binding(
            get: {
                field.value(in: store.settings)
            },
            set: { newValue in
                updateTimerField(field, value: newValue)
            }
        )
    }

    private func updateTimerField(_ field: SettingsTimerField, value: Int) {
        guard field.allowedValues.contains(value) else { return }

        switch field {
        case .focus:
            store.updateFocusMinutes(value)
        case .shortBreak:
            store.updateShortBreakMinutes(value)
        case .longBreak:
            store.updateLongBreakMinutes(value)
        case .rounds:
            store.updateTargetRounds(value)
        }
    }
}

private struct SettingsExpandablePickerRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let indicator: SettingsIndicator
    let title: String
    let valueText: String
    let accessibilityValue: String
    let allowedValues: [Int]
    @Binding var selectedValue: Int
    let textForValue: (Int) -> String
    let isExpanded: Bool
    let rowAccessibilityIdentifier: String
    let pickerAccessibilityIdentifier: String
    let toggleExpansion: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: toggleExpansion) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 12) {
                            label
                            valueDisclosure
                        }
                    } else {
                        HStack(spacing: 12) {
                            label
                            Spacer(minLength: 8)
                            valueDisclosure
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(isExpanded ? "Collapse picker" : "Expand picker")
            .accessibilityIdentifier(rowAccessibilityIdentifier)

            if isExpanded {
                picker
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                    ))
            }
        }
        .padding(.vertical, SettingsLayout.pickerRowVerticalPadding)
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

    private var valueDisclosure: some View {
        HStack(spacing: 8) {
            Text(valueText)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(SettingsTheme.primaryTextColor(for: colorScheme))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.88)
                .frame(minWidth: SettingsLayout.pickerValueMinWidth)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SettingsTheme.secondaryTextColor(for: colorScheme).opacity(0.48))
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .frame(height: SettingsLayout.pickerValuePillHeight)
        .glassEffect(.regular.tint(SettingsTheme.valuePillFill(for: colorScheme)).interactive(), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(SettingsTheme.valuePillStroke(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.02 : 0.012), radius: 8, y: 3)
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

    private var picker: some View {
        Picker(title, selection: $selectedValue) {
            ForEach(allowedValues, id: \.self) { value in
                Text(textForValue(value))
                    .font(.system(.title2, weight: .semibold))
                    .monospacedDigit()
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .frame(height: SettingsLayout.expandedPickerHeight)
        .clipped()
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SettingsTheme.pickerFill(for: colorScheme))
                    .glassEffect(.regular.tint(SettingsTheme.pickerFill(for: colorScheme)), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(colorScheme == .dark ? 0.035 : 0.018),
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.018 : 0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SettingsTheme.pickerSelectionFill(for: colorScheme))
                    .frame(height: 42)
                    .padding(.horizontal, 16)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(SettingsTheme.pickerRecessStroke(for: colorScheme), lineWidth: 1)
        }
        .mask {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        }
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    SettingsTheme.pickerFill(for: colorScheme),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color.clear,
                    SettingsTheme.pickerFill(for: colorScheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
            .allowsHitTesting(false)
        }
        .accessibilityLabel("\(title) picker")
        .accessibilityIdentifier(pickerAccessibilityIdentifier)
    }
}
