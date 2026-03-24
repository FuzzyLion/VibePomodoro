import SwiftUI

private enum SettingsLayout {
    static let pageHorizontalInset: CGFloat = 18
    static let pageTopInset: CGFloat = 12
    static let pageBottomInset: CGFloat = 28
    static let pageSectionSpacing: CGFloat = 14
    static let cardContentInset: CGFloat = 18
    static let summaryCardCornerRadius: CGFloat = 28
    static let secondaryCardCornerRadius: CGFloat = 26
    static let cardSectionSpacing: CGFloat = 16
    static let rowVerticalPadding: CGFloat = 14
    static let controlPillHeight: CGFloat = 44
    static let controlButtonWidth: CGFloat = 44
    static let controlValueMinimumWidth: CGFloat = 58
}

private enum SettingsAdjustmentDirection {
    case decrement
    case increment
}

private enum SettingsTimerField: String, CaseIterable, Identifiable {
    case focus
    case shortBreak
    case longBreak
    case rounds

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus:
            return "Focus"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        case .rounds:
            return "Rounds"
        }
    }

    var accent: Color {
        switch self {
        case .focus:
            return VibePalette.focusTint
        case .shortBreak:
            return VibePalette.softMist
        case .longBreak:
            return VibePalette.softJade
        case .rounds:
            return VibePalette.warmAmberAccent
        }
    }

    var indicator: SettingsIndicator {
        switch self {
        case .rounds:
            return .symbol("repeat", accent)
        default:
            return .dot(accent)
        }
    }

    var allowedValues: [Int] {
        switch self {
        case .focus:
            return Array(stride(from: 15, through: 90, by: 5))
        case .shortBreak:
            return [5, 10]
        case .longBreak:
            return [15, 20, 30]
        case .rounds:
            return Array(1...10)
        }
    }

    var minimumValue: Int {
        allowedValues.first ?? 0
    }

    var maximumValue: Int {
        allowedValues.last ?? 0
    }

    func rawValue(in settings: PomodoroSettings) -> Int {
        switch self {
        case .focus:
            return settings.focusMinutes
        case .shortBreak:
            return settings.shortBreakMinutes
        case .longBreak:
            return settings.longBreakMinutes
        case .rounds:
            return settings.targetRounds
        }
    }

    func value(in settings: PomodoroSettings) -> Int {
        let currentValue = rawValue(in: settings)
        return allowedValues.min { lhs, rhs in
            let lhsDistance = abs(lhs - currentValue)
            let rhsDistance = abs(rhs - currentValue)

            if lhsDistance == rhsDistance {
                return lhs < rhs
            }

            return lhsDistance < rhsDistance
        } ?? minimumValue
    }

    func valueText(in settings: PomodoroSettings) -> String {
        let value = value(in: settings)
        switch self {
        case .rounds:
            return "\(value)"
        default:
            return "\(value) min"
        }
    }

    func accessibilityValue(in settings: PomodoroSettings) -> String {
        let value = value(in: settings)
        switch self {
        case .rounds:
            return value == 1 ? "1 round" : "\(value) rounds"
        default:
            return "\(value) minutes"
        }
    }

    func adjustedValue(in settings: PomodoroSettings, direction: SettingsAdjustmentDirection) -> Int {
        let currentValue = value(in: settings)
        guard let currentIndex = allowedValues.firstIndex(of: currentValue) else {
            return currentValue
        }

        switch direction {
        case .decrement:
            let previousIndex = max(allowedValues.startIndex, currentIndex - 1)
            return allowedValues[previousIndex]
        case .increment:
            let nextIndex = min(allowedValues.index(before: allowedValues.endIndex), currentIndex + 1)
            return allowedValues[nextIndex]
        }
    }

    func canAdjust(in settings: PomodoroSettings, direction: SettingsAdjustmentDirection) -> Bool {
        let currentValue = value(in: settings)
        switch direction {
        case .decrement:
            return currentValue > minimumValue
        case .increment:
            return currentValue < maximumValue
        }
    }
}

private enum SettingsIndicator {
    case dot(Color)
    case symbol(String, Color)
}

private func settingsPrimaryTextColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? VibePalette.warmBackground.opacity(0.96) : Color.black.opacity(0.78)
}

private func settingsSecondaryTextColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? VibePalette.warmBackground.opacity(0.68) : Color.black.opacity(0.50)
}

private func settingsSectionLabelColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? VibePalette.warmBackground.opacity(0.76) : Color.black.opacity(0.42)
}

private func settingsDividerColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
}

private func settingsControlFill(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.045)
}

private func settingsControlStroke(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.22)
}

struct SettingsScreen: View {
    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: SettingsLayout.pageSectionSpacing) {
                    sessionRhythmCard
                    alertsCard
                    displayCard
                    otherCard
                }
                .padding(.horizontal, SettingsLayout.pageHorizontalInset)
                .padding(.top, SettingsLayout.pageTopInset)
                .padding(.bottom, SettingsLayout.pageBottomInset)
            }
            .onAppear(perform: normalizeTimerSettingsIfNeeded)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var sessionRhythmCard: some View {
        SettingsCard(
            style: .summary(
                contentInset: SettingsLayout.cardContentInset,
                cornerRadius: SettingsLayout.summaryCardCornerRadius
            ),
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
                timerRow(for: .focus)
                rowDivider
                timerRow(for: .shortBreak)
                rowDivider
                timerRow(for: .longBreak)
                rowDivider
                timerRow(for: .rounds)
            }
        }
    }

    private var alertsCard: some View {
        SettingsCard(
            style: .trend(
                contentInset: SettingsLayout.cardContentInset,
                cornerRadius: SettingsLayout.secondaryCardCornerRadius
            ),
            accentOverlay: { EmptyView() }
        ) {
            SettingsCardHeader(title: "ALERTS")

            VStack(spacing: 0) {
                SettingsToggleRow(
                    isOn: Binding(
                        get: { store.settings.notificationsEnabled },
                        set: store.setNotificationsEnabled
                    ),
                    title: "Notifications"
                )

                rowDivider

                SettingsToggleRow(
                    isOn: Binding(
                        get: { store.settings.soundEnabled },
                        set: store.setSoundEnabled
                    ),
                    title: "Sound",
                    subtitle: store.settings.notificationsEnabled ? nil : "Requires Notifications",
                    disabled: !store.settings.notificationsEnabled
                )

                if store.settings.notificationsEnabled && store.settings.soundEnabled {
                    rowDivider

                    Menu {
                        Picker(
                            "Reminder Sound",
                            selection: Binding(
                                get: { store.settings.selectedSound },
                                set: store.setSelectedSound
                            )
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

                rowDivider

                SettingsToggleRow(
                    isOn: Binding(
                        get: { store.settings.hapticsEnabled },
                        set: store.setHapticsEnabled
                    ),
                    title: "Haptics"
                )
            }
        }
    }

    private var displayCard: some View {
        SettingsCard(
            style: .trend(
                contentInset: SettingsLayout.cardContentInset,
                cornerRadius: SettingsLayout.secondaryCardCornerRadius
            ),
            accentOverlay: { EmptyView() }
        ) {
            SettingsCardHeader(title: "DISPLAY")

            SettingsToggleRow(
                isOn: Binding(
                    get: { store.settings.keepScreenOn },
                    set: store.setKeepScreenOn
                ),
                title: "Keep Screen On",
                subtitle: "Active sessions only"
            )
        }
    }

    private var otherCard: some View {
        SettingsCard(
            style: .trend(
                contentInset: SettingsLayout.cardContentInset,
                cornerRadius: SettingsLayout.secondaryCardCornerRadius
            ),
            accentOverlay: { EmptyView() }
        ) {
            SettingsCardHeader(title: "OTHER")

            VStack(spacing: 0) {
                SettingsPlaceholderRow(title: "Send Feedback", status: "Soon")

                rowDivider

                SettingsPlaceholderRow(title: "Share App", status: "Soon")
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

    private func normalizeTimerSettingsIfNeeded() {
        let normalizedFocus = SettingsTimerField.focus.value(in: store.settings)
        if store.settings.focusMinutes != normalizedFocus {
            store.updateFocusMinutes(normalizedFocus, fireFeedback: false)
        }

        let normalizedShortBreak = SettingsTimerField.shortBreak.value(in: store.settings)
        if store.settings.shortBreakMinutes != normalizedShortBreak {
            store.updateShortBreakMinutes(normalizedShortBreak, fireFeedback: false)
        }

        let normalizedLongBreak = SettingsTimerField.longBreak.value(in: store.settings)
        if store.settings.longBreakMinutes != normalizedLongBreak {
            store.updateLongBreakMinutes(normalizedLongBreak, fireFeedback: false)
        }

        let normalizedRounds = SettingsTimerField.rounds.value(in: store.settings)
        if store.settings.targetRounds != normalizedRounds {
            store.updateTargetRounds(normalizedRounds, fireFeedback: false)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(settingsDividerColor(for: colorScheme))
            .frame(height: 1)
    }
}

private struct SettingsCard<Content: View, AccentOverlay: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let style: ProductivityCardChromeStyle
    let accentOverlay: AccentOverlay
    let content: Content

    init(
        style: ProductivityCardChromeStyle,
        @ViewBuilder accentOverlay: () -> AccentOverlay,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.accentOverlay = accentOverlay()
        self.content = content()
    }

    var body: some View {
        content
            .padding(SettingsLayout.cardContentInset)
            .productivityGlassCard(
                colorScheme: colorScheme,
                style: style
            ) {
                accentOverlay
            }
    }
}

private struct SettingsCardHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    var trailingText: String? = nil

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    titleLabel
                    if let trailingText {
                        trailingLabel(trailingText)
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    titleLabel
                    Spacer(minLength: 12)
                    if let trailingText {
                        trailingLabel(trailingText)
                    }
                }
            }
        }
        .padding(.bottom, 14)
    }

    private var titleLabel: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.6)
            .foregroundStyle(settingsSectionLabelColor(for: colorScheme))
    }

    private func trailingLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.footnote, weight: .semibold))
            .foregroundStyle(VibePalette.focusTint)
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
                HStack(spacing: 14) {
                    label
                    Spacer(minLength: 12)
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
                .foregroundStyle(settingsPrimaryTextColor(for: colorScheme))
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
                .foregroundStyle(settingsPrimaryTextColor(for: colorScheme))
                .monospacedDigit()
                .frame(minWidth: SettingsLayout.controlValueMinimumWidth)
                .padding(.horizontal, 12)
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
                .fill(settingsControlFill(for: colorScheme))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(settingsControlStroke(for: colorScheme), lineWidth: 1)
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
                        ? settingsSecondaryTextColor(for: colorScheme).opacity(0.5)
                        : settingsPrimaryTextColor(for: colorScheme)
                )
                .frame(width: SettingsLayout.controlButtonWidth, height: SettingsLayout.controlPillHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct SettingsToggleRow: View {
    @Binding var isOn: Bool

    let title: String
    var subtitle: String? = nil
    var disabled: Bool = false

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 4) {
                Text(title)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(.footnote, weight: .medium))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, SettingsLayout.rowVerticalPadding)
        }
        .tint(VibePalette.focusTint)
        .disabled(disabled)
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
            .foregroundStyle(settingsPrimaryTextColor(for: colorScheme))
    }

    private var valueLabel: some View {
        HStack(spacing: 10) {
            Text(value)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(settingsPrimaryTextColor(for: colorScheme))
                .multilineTextAlignment(.trailing)

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(settingsSecondaryTextColor(for: colorScheme))
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
            .foregroundStyle(settingsPrimaryTextColor(for: colorScheme))
    }

    private var statusLabel: some View {
        Text(status.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(settingsSecondaryTextColor(for: colorScheme))
    }
}
