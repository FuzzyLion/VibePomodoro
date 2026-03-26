import Foundation

struct ProductivityDailySummary: Codable, Equatable, Identifiable {
    let date: Date
    var focusTime: TimeInterval
    var shortBreakTime: TimeInterval
    var longBreakTime: TimeInterval
    var completedFocusCount: Int

    var id: Date { date }

    var breakTime: TimeInterval {
        shortBreakTime + longBreakTime
    }

    var sessionTime: TimeInterval {
        focusTime + breakTime
    }

    mutating func add(duration: TimeInterval, for phase: SessionPhase) {
        switch phase {
        case .focus:
            focusTime += duration
        case .shortBreak:
            shortBreakTime += duration
        case .longBreak:
            longBreakTime += duration
        }
    }

    mutating func addCompletedFocusCount(_ count: Int = 1) {
        completedFocusCount += count
    }
}

struct ProductivityAggregateCache: Codable, Equatable {
    static let currentSchemaVersion = 4

    let schemaVersion: Int
    var totalFocusTime: TimeInterval
    var totalShortBreakTime: TimeInterval
    var totalLongBreakTime: TimeInterval
    var completedSessionCount: Int
    var completedFocusCount: Int
    var dailySummaries: [ProductivityDailySummary]
    var accountedSessionIDs: Set<UUID>

    init(
        schemaVersion: Int = ProductivityAggregateCache.currentSchemaVersion,
        totalFocusTime: TimeInterval = 0,
        totalShortBreakTime: TimeInterval = 0,
        totalLongBreakTime: TimeInterval = 0,
        completedSessionCount: Int = 0,
        completedFocusCount: Int = 0,
        dailySummaries: [ProductivityDailySummary] = [],
        accountedSessionIDs: Set<UUID> = []
    ) {
        self.schemaVersion = schemaVersion
        self.totalFocusTime = totalFocusTime
        self.totalShortBreakTime = totalShortBreakTime
        self.totalLongBreakTime = totalLongBreakTime
        self.completedSessionCount = completedSessionCount
        self.completedFocusCount = completedFocusCount
        self.dailySummaries = dailySummaries
        self.accountedSessionIDs = accountedSessionIDs
    }

    static let empty = ProductivityAggregateCache()

    var totalBreakTime: TimeInterval {
        totalShortBreakTime + totalLongBreakTime
    }

    var averageFocusHoursPerDay: Double {
        let focusDays = dailySummaries.filter { $0.focusTime > 0 }
        guard !focusDays.isEmpty else { return 0 }

        let total = focusDays.reduce(0) { $0 + $1.focusTime }
        return total / Double(focusDays.count) / 3600
    }

    static func rebuild(
        from sessions: [CompletedSession],
        calendar: Calendar = .autoupdatingCurrent
    ) -> ProductivityAggregateCache {
        var cache = ProductivityAggregateCache.empty

        for session in sessions {
            cache.apply(session, calendar: calendar)
        }

        return cache
    }

    mutating func apply(_ session: CompletedSession, calendar: Calendar = .autoupdatingCurrent) {
        guard !accountedSessionIDs.contains(session.id) else { return }

        accountedSessionIDs.insert(session.id)
        completedSessionCount += 1
        completedFocusCount += session.completedFocusCount
        totalFocusTime += session.totalFocusTime
        totalShortBreakTime += session.totalShortBreakTime
        totalLongBreakTime += session.totalLongBreakTime

        for segment in session.segments {
            addDailySlices(for: segment, calendar: calendar)
        }

        addDailyCompletedFocusCounts(for: session, calendar: calendar)
    }

    private mutating func addDailySlices(for segment: ActivitySegment, calendar: Calendar) {
        var cursor = segment.startDate

        while cursor < segment.endDate {
            let dayStart = calendar.startOfDay(for: cursor)
            let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? segment.endDate
            let sliceEnd = min(nextDay, segment.endDate)
            let duration = sliceEnd.timeIntervalSince(cursor)

            if duration > 0 {
                add(duration: duration, phase: segment.phase, on: dayStart)
            }

            cursor = sliceEnd
        }
    }

    private mutating func add(duration: TimeInterval, phase: SessionPhase, on dayStart: Date) {
        guard duration > 0 else { return }

        if let index = dailySummaries.firstIndex(where: { $0.date == dayStart }) {
            dailySummaries[index].add(duration: duration, for: phase)
            return
        }

        var summary = ProductivityDailySummary(
            date: dayStart,
            focusTime: 0,
            shortBreakTime: 0,
            longBreakTime: 0,
            completedFocusCount: 0
        )
        summary.add(duration: duration, for: phase)
        dailySummaries.append(summary)
        dailySummaries.sort { $0.date < $1.date }
    }

    private mutating func addDailyCompletedFocusCounts(
        for session: CompletedSession,
        calendar: Calendar
    ) {
        for completionDate in session.completedFocusCompletionDates() {
            add(completedFocusCount: 1, on: calendar.startOfDay(for: completionDate))
        }
    }

    private mutating func add(completedFocusCount: Int, on dayStart: Date) {
        guard completedFocusCount > 0 else { return }

        if let index = dailySummaries.firstIndex(where: { $0.date == dayStart }) {
            dailySummaries[index].addCompletedFocusCount(completedFocusCount)
            return
        }

        var summary = ProductivityDailySummary(
            date: dayStart,
            focusTime: 0,
            shortBreakTime: 0,
            longBreakTime: 0,
            completedFocusCount: 0
        )
        summary.addCompletedFocusCount(completedFocusCount)
        dailySummaries.append(summary)
        dailySummaries.sort { $0.date < $1.date }
    }
}

struct DailyStatisticsPoint: Identifiable, Equatable {
    let date: Date
    let focusTime: TimeInterval
    let shortBreakTime: TimeInterval
    let longBreakTime: TimeInterval

    var id: Date { date }

    var breakTime: TimeInterval {
        shortBreakTime + longBreakTime
    }

    var sessionTime: TimeInterval {
        focusTime + breakTime
    }
}

enum ProductivityRange: String, CaseIterable, Identifiable {
    case week = "W"
    case month = "M"
    case year = "Y"

    var id: String { rawValue }
}
