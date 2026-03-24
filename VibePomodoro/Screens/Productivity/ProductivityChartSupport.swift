import CoreGraphics
import Foundation

enum ProductivityValueFormatting {
    static func compactDurationText(_ duration: TimeInterval) -> String {
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

    static func summarySessionTimeText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let totalHours = totalSeconds / 3600
        let totalMinutes = totalSeconds / 60
        let days = totalHours / 24
        let hours = totalHours % 24
        let minutes = totalMinutes % 60

        if days >= 100 {
            return "\(days)d"
        }
        if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        }
        if totalHours > 0 {
            return minutes > 0 ? "\(totalHours)h \(minutes)m" : "\(totalHours)h"
        }
        return "\(totalMinutes)m"
    }

    static func summarySessionTimeAccessibilityValue(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let totalHours = totalSeconds / 3600
        let totalMinutes = totalSeconds / 60
        let days = totalHours / 24
        let hours = totalHours % 24
        let minutes = totalMinutes % 60

        if days >= 100 {
            return dayUnitText(days)
        }
        if days > 0 {
            return hours > 0 ? "\(dayUnitText(days)) \(hourUnitText(hours))" : dayUnitText(days)
        }
        if totalHours > 0 {
            return minutes > 0 ? "\(hourUnitText(totalHours)) \(minuteUnitText(minutes))" : hourUnitText(totalHours)
        }
        return minuteUnitText(totalMinutes)
    }

    static func summaryAverageFocusText(_ hoursPerDay: Double) -> String {
        let totalMinutes = max(0, Int((hoursPerDay * 60).rounded()))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(totalMinutes)m"
    }

    static func summaryAverageFocusAccessibilityValue(_ hoursPerDay: Double) -> String {
        let totalMinutes = max(0, Int((hoursPerDay * 60).rounded()))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return minutes > 0 ? "\(hourUnitText(hours)) \(minuteUnitText(minutes))" : hourUnitText(hours)
        }
        return minuteUnitText(totalMinutes)
    }

    static func summaryAverageFocusActiveDayAccessibilityValue(_ hoursPerDay: Double) -> String {
        "\(summaryAverageFocusAccessibilityValue(hoursPerDay)) average focus time across active days"
    }

    static func summaryStreakText(_ streakLength: Int) -> String {
        "\(max(0, streakLength))d"
    }

    static func summaryStreakAccessibilityValue(_ streakLength: Int) -> String {
        dayUnitText(max(0, streakLength))
    }

    private static func dayUnitText(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    private static func hourUnitText(_ count: Int) -> String {
        count == 1 ? "1 hour" : "\(count) hours"
    }

    private static func minuteUnitText(_ count: Int) -> String {
        count == 1 ? "1 minute" : "\(count) minutes"
    }
}

struct ProductivityDisplayBucket: Identifiable, Equatable {
    let slotIndex: Int
    let startDate: Date
    let endDate: Date
    let xDate: Date
    let labelDate: Date
    let focusTime: TimeInterval
    let breakTime: TimeInterval
    let completedFocusCount: Int

    var id: Date { xDate }
    var slotValue: Double { Double(slotIndex) }
}

struct ProductivityNumericAxisStyle: Equatable {
    let step: Double
    let upperBound: Double

    var values: [Double] {
        let count = max(1, Int((upperBound / step).rounded()))
        return (0...count).map { Double($0) * step }
    }
}

enum ProductivityChartDisplay {
    private static let calendar = Calendar.autoupdatingCurrent

    static func displayBuckets(from points: [ProductivityChartPoint], range: ProductivityRange) -> [ProductivityDisplayBucket] {
        let sortedPoints = points.sorted { $0.startDate < $1.startDate }
        let unslottedBuckets: [ProductivityDisplayBucket]

        switch range {
        case .week:
            unslottedBuckets = sortedPoints.compactMap { point in
                makeBucket(
                    startDate: point.startDate,
                    endDate: calendar.date(byAdding: .day, value: 1, to: point.startDate),
                    labelDate: point.startDate,
                    focusTime: point.focusTime,
                    breakTime: point.breakTime,
                    completedFocusCount: point.completedFocusCount
                )
            }
        case .month:
            unslottedBuckets = stride(from: 0, to: sortedPoints.count, by: 7).compactMap { startIndex in
                let endIndex = min(startIndex + 7, sortedPoints.count)
                let chunk = Array(sortedPoints[startIndex..<endIndex])
                guard let first = chunk.first else { return nil }
                let endDate = calendar.date(byAdding: .day, value: chunk.count, to: first.startDate)

                return makeBucket(
                    startDate: first.startDate,
                    endDate: endDate,
                    labelDate: first.startDate,
                    focusTime: chunk.reduce(0) { $0 + $1.focusTime },
                    breakTime: chunk.reduce(0) { $0 + $1.breakTime },
                    completedFocusCount: chunk.reduce(0) { $0 + $1.completedFocusCount }
                )
            }
        case .year:
            unslottedBuckets = sortedPoints.compactMap { point in
                makeBucket(
                    startDate: point.startDate,
                    endDate: calendar.date(byAdding: .month, value: 1, to: point.startDate),
                    labelDate: point.startDate,
                    focusTime: point.focusTime,
                    breakTime: point.breakTime,
                    completedFocusCount: point.completedFocusCount
                )
            }
        }

        return unslottedBuckets.enumerated().map { index, bucket in
            ProductivityDisplayBucket(
                slotIndex: index,
                startDate: bucket.startDate,
                endDate: bucket.endDate,
                xDate: bucket.xDate,
                labelDate: bucket.labelDate,
                focusTime: bucket.focusTime,
                breakTime: bucket.breakTime,
                completedFocusCount: bucket.completedFocusCount
            )
        }
    }

    private static func makeBucket(
        startDate: Date,
        endDate: Date?,
        labelDate: Date,
        focusTime: TimeInterval,
        breakTime: TimeInterval,
        completedFocusCount: Int
    ) -> ProductivityDisplayBucket? {
        guard let endDate else { return nil }
        let midpoint = startDate.addingTimeInterval(endDate.timeIntervalSince(startDate) / 2)

        return ProductivityDisplayBucket(
            slotIndex: 0,
            startDate: startDate,
            endDate: endDate,
            xDate: midpoint,
            labelDate: labelDate,
            focusTime: focusTime,
            breakTime: breakTime,
            completedFocusCount: completedFocusCount
        )
    }
}

enum ProductivityChartFormatting {
    private static let englishLocale = Locale(identifier: "en_US_POSIX")
    private static let englishMonthSymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = englishLocale
        return formatter.shortMonthSymbols
    }()

    static func xAxisLabel(for date: Date, range: ProductivityRange) -> String {
        switch range {
        case .week:
            return date.formatted(.dateTime.weekday(.abbreviated))
        case .month:
            return monthAxisLabel(for: date)
        case .year:
            return yearAxisLabel(for: date)
        }
    }

    static func monthAxisLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = englishLocale
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    static func yearAxisLabel(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let month = calendar.component(.month, from: date)
        guard month > 0, month <= englishMonthSymbols.count else { return "" }
        return String(englishMonthSymbols[month - 1].prefix(1))
    }

    static func axisDurationText(_ value: Double) -> String {
        let totalMinutes = Int((max(0, value) / 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(totalMinutes)m"
    }

    static func annotationDurationText(_ value: Double) -> String {
        let totalSeconds = max(0, Int(value.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "\(seconds)s"
    }

    static func timeAxisStyle(for maxValue: Double) -> ProductivityNumericAxisStyle {
        let step: Double

        switch maxValue {
        case ..<3600:
            step = 20 * 60
        case ..<7200:
            step = 40 * 60
        default:
            step = 60 * 60
        }

        let upperBound = max(step * 3, ceil(maxValue / step) * step)
        return ProductivityNumericAxisStyle(step: step, upperBound: upperBound)
    }
}

extension ProductivityRange {
    var displayTitle: String {
        switch self {
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .year:
            return "Year"
        }
    }

    var barWidth: CGFloat {
        switch self {
        case .week:
            return 18
        case .month:
            return 26
        case .year:
            return 15
        }
    }

    var barTopCornerRadius: CGFloat {
        switch self {
        case .week:
            return 4
        case .month:
            return 3
        case .year:
            return 2
        }
    }

    var annotationFontSize: CGFloat {
        switch self {
        case .week:
            return 10
        case .month:
            return 9
        case .year:
            return 10
        }
    }

    var annotationBottomPadding: CGFloat {
        switch self {
        case .week:
            return 2
        case .month:
            return 1
        case .year:
            return 2
        }
    }
}
