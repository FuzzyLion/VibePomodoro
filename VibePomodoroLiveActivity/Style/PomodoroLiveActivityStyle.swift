import SwiftUI
import UIKit

struct PomodoroLiveActivityPalette {
    var cardBackground: Color {
        Color(Self.dynamicColor(light: .white, dark: .black))
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
}

extension PomodoroActivityPhase {
    var activityStyle: PomodoroPhaseActivityStyle {
        switch self {
        case .focus:
            return PomodoroPhaseActivityStyle(
                accent: Color(red: 0.85, green: 0.70, blue: 0.40),
                deepAccent: Color(red: 0.76, green: 0.58, blue: 0.25)
            )
        case .shortBreak:
            return PomodoroPhaseActivityStyle(
                accent: Color(red: 0.71, green: 0.82, blue: 0.90),
                deepAccent: Color(red: 0.52, green: 0.65, blue: 0.75)
            )
        case .longBreak:
            return PomodoroPhaseActivityStyle(
                accent: Color(red: 0.66, green: 0.80, blue: 0.74),
                deepAccent: Color(red: 0.48, green: 0.66, blue: 0.60)
            )
        }
    }
}
