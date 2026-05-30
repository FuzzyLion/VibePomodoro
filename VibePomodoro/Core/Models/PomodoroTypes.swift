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

    var detailTitle: String {
        switch self {
        case .focus:
            return "Focus Session"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    var systemImage: String {
        switch self {
        case .focus:
            return "timer"
        case .shortBreak:
            return "cup.and.saucer"
        case .longBreak:
            return "sparkles"
        }
    }
}

enum SessionRunState: String, Codable {
    case idle
    case running
    case paused
    case completed
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

    var focusDuration: TimeInterval { TimeInterval(focusMinutes * 60) }
    var shortBreakDuration: TimeInterval { TimeInterval(shortBreakMinutes * 60) }
    var longBreakDuration: TimeInterval { TimeInterval(longBreakMinutes * 60) }

    static let `default` = PomodoroSettings()
}
