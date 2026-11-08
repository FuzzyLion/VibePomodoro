import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case focus
    case productivity
    case settings

    var id: String { rawValue }
}

enum SessionPhase: String, Codable, CaseIterable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus:
            return "Focus"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
}

enum SessionRunState: String, Codable {
    case idle
    case running
    case paused
    case completed
}

enum PomodoroAppearanceMode: String, Codable, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "Follow System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }
}

struct PomodoroSettings: Codable, Equatable {
    var focusMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var targetRounds: Int = 4

    var keepScreenOn: Bool = true
    var notificationsEnabled: Bool = true
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true

    var appearanceMode: PomodoroAppearanceMode = .system

    var focusDuration: TimeInterval { TimeInterval(focusMinutes * 60) }
    var shortBreakDuration: TimeInterval { TimeInterval(shortBreakMinutes * 60) }
    var longBreakDuration: TimeInterval { TimeInterval(longBreakMinutes * 60) }

    static let `default` = PomodoroSettings()

    init(
        focusMinutes: Int = 25,
        shortBreakMinutes: Int = 5,
        longBreakMinutes: Int = 15,
        targetRounds: Int = 4,
        keepScreenOn: Bool = true,
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        appearanceMode: PomodoroAppearanceMode = .system
    ) {
        self.focusMinutes = focusMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.targetRounds = targetRounds
        self.keepScreenOn = keepScreenOn
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.appearanceMode = appearanceMode
    }

    private enum CodingKeys: String, CodingKey {
        case focusMinutes
        case shortBreakMinutes
        case longBreakMinutes
        case targetRounds
        case keepScreenOn
        case notificationsEnabled
        case soundEnabled
        case hapticsEnabled
        case appearanceMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.focusMinutes = try container.decodeIfPresent(Int.self, forKey: .focusMinutes) ?? 25
        self.shortBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .shortBreakMinutes) ?? 5
        self.longBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .longBreakMinutes) ?? 15
        self.targetRounds = try container.decodeIfPresent(Int.self, forKey: .targetRounds) ?? 4
        self.keepScreenOn = try container.decodeIfPresent(Bool.self, forKey: .keepScreenOn) ?? true
        self.notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        self.soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        self.hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        self.appearanceMode = try container.decodeIfPresent(PomodoroAppearanceMode.self, forKey: .appearanceMode) ?? .system
    }
}
