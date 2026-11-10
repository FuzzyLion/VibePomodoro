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
        if minutes > 0 || seconds == 0 {
            return "\(minutes)m"
        }
        return "\(seconds)s"
    }

    /// Spelled out for VoiceOver: "1 hour 30 minutes".
    static func durationAccessibilityText(_ duration: TimeInterval) -> String {
        let totalMinutes = max(0, Int(duration.rounded())) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return minutes > 0 ? "\(hourUnitText(hours)) \(minuteUnitText(minutes))" : hourUnitText(hours)
        }
        return minuteUnitText(minutes)
    }

    /// Lifetime totals read in hours, never days, so they can't be mistaken for the streak.
    /// From 100 hours on, the minutes drop.
    static func lifetimeDurationText(_ duration: TimeInterval) -> String {
        let totalMinutes = max(0, Int(duration.rounded())) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours >= 100 || (hours > 0 && minutes == 0) {
            return "\(hours)h"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    static func lifetimeDurationAccessibilityValue(_ duration: TimeInterval) -> String {
        let totalMinutes = max(0, Int(duration.rounded())) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours >= 100 || (hours > 0 && minutes == 0) {
            return hourUnitText(hours)
        }
        if hours > 0 {
            return "\(hourUnitText(hours)) \(minuteUnitText(minutes))"
        }
        return minuteUnitText(minutes)
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

    /// The summary's footer, which carries Session Time now that Focus Time leads the card.
    static func summaryMetaText(sessionTime: TimeInterval, completedSessionCount: Int, completedFocusCount: Int) -> String {
        guard completedSessionCount > 0 else {
            return "No finished sessions yet"
        }

        return "\(lifetimeDurationText(sessionTime)) across \(sessionCountText(completedSessionCount)) • \(focusBlockCountText(completedFocusCount))"
    }

    static func summaryMetaAccessibilityText(sessionTime: TimeInterval, completedSessionCount: Int, completedFocusCount: Int) -> String {
        guard completedSessionCount > 0 else {
            return "No finished sessions yet"
        }

        return "\(lifetimeDurationAccessibilityValue(sessionTime)) across \(sessionCountText(completedSessionCount)), \(focusBlockCountText(completedFocusCount))"
    }

    static func sessionCountText(_ count: Int) -> String {
        count == 1 ? "1 session" : "\(count) sessions"
    }

    static func focusBlockCountText(_ count: Int) -> String {
        count == 1 ? "1 focus block" : "\(count) focus blocks"
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
    static let maximumIntervals: Double = 4

    let step: Double
    let upperBound: Double

    var values: [Double] {
        let count = max(1, Int((upperBound / step).rounded()))
        return (0...count).map { Double($0) * step }
    }

    /// Uses the first round step that covers `maxValue` in at most four intervals.
    static func fitting(_ maxValue: Double, minimumUpperBound: Double, steps: [Double]) -> Self {
        let target = max(maxValue, minimumUpperBound)
        let largestStep = steps.last ?? 1
        let step = steps.first { (target / $0).rounded(.up) <= maximumIntervals }
            ?? largestStep * (target / (largestStep * maximumIntervals)).rounded(.up)

        return Self(step: step, upperBound: (target / step).rounded(.up) * step)
    }
}

enum ProductivityChartDisplay {
    private static let calendar = Calendar.autoupdatingCurrent

    /// One slot per point: a day for Week and Month, a month for Year. Month keeps daily bars
    /// because 30 days never split into equal weeks, and a short group would read as a drop.
    static func displayBuckets(from points: [ProductivityChartPoint], range: ProductivityRange) -> [ProductivityDisplayBucket] {
        let bucketLength: Calendar.Component = range == .year ? .month : .day
        let unslottedBuckets = points
            .sorted { $0.startDate < $1.startDate }
            .compactMap { point in
                makeBucket(
                    startDate: point.startDate,
                    endDate: calendar.date(byAdding: bucketLength, value: 1, to: point.startDate),
                    labelDate: point.startDate,
                    focusTime: point.focusTime,
                    breakTime: point.breakTime,
                    completedFocusCount: point.completedFocusCount
                )
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

    /// The slot under a tap, `x` measured from the plot's leading edge.
    static func slotIndex(atX x: CGFloat, plotWidth: CGFloat, slotCount: Int) -> Int? {
        guard slotCount > 0, plotWidth > 0, x >= 0, x < plotWidth else { return nil }
        return min(slotCount - 1, Int(x / (plotWidth / CGFloat(slotCount))))
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
    private static let monthAxisFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = englishLocale
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    private static let weekAxisFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = englishLocale
        formatter.dateFormat = "EEE"
        return formatter
    }()
    private static let englishMonthSymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = englishLocale
        return formatter.shortMonthSymbols
    }()
    private static let dayFormatter = englishFormatter("d")
    private static let monthYearFormatter = englishFormatter("MMM yyyy")
    private static let selectedDayFormatter = englishFormatter("EEE d MMM")
    private static let spokenDayFormatter = englishFormatter("EEEE d MMMM")
    private static let spokenMonthFormatter = englishFormatter("MMMM yyyy")

    private static func englishFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = englishLocale
        formatter.dateFormat = format
        return formatter
    }

    /// The span the trend cards cover, such as "3–9 Nov", "11 Oct – 9 Nov", or "Dec 2025 – Nov 2026".
    static func rangeDatesText(
        for buckets: [ProductivityDisplayBucket],
        range: ProductivityRange,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        guard let first = buckets.first?.startDate, let last = buckets.last?.startDate else { return "" }

        switch range {
        case .week, .month:
            return dayRangeText(from: first, to: last, calendar: calendar)
        case .year:
            return "\(monthYearFormatter.string(from: first)) – \(monthYearFormatter.string(from: last))"
        }
    }

    /// The day or month a tapped bar stands for. The month in progress names the days it covers so far.
    static func selectionText(
        for bucket: ProductivityDisplayBucket,
        range: ProductivityRange,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        switch range {
        case .week, .month:
            return selectedDayFormatter.string(from: bucket.startDate)
        case .year:
            guard bucket.endDate > now else { return monthYearFormatter.string(from: bucket.startDate) }
            return dayRangeText(from: bucket.startDate, to: now, calendar: calendar)
        }
    }

    static func selectionAccessibilityText(
        for bucket: ProductivityDisplayBucket,
        range: ProductivityRange,
        now: Date = .now
    ) -> String {
        switch range {
        case .week, .month:
            return spokenDayFormatter.string(from: bucket.startDate)
        case .year:
            let month = spokenMonthFormatter.string(from: bucket.startDate)
            return bucket.endDate > now ? "\(month) so far" : month
        }
    }

    private static func dayRangeText(from start: Date, to end: Date, calendar: Calendar) -> String {
        if calendar.isDate(start, inSameDayAs: end) {
            return monthAxisFormatter.string(from: end)
        }
        if calendar.isDate(start, equalTo: end, toGranularity: .month) {
            return "\(dayFormatter.string(from: start))–\(monthAxisFormatter.string(from: end))"
        }
        return "\(monthAxisFormatter.string(from: start)) – \(monthAxisFormatter.string(from: end))"
    }

    static func xAxisLabel(for date: Date, range: ProductivityRange) -> String {
        switch range {
        case .week:
            return weekAxisLabel(for: date)
        case .month:
            return monthAxisLabel(for: date)
        case .year:
            return yearAxisLabel(for: date)
        }
    }

    static func monthAxisLabel(for date: Date) -> String {
        monthAxisFormatter.string(from: date)
    }

    static func weekAxisLabel(for date: Date) -> String {
        weekAxisFormatter.string(from: date)
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

        if totalMinutes == 0 {
            return "0"
        }
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(totalMinutes)m"
    }

    private static let hourAxisSteps: [TimeInterval] = [1, 2, 3, 4, 5, 10, 15, 20, 25, 50, 100, 150, 200, 250, 500, 1_000]
        .map { $0 * 3_600 }

    /// Up to an hour the axis stays at 0–60m in 20-minute steps. Above that it uses whole hours,
    /// so no label needs minutes, and at most four intervals however long the bucket is.
    static func timeAxisStyle(for maxValue: Double) -> ProductivityNumericAxisStyle {
        guard maxValue > 3_600 else {
            return ProductivityNumericAxisStyle(step: 20 * 60, upperBound: 3_600)
        }

        return .fitting(maxValue, minimumUpperBound: 3_600, steps: hourAxisSteps)
    }

    private static let sessionTimeFormatter = englishFormatter("HH:mm")
    private static let sessionDayFormatter = englishFormatter("EEE d MMM")

    /// A session's start: "Today 08:30", "Yesterday 14:00", or "Sat 7 Nov 09:00".
    static func sessionStartText(
        _ start: Date,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        "\(relativeDayText(start, now: now, calendar: calendar) ?? sessionDayFormatter.string(from: start))\u{2002}\(sessionTimeFormatter.string(from: start))"
    }

    static func sessionStartAccessibilityText(
        _ start: Date,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        "\(relativeDayText(start, now: now, calendar: calendar) ?? spokenDayFormatter.string(from: start)) at \(sessionTimeFormatter.string(from: start))"
    }

    private static func relativeDayText(_ date: Date, now: Date, calendar: Calendar) -> String? {
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        return nil
    }
}

/// Focus, breaks, and completed blocks over some slots: the whole range or one tapped slot.
struct ProductivityRhythmTotals: Equatable {
    let focusTime: TimeInterval
    let breakTime: TimeInterval
    let completedFocusCount: Int

    init<Buckets: Sequence>(_ buckets: Buckets) where Buckets.Element == ProductivityDisplayBucket {
        var focusTime: TimeInterval = 0
        var breakTime: TimeInterval = 0
        var completedFocusCount = 0

        for bucket in buckets {
            focusTime += bucket.focusTime
            breakTime += bucket.breakTime
            completedFocusCount += bucket.completedFocusCount
        }

        self.focusTime = focusTime
        self.breakTime = breakTime
        self.completedFocusCount = completedFocusCount
    }

    /// Mean focus over the slots that have any, the rule Daily Focus Avg uses for days.
    static func averageFocus(over buckets: [ProductivityDisplayBucket]) -> TimeInterval {
        let activeBuckets = buckets.filter { $0.focusTime > 0 }
        guard !activeBuckets.isEmpty else { return 0 }
        return activeBuckets.reduce(0) { $0 + $1.focusTime } / Double(activeBuckets.count)
    }

    /// What VoiceOver reads for one slot.
    var accessibilityText: String {
        [
            "\(ProductivityValueFormatting.durationAccessibilityText(focusTime)) of focus",
            "\(ProductivityValueFormatting.durationAccessibilityText(breakTime)) of breaks",
            ProductivityValueFormatting.focusBlockCountText(completedFocusCount)
        ].joined(separator: ", ")
    }
}

/// The sessions listed under the chart.
enum ProductivitySessionList {
    static let rowLimit = 5

    struct Rows: Equatable {
        let sessions: [CompletedSession]
        /// Sessions in the interval beyond the row limit.
        let hiddenCount: Int
    }

    /// The latest sessions that started in `[start, end)`, newest first.
    static func rows(
        from sessions: [CompletedSession],
        startingFrom start: Date,
        before end: Date,
        limit: Int = rowLimit
    ) -> Rows {
        let matching = sessions
            .filter { $0.startDate >= start && $0.startDate < end }
            .sorted { $0.startDate > $1.startDate }

        return Rows(sessions: Array(matching.prefix(limit)), hiddenCount: max(0, matching.count - limit))
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
            return 6
        case .year:
            return 15
        }
    }

    var barTopCornerRadius: CGFloat {
        switch self {
        case .week:
            return 4
        case .month, .year:
            return 2
        }
    }

    var windowTitle: String {
        switch self {
        case .week:
            return "Last 7 days"
        case .month:
            return "Last 30 days"
        case .year:
            return "Last 12 months"
        }
    }

    /// Empty glass columns behind the bars show the days without focus. Thirty of them read as
    /// stripes, so Month leaves them out.
    var showsBarTracks: Bool {
        self != .month
    }

    /// Month labels every seventh day, counted back from today so the rightmost label is today.
    var axisLabelStride: Int {
        self == .month ? 7 : 1
    }

    func showsAxisLabel(atSlot index: Int, slotCount: Int) -> Bool {
        (slotCount - 1 - index) % axisLabelStride == 0
    }
}
