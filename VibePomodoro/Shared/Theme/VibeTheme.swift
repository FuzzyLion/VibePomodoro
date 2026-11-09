import SwiftUI

enum VibePalette {
    static let amberGold = Color(red: 0.85, green: 0.70, blue: 0.40)
    static let amberGoldDeep = Color(red: 0.76, green: 0.58, blue: 0.25)
    static let warmAmberAccent = Color(red: 0.70, green: 0.55, blue: 0.31)
    static let warmAmberAccentDeep = Color(red: 0.58, green: 0.44, blue: 0.24)
    static let softMist = Color(red: 0.71, green: 0.82, blue: 0.90)
    static let softMistDeep = Color(red: 0.52, green: 0.65, blue: 0.75)
    static let softJade = Color(red: 0.66, green: 0.80, blue: 0.74)
    static let softJadeDeep = Color(red: 0.48, green: 0.66, blue: 0.60)

    /// Amber for light-mode text, deep enough for 4.5:1 on the light cards.
    static let amberGoldInk = Color(red: 0.50, green: 0.38, blue: 0.17)

    static let warmBackground = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let mistBackground = Color(red: 0.93, green: 0.93, blue: 0.95)
    static let darkBackground = Color(red: 0.08, green: 0.09, blue: 0.11)
    static let darkSurface = Color(red: 0.13, green: 0.14, blue: 0.17)

    static let focusTint = amberGold
    static let labelPrimary = Color(red: 0.24, green: 0.24, blue: 0.27)
    static let labelSecondary = Color(red: 0.46, green: 0.46, blue: 0.50)
}

extension SessionPhase {
    var tintColor: Color {
        switch self {
        case .focus:
            return VibePalette.amberGold
        case .shortBreak:
            return VibePalette.softMist
        case .longBreak:
            return VibePalette.softJade
        }
    }

    var glassTint: Color {
        switch self {
        case .focus:
            return VibePalette.amberGold.opacity(0.14)
        case .shortBreak:
            return VibePalette.softMist.opacity(0.16)
        case .longBreak:
            return VibePalette.softJade.opacity(0.14)
        }
    }

    var shadowColor: Color {
        switch self {
        case .focus:
            return VibePalette.amberGoldDeep
        case .shortBreak:
            return VibePalette.softMistDeep
        case .longBreak:
            return VibePalette.softJadeDeep
        }
    }
}
