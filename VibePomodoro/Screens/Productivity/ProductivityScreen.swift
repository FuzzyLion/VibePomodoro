import Charts
import SwiftUI

struct ProductivityScreen: View {
    @EnvironmentObject private var store: PomodoroStore
    @State private var selectedRange: ProductivityRange = .week

    private var renderState: ProductivityMetricsSnapshot {
        store.productivitySnapshot(for: selectedRange)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(ProductivityMetricKind.allCases) { metric in
                        ProductivityMetricCard(
                            metric: metric,
                            snapshot: renderState,
                            range: selectedRange
                        )
                    }

                    if renderState.completedSessionCount == 0 {
                        Text("Complete a full session to start filling these charts. Productivity only reflects finished sessions.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .navigationTitle("Productivity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProductivityRangeToolbarMenu(selectedRange: $selectedRange)
                }
            }
        }
    }
}

private struct ProductivityRangeToolbarMenu: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selectedRange: ProductivityRange

    var body: some View {
        Menu {
            Picker("Range", selection: $selectedRange) {
                ForEach(ProductivityRange.allCases) { range in
                    Text(range.displayTitle).tag(range)
                }
            }
        } label: {
            Label(selectedRange.toolbarLabel, systemImage: "line.3.horizontal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(toolbarLabelColor)
        }
        .accessibilityLabel("Time Range")
        .accessibilityValue(selectedRange.displayTitle)
    }

    private var toolbarLabelColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.96) : Color.black.opacity(0.80)
    }
}

private struct ProductivityMetricCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let metric: ProductivityMetricKind
    let snapshot: ProductivityMetricsSnapshot
    let range: ProductivityRange

    private var displayBuckets: [ProductivityDisplayBucket] {
        ProductivityChartDisplay.displayBuckets(from: snapshot.chartPoints, range: range)
    }

    private var axisStyle: ProductivityNumericAxisStyle {
        metric.axisStyle(for: displayBuckets)
    }

    private var xDomain: ClosedRange<Date> {
        ProductivityChartDisplay.xDomain(for: displayBuckets) ?? {
            let now = Date.now
            return now...now.addingTimeInterval(24 * 3600)
        }()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: metric.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(metric.accentColor(for: colorScheme))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(metric.accentColor(for: colorScheme).opacity(colorScheme == .dark ? 0.11 : 0.08))
                    )

                Text(metric.title)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(metric.accentColor(for: colorScheme))

                Spacer()
            }

            Text(metric.totalValueText(from: snapshot))
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(primaryTextColor)
                .minimumScaleFactor(0.76)
                .lineLimit(1)
                .monospacedDigit()

            Chart(displayBuckets) { bucket in
                let value = metric.bucketValue(for: bucket)

                BarMark(
                    x: .value("Bucket", bucket.xDate),
                    y: .value(metric.title, value),
                    width: .fixed(range.barWidth)
                )
                .clipShape(RoundedRectangle(cornerRadius: range.barCornerRadius, style: .continuous))
                .foregroundStyle(metric.barFill(for: colorScheme))
                .opacity(value > 0 ? 1 : 0.10)
                .annotation(position: .overlay, alignment: .top) {
                    if value > 0 {
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.22 : 0.16))
                            .frame(width: range.highlightWidth, height: 1.25)
                            .padding(.top, 4)
                    }
                }
                .annotation(position: .top, alignment: .center) {
                    if shouldShowAnnotation(for: value) {
                        Text(metric.annotationText(for: value))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(metric.accentColor(for: colorScheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .padding(.bottom, 2)
                    }
                }
            }
            .frame(height: 194)
            .chartLegend(.hidden)
            .chartYScale(domain: 0...axisStyle.upperBound)
            .chartXScale(domain: xDomain)
            .chartXAxis {
                AxisMarks(values: ProductivityChartFormatting.xAxisMarkDates(for: displayBuckets)) { value in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisTick().foregroundStyle(.clear)
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(ProductivityChartFormatting.xAxisLabel(for: date, buckets: displayBuckets, range: range))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: axisStyle.values) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(gridColor)
                    AxisTick().foregroundStyle(.clear)
                    AxisValueLabel {
                        if let axisValue = value.as(Double.self) {
                            Text(metric.axisLabelText(for: axisValue))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(cardBorderColor, lineWidth: 0.75)
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.52),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 18)
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.14 : 0.06),
            radius: colorScheme == .dark ? 18 : 12,
            y: colorScheme == .dark ? 10 : 6
        )
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.94) : Color.black.opacity(0.80)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.54) : Color.black.opacity(0.48)
    }

    private var gridColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(metric.accentColor(for: colorScheme).opacity(colorScheme == .dark ? 0.035 : 0.016))
            }
    }

    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.66)
    }

    private func shouldShowAnnotation(for value: Double) -> Bool {
        value > 0 && range != .month
    }
}

private enum ProductivityMetricKind: CaseIterable, Identifiable {
    case focusSessions
    case sessionTime
    case focusTime
    case breakTime

    var id: String { title }

    var title: String {
        switch self {
        case .focusSessions:
            return "Focus Sessions"
        case .sessionTime:
            return "Session Time"
        case .focusTime:
            return "Focus Time"
        case .breakTime:
            return "Break Time"
        }
    }

    var systemImage: String {
        switch self {
        case .focusSessions:
            return "square.on.square"
        case .sessionTime:
            return "hourglass"
        case .focusTime:
            return "gauge.with.dots.needle.67percent"
        case .breakTime:
            return "cup.and.saucer"
        }
    }

    func accentColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .focusSessions:
            return colorScheme == .dark ? VibePalette.softMist : VibePalette.softMistDeep
        case .sessionTime:
            return colorScheme == .dark ? VibePalette.warmAmberAccent : VibePalette.warmAmberAccentDeep
        case .focusTime:
            return colorScheme == .dark ? VibePalette.amberGold : VibePalette.amberGoldDeep
        case .breakTime:
            return colorScheme == .dark ? VibePalette.softJade : VibePalette.softJadeDeep
        }
    }

    func barFill(for colorScheme: ColorScheme) -> AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: barGradientColors(for: colorScheme),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    func totalValueText(from snapshot: ProductivityMetricsSnapshot) -> String {
        switch self {
        case .focusSessions:
            return "\(snapshot.completedFocusCount)"
        case .sessionTime:
            return Self.longDurationText(snapshot.totalSessionTime)
        case .focusTime:
            return Self.longDurationText(snapshot.totalFocusTime)
        case .breakTime:
            return Self.longDurationText(snapshot.totalBreakTime)
        }
    }

    func bucketValue(for bucket: ProductivityDisplayBucket) -> Double {
        switch self {
        case .focusSessions:
            return Double(bucket.completedFocusCount)
        case .sessionTime:
            return bucket.sessionTime
        case .focusTime:
            return bucket.focusTime
        case .breakTime:
            return bucket.breakTime
        }
    }

    func axisLabelText(for value: Double) -> String {
        switch self {
        case .focusSessions:
            return "\(Int(value.rounded()))"
        case .sessionTime, .focusTime, .breakTime:
            return ProductivityChartFormatting.axisDurationText(value)
        }
    }

    func annotationText(for value: Double) -> String {
        switch self {
        case .focusSessions:
            return "\(Int(value.rounded()))"
        case .sessionTime, .focusTime, .breakTime:
            return ProductivityChartFormatting.annotationDurationText(value)
        }
    }

    func axisStyle(for buckets: [ProductivityDisplayBucket]) -> ProductivityNumericAxisStyle {
        let maxValue = buckets.map(bucketValue(for:)).max() ?? 0

        switch self {
        case .focusSessions:
            return Self.countAxisStyle(for: maxValue)
        case .sessionTime, .focusTime, .breakTime:
            return ProductivityChartFormatting.timeAxisStyle(for: maxValue)
        }
    }

    private func barGradientColors(for colorScheme: ColorScheme) -> [Color] {
        switch self {
        case .focusSessions:
            return [
                VibePalette.softMist.opacity(colorScheme == .dark ? 0.88 : 0.78),
                VibePalette.softMistDeep.opacity(colorScheme == .dark ? 0.66 : 0.54)
            ]
        case .sessionTime:
            return [
                VibePalette.warmAmberAccent.opacity(colorScheme == .dark ? 0.88 : 0.76),
                VibePalette.warmAmberAccentDeep.opacity(colorScheme == .dark ? 0.66 : 0.54)
            ]
        case .focusTime:
            return [
                VibePalette.amberGold.opacity(colorScheme == .dark ? 0.90 : 0.80),
                VibePalette.amberGoldDeep.opacity(colorScheme == .dark ? 0.68 : 0.56)
            ]
        case .breakTime:
            return [
                VibePalette.softJade.opacity(colorScheme == .dark ? 0.88 : 0.78),
                VibePalette.softJadeDeep.opacity(colorScheme == .dark ? 0.66 : 0.54)
            ]
        }
    }

    private static func longDurationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        }
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    private static func countAxisStyle(for maxValue: Double) -> ProductivityNumericAxisStyle {
        guard maxValue > 0 else {
            return ProductivityNumericAxisStyle(step: 1, upperBound: 4)
        }

        let padded = maxValue * 1.18
        let step: Double

        switch padded {
        case ..<6:
            step = 1
        case ..<20:
            step = 2
        case ..<50:
            step = 5
        default:
            step = 10
        }

        let upperBound = max(step * 4, ceil(padded / step) * step)
        return ProductivityNumericAxisStyle(step: step, upperBound: upperBound)
    }
}

struct ProductivityDisplayBucket: Identifiable, Equatable {
    let startDate: Date
    let endDate: Date
    let xDate: Date
    let labelDate: Date
    let focusTime: TimeInterval
    let breakTime: TimeInterval
    let completedFocusCount: Int

    var id: Date { xDate }

    var sessionTime: TimeInterval {
        focusTime + breakTime
    }
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

        switch range {
        case .week:
            return sortedPoints.compactMap { point in
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
            return stride(from: 0, to: sortedPoints.count, by: 7).compactMap { startIndex in
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
            return sortedPoints.compactMap { point in
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
    }

    static func xDomain(for buckets: [ProductivityDisplayBucket]) -> ClosedRange<Date>? {
        guard let first = buckets.first, let last = buckets.last else { return nil }
        return first.startDate...last.endDate
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

    static func xAxisMarkDates(for buckets: [ProductivityDisplayBucket]) -> [Date] {
        buckets.map(\.xDate)
    }

    static func xAxisLabel(
        for markDate: Date,
        buckets: [ProductivityDisplayBucket],
        range: ProductivityRange
    ) -> String {
        guard let bucket = buckets.first(where: { $0.xDate == markDate }) else { return "" }

        switch range {
        case .week:
            return bucket.labelDate.formatted(.dateTime.weekday(.abbreviated))
        case .month:
            return monthAxisLabel(for: bucket.labelDate)
        case .year:
            return yearAxisLabel(for: bucket.labelDate)
        }
    }

    static func monthAxisLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = englishLocale
        formatter.dateFormat = "d. MMM"
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

private extension ProductivityRange {
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

    var toolbarLabel: String {
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

    var highlightWidth: CGFloat {
        switch self {
        case .week:
            return 16
        case .month:
            return 18
        case .year:
            return 12
        }
    }

    var barCornerRadius: CGFloat {
        switch self {
        case .week:
            return 7
        case .month:
            return 6
        case .year:
            return 6
        }
    }
}
