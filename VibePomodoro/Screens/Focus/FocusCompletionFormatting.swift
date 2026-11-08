import Foundation

enum FocusCompletionFormatting {
    /// One number and its unit, such as 40 and "m".
    struct DurationPart: Equatable {
        let value: String
        let unit: String
    }

    static func durationText(_ duration: TimeInterval) -> String {
        durationParts(duration)
            .map { $0.value + $0.unit }
            .joined(separator: " ")
    }

    /// The duration as numbers with their units, for layouts that set the units smaller than the
    /// numbers: 1h 40m, 25m, or 45s.
    static func durationParts(_ duration: TimeInterval) -> [DurationPart] {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            let hourPart = DurationPart(value: "\(hours)", unit: "h")
            return minutes > 0 ? [hourPart, DurationPart(value: "\(minutes)", unit: "m")] : [hourPart]
        }
        if minutes > 0 {
            return [DurationPart(value: "\(minutes)", unit: "m")]
        }
        return [DurationPart(value: "\(seconds)", unit: "s")]
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
