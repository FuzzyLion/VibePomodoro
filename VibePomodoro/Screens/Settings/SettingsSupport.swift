import SwiftUI

enum SettingsLayout {
    static let pageHorizontalInset: CGFloat = 18
    static let pageTopInset: CGFloat = 12
    static let pageBottomInset: CGFloat = 60
    static let pageSectionSpacing: CGFloat = 28
    static let cardContentInset: CGFloat = 20
    static let cardVerticalInset: CGFloat = 4
    static let summaryCardTopInset: CGFloat = 20
    static let summaryCardBottomInset: CGFloat = cardVerticalInset
    static let summaryCardCornerRadius: CGFloat = 28
    static let secondaryCardCornerRadius: CGFloat = 26
    static let rowVerticalPadding: CGFloat = 14
    static let pickerRowVerticalPadding: CGFloat = 16
    static let expandedPickerHeight: CGFloat = 128
    static let expandedPickerTopSpacing: CGFloat = 12
    static let expandedPickerDrawerHeight: CGFloat = expandedPickerTopSpacing + expandedPickerHeight
    static let pickerCornerRadius: CGFloat = 24
    static let pickerFadeHeight: CGFloat = 28
    static let pickerValuePillHeight: CGFloat = 36
    static let pickerValueMinWidth: CGFloat = 86
    static let sectionTitleTracking: CGFloat = 1.0
    static let cardHeaderBottomSpacing: CGFloat = 12
    static let sectionHeaderBottomSpacing: CGFloat = 8
}

enum SettingsIndicator {
    case dot(Color)
    case symbol(String, Color)
}

/// What the Alerts card shows, given the in-app switch and what iOS allows.
struct SettingsAlertsPresentation: Equatable {
    static let blockedNotificationsDetail = "Off in iOS Settings"
    static let inAppSoundDetail = "Only while the app is open"

    /// The switch is on but iOS blocks delivery, so the row links to iOS Settings instead.
    let opensSystemSettings: Bool
    /// Sound also plays inside the app, so it stays adjustable. Without notifications it can't reach
    /// the lock screen, and this says so.
    let soundDetail: String?

    init(notificationsEnabled: Bool, permission: NotificationPermission) {
        let canNotify = notificationsEnabled && permission != .denied
        opensSystemSettings = notificationsEnabled && permission == .denied
        soundDetail = canNotify ? nil : Self.inAppSoundDetail
    }
}

/// Text colors keep at least 4.5:1 on iOS 27, whose default glass draws the dark cards lighter than
/// iOS 26 did (about RGB 78 instead of 49), and turn stronger when Increase Contrast is on.
enum SettingsTheme {
    static func primaryTextColor(for colorScheme: ColorScheme) -> ContrastAdaptiveColor {
        colorScheme == .dark
            ? ContrastAdaptiveColor(VibePalette.warmBackground.opacity(0.96), increased: VibePalette.warmBackground)
            : ContrastAdaptiveColor(Color.black.opacity(0.78), increased: Color.black.opacity(0.9))
    }

    static func secondaryTextColor(for colorScheme: ColorScheme) -> ContrastAdaptiveColor {
        colorScheme == .dark
            ? ContrastAdaptiveColor(VibePalette.warmBackground.opacity(0.76), increased: VibePalette.warmBackground.opacity(0.9))
            : ContrastAdaptiveColor(Color.black.opacity(0.58), increased: Color.black.opacity(0.72))
    }

    static func sectionLabelColor(for colorScheme: ColorScheme) -> ContrastAdaptiveColor {
        colorScheme == .dark
            ? ContrastAdaptiveColor(VibePalette.warmBackground.opacity(0.74), increased: VibePalette.warmBackground.opacity(0.88))
            : ContrastAdaptiveColor(Color.black.opacity(0.58), increased: Color.black.opacity(0.72))
    }

    static func sectionAccentColor(for colorScheme: ColorScheme) -> ContrastAdaptiveColor {
        VibePalette.amberText(for: colorScheme)
    }

    /// Clear Productivity History. Softer than system red in dark mode, which stays near 2.4:1 on the
    /// frosted cards.
    static func destructiveTextColor(for colorScheme: ColorScheme) -> ContrastAdaptiveColor {
        colorScheme == .dark
            ? ContrastAdaptiveColor(Color(red: 1.0, green: 0.71, blue: 0.68), increased: Color(red: 1.0, green: 0.80, blue: 0.77))
            : ContrastAdaptiveColor(Color(red: 0.73, green: 0.23, blue: 0.21), increased: Color(red: 0.62, green: 0.15, blue: 0.13))
    }


    static func placeholderFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.035)
    }

    static func placeholderStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.24)
    }

    static func dividerColor(for colorScheme: ColorScheme) -> ContrastAdaptiveColor {
        colorScheme == .dark
            ? ContrastAdaptiveColor(Color.white.opacity(0.12), increased: Color.white.opacity(0.24))
            : ContrastAdaptiveColor(Color.black.opacity(0.08), increased: Color.black.opacity(0.18))
    }

    static func controlFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.045)
    }

    static func valuePillFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.18)
    }

    static func valuePillPressedFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.28)
    }

    static func pickerFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.035) : Color.white.opacity(0.16)
    }

    static func controlStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.22)
    }

    static func valuePillStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.30)
    }

    static func pickerRecessStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.26)
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

    func pickerText(for value: Int) -> String {
        switch self {
        case .rounds:
            return "\(value)"
        default:
            return "\(value) min"
        }
    }
}
