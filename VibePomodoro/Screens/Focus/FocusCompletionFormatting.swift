import Foundation

enum FocusCompletionFormatting {
    static func durationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "\(seconds)s"
    }

    static func accessibilityDurationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hourText(hours)) \(minuteText(minutes))"
            }
            return hourText(hours)
        }
        if minutes > 0 {
            if seconds > 0 {
                return "\(minuteText(minutes)) \(secondText(seconds))"
            }
            return minuteText(minutes)
        }
        return secondText(seconds)
    }

    private static func hourText(_ count: Int) -> String {
        count == 1 ? "1 hour" : "\(count) hours"
    }

    private static func minuteText(_ count: Int) -> String {
        count == 1 ? "1 minute" : "\(count) minutes"
    }

    private static func secondText(_ count: Int) -> String {
        count == 1 ? "1 second" : "\(count) seconds"
    }
}
