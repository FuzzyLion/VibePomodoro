import SwiftUI

enum SettingsLayout {
    static let pageHorizontalInset: CGFloat = 18
    static let pageTopInset: CGFloat = 12
    static let pageBottomInset: CGFloat = 28
    static let pageSectionSpacing: CGFloat = 28
    static let cardContentInset: CGFloat = 20
    static let cardVerticalInset: CGFloat = 4
    static let summaryCardTopInset: CGFloat = 20
    static let summaryCardBottomInset: CGFloat = cardVerticalInset
    static let summaryCardCornerRadius: CGFloat = 28
    static let secondaryCardCornerRadius: CGFloat = 26
    static let rowVerticalPadding: CGFloat = 14
    static let controlPillHeight: CGFloat = 44
    static let controlButtonWidth: CGFloat = 44
    static let controlValueWidth: CGFloat = 58
    static let controlValueHorizontalPadding: CGFloat = 8
    static let sectionTitleTracking: CGFloat = 1.0
    static let cardHeaderBottomSpacing: CGFloat = 12
    static let sectionHeaderBottomSpacing: CGFloat = 8
}

enum SettingsAdjustmentDirection {
    case decrement
    case increment
}

enum SettingsIndicator {
    case dot(Color)
    case symbol(String, Color)
}

enum SettingsTheme {
    static func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.96) : Color.black.opacity(0.78)
    }

    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.68) : Color.black.opacity(0.50)
    }

    static func sectionLabelColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.64) : Color.black.opacity(0.45)
    }

    static func sectionAccentColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? VibePalette.warmAmberAccent.opacity(0.88)
            : VibePalette.warmAmberAccentDeep.opacity(0.92)
    }

    static func placeholderFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.035)
    }

    static func placeholderStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.24)
    }

    static func dividerColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    static func controlFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.045)
    }

    static func controlStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.22)
    }
}

enum SettingsTimerField: String, CaseIterable, Identifiable {
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
            // Temporary QA hook: keep a 1 minute focus option available for transition testing.
            return [1] + Array(stride(from: 15, through: 90, by: 5))
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
