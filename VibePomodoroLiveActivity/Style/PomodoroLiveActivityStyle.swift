import SwiftUI
import UIKit

struct PomodoroLiveActivityPalette {
    func cardBackground(for phase: PomodoroActivityPhase) -> Color {
        let style = phase.activityStyle
        return Color(Self.dynamicColor(
            light: UIColor(style.lightBackground),
            dark: UIColor(style.darkBackground)
        ))
    }

    var primaryText: Color {
        Color(Self.dynamicColor(light: .black, dark: .white))
    }

    var secondaryText: Color {
        Color(Self.dynamicColor(
            light: UIColor.black.withAlphaComponent(0.62),
            dark: UIColor.white.withAlphaComponent(0.72)
        ))
    }

    var inactiveProgress: Color {
        Color(Self.dynamicColor(
            light: UIColor.black.withAlphaComponent(0.14),
            dark: UIColor.white.withAlphaComponent(0.22)
        ))
    }

    private static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

struct PomodoroPhaseActivityStyle {
    let accent: Color
    let deepAccent: Color
    let secondaryAccent: Color
    let lightBackground: Color
    let darkBackground: Color
}

extension PomodoroActivityPhase {
    var activityStyle: PomodoroPhaseActivityStyle {
        switch self {
        case .focus:
            return PomodoroPhaseActivityStyle(
                accent: Color(red: 0.85, green: 0.70, blue: 0.40),
                deepAccent: Color(red: 0.76, green: 0.58, blue: 0.25),
                secondaryAccent: Color(red: 0.62, green: 0.76, blue: 0.83),
                lightBackground: Color(red: 0.99, green: 0.97, blue: 0.92),
                darkBackground: Color(red: 0.055, green: 0.052, blue: 0.046)
            )
        case .shortBreak:
            return PomodoroPhaseActivityStyle(
                accent: Color(red: 0.71, green: 0.82, blue: 0.90),
                deepAccent: Color(red: 0.52, green: 0.65, blue: 0.75),
                secondaryAccent: Color(red: 0.78, green: 0.85, blue: 0.72),
                lightBackground: Color(red: 0.94, green: 0.97, blue: 0.99),
                darkBackground: Color(red: 0.045, green: 0.052, blue: 0.058)
            )
        case .longBreak:
            return PomodoroPhaseActivityStyle(
                accent: Color(red: 0.66, green: 0.80, blue: 0.74),
                deepAccent: Color(red: 0.48, green: 0.66, blue: 0.60),
                secondaryAccent: Color(red: 0.82, green: 0.76, blue: 0.90),
                lightBackground: Color(red: 0.94, green: 0.98, blue: 0.95),
                darkBackground: Color(red: 0.045, green: 0.056, blue: 0.050)
            )
        }
    }
}
