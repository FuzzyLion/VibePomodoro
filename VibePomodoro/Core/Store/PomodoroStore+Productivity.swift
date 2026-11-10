import Foundation

extension PomodoroStore {
    func clearProductivityHistory() {
        completedSessions = []
        productivityCache = .empty
        persist([.completedSessions, .productivityCache])
    }

    func productivitySnapshot(for range: ProductivityRange, now: Date = .now) -> ProductivityMetricsSnapshot {
        ProductivityMetricsSnapshot(
            chartPoints: chartPoints(for: range, cache: productivityCache, now: now),
            streakLength: streakLength(from: productivityCache.dailySummaries, now: now),
            completedSessionCount: productivityCache.completedSessionCount,
            completedFocusCount: productivityCache.completedFocusCount,
            totalFocusTime: productivityCache.totalFocusTime,
            totalBreakTime: productivityCache.totalBreakTime,
            averageFocusHoursPerDay: productivityCache.averageFocusHoursPerDay
        )
    }

    func chartPoints(for range: ProductivityRange, now: Date = .now) -> [ProductivityChartPoint] {
        chartPoints(for: range, cache: productivityCache, now: now)
    }

    func totalFocusTime(now: Date = .now) -> TimeInterval {
        productivityCache.totalFocusTime
    }

    func totalBreakTime(now: Date = .now) -> TimeInterval {
        productivityCache.totalBreakTime
    }

    func totalSessionTime(now: Date = .now) -> TimeInterval {
        productivityCache.totalFocusTime + productivityCache.totalBreakTime
    }

    func completedSessionCount() -> Int {
        productivityCache.completedSessionCount
    }

    func completedFocusCount() -> Int {
        productivityCache.completedFocusCount
    }

    func streakLength(now: Date = .now) -> Int {
        streakLength(from: productivityCache.dailySummaries, now: now)
    }

    func averageFocusHoursPerDay(now: Date = .now) -> Double {
        productivityCache.averageFocusHoursPerDay
    }
}

private extension PomodoroStore {
    func chartPoints(
        for range: ProductivityRange,
        cache: ProductivityAggregateCache,
        now: Date
    ) -> [ProductivityChartPoint] {
        let calendar = Calendar.autoupdatingCurrent
        let config = bucketConfiguration(for: range, calendar: calendar, now: now)
        var buckets: [Date: ProductivityChartPoint] = [:]

        for bucketStart in config.bucketStarts {
            buckets[bucketStart] = ProductivityChartPoint(
                startDate: bucketStart,
                label: config.label(bucketStart),
                focusTime: 0,
                breakTime: 0,
                completedFocusCount: 0
            )
        }

        for summary in cache.dailySummaries {
            guard summary.date >= config.rangeStart, summary.date < config.rangeEnd else { continue }

            let bucketStart = config.floor(summary.date)
            guard let point = buckets[bucketStart] else { continue }

            buckets[bucketStart] = point.updating(
                focusTime: point.focusTime + summary.focusTime,
                breakTime: point.breakTime + summary.breakTime,
                completedFocusCount: point.completedFocusCount + summary.completedFocusCount
            )
        }

        return config.bucketStarts.compactMap { buckets[$0] }
    }

    /// Consecutive days with focus time, counted back from today. A day without focus yet doesn't
    /// end the streak until it is over, so the count starts from yesterday until today has its own.
    func streakLength(from dailySummaries: [ProductivityDailySummary], now: Date) -> Int {
        let calendar = Calendar.autoupdatingCurrent
        // Days recorded in another time zone can land on the same local day; merge them.
        let dailyFocus: [Date: TimeInterval] = Dictionary(
            dailySummaries.map { (calendar.startOfDay(for: $0.date), $0.focusTime) },
            uniquingKeysWith: +
        )

        guard !dailyFocus.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: now)
        let todayHasFocus = (dailyFocus[today] ?? 0) > 0
        var streak = 0
        var day = todayHasFocus ? today : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)

        while let focusTime = dailyFocus[day], focusTime > 0 {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return streak
    }

    func bucketConfiguration(
        for range: ProductivityRange,
        calendar: Calendar,
        now: Date
    ) -> BucketConfiguration {
        switch range {
        case .week:
            let today = calendar.startOfDay(for: now)
            let starts = (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }

            return BucketConfiguration(
                rangeStart: starts.first ?? today,
                rangeEnd: calendar.date(byAdding: .day, value: 1, to: starts.last ?? today) ?? now,
                bucketStarts: starts,
                floor: { calendar.startOfDay(for: $0) },
                label: { $0.formatted(.dateTime.weekday(.abbreviated)) }
            )
        case .month:
            let today = calendar.startOfDay(for: now)
            let starts = (0..<30).compactMap { calendar.date(byAdding: .day, value: -29 + $0, to: today) }

            return BucketConfiguration(
                rangeStart: starts.first ?? today,
                rangeEnd: calendar.date(byAdding: .day, value: 1, to: starts.last ?? today) ?? now,
                bucketStarts: starts,
                floor: { calendar.startOfDay(for: $0) },
                label: { $0.formatted(.dateTime.day()) }
            )
        case .year:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let starts = (0..<12).compactMap { calendar.date(byAdding: .month, value: -11 + $0, to: monthStart) }

            return BucketConfiguration(
                rangeStart: starts.first ?? monthStart,
                rangeEnd: calendar.date(byAdding: .month, value: 1, to: starts.last ?? monthStart) ?? now,
                bucketStarts: starts,
                floor: { calendar.date(from: calendar.dateComponents([.year, .month], from: $0)) ?? $0 },
                label: { $0.formatted(.dateTime.month(.abbreviated)) }
            )
        }
    }
}

struct ProductivityChartPoint: Identifiable, Equatable {
    let startDate: Date
    let label: String
    let focusTime: TimeInterval
    let breakTime: TimeInterval
    let completedFocusCount: Int

    var id: Date { startDate }

    var sessionTime: TimeInterval {
        focusTime + breakTime
    }

    func updating(
        focusTime: TimeInterval,
        breakTime: TimeInterval,
        completedFocusCount: Int
    ) -> ProductivityChartPoint {
        ProductivityChartPoint(
            startDate: startDate,
            label: label,
            focusTime: focusTime,
            breakTime: breakTime,
            completedFocusCount: completedFocusCount
        )
    }
}

struct ProductivityMetricsSnapshot: Equatable {
    let chartPoints: [ProductivityChartPoint]
    let streakLength: Int
    let completedSessionCount: Int
    let completedFocusCount: Int
    let totalFocusTime: TimeInterval
    let totalBreakTime: TimeInterval
    let averageFocusHoursPerDay: Double

    var totalSessionTime: TimeInterval {
        totalFocusTime + totalBreakTime
    }
}

private struct BucketConfiguration {
    let rangeStart: Date
    let rangeEnd: Date
    let bucketStarts: [Date]
    let floor: (Date) -> Date
    let label: (Date) -> String
}
