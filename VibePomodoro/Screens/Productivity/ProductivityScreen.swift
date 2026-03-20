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
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(ProductivityMetricKind.allCases) { metric in
                        ProductivityMetricCard(
                            metric: metric,
                            snapshot: renderState,
                            range: selectedRange
                        )
                    }

                    if renderState.completedSessionCount == 0 {
                        Text("Complete a full session to start filling these charts. Productivity only reflects finished sessions.")
                            .font(.system(.footnote, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
            .navigationTitle("Productivity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProductivityRangeMenu(selectedRange: $selectedRange)
                }
            }
        }
    }
}

private struct ProductivityRangeMenu: View {
    @Binding var selectedRange: ProductivityRange
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Menu {
            Picker("Range", selection: $selectedRange) {
                ForEach(ProductivityRange.allCases) { range in
                    Text(range.displayTitle).tag(range)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 15, weight: .semibold))

                Text(selectedRange.displayTitle)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .opacity(0.72)
            }
            .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.74))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.68),
                        lineWidth: 0.75
                    )
            }
            .overlay(alignment: .top) {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.18 : 0.58),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, 14)
            }
        }
    }
}

private struct ProductivityMetricCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let metric: ProductivityMetricKind
    let snapshot: ProductivityMetricsSnapshot
    let range: ProductivityRange

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: metric.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(metric.accentColor(for: colorScheme))
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(metric.accentColor(for: colorScheme).opacity(colorScheme == .dark ? 0.13 : 0.10))
                    )

                Text(metric.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(metric.accentColor(for: colorScheme))

                Spacer()
            }

            Text(metric.totalValueText(from: snapshot))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(primaryTextColor)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .monospacedDigit()

            Chart(snapshot.chartPoints) { point in
                let value = metric.bucketValue(for: point)

                BarMark(
                    x: .value("Bucket", point.startDate, unit: range.chartUnit),
                    y: .value(metric.title, value)
                )
                .clipShape(RoundedRectangle(cornerRadius: range.barCornerRadius, style: .continuous))
                .foregroundStyle(metric.barFill(for: colorScheme))
                .opacity(value > 0 ? 1 : 0.18)
                .annotation(position: .overlay, alignment: .top) {
                    if value > 0 {
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.24 : 0.18))
                            .frame(width: range.highlightWidth, height: 1.5)
                            .padding(.top, 4)
                    }
                }
                .annotation(position: .top, alignment: .center) {
                    if shouldShowAnnotation(for: value) {
                        Text(metric.annotationText(for: value))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(metric.accentColor(for: colorScheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .padding(.bottom, 2)
                    }
                }
            }
            .frame(height: 230)
            .chartLegend(.hidden)
            .chartYScale(domain: 0...metric.chartUpperBound(for: snapshot.chartPoints))
            .chartXAxis {
                AxisMarks(values: xAxisMarkDates) { value in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisTick().foregroundStyle(.clear)
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(xAxisLabel(for: date))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(gridColor)
                    AxisTick().foregroundStyle(.clear)
                    AxisValueLabel {
                        if let axisValue = value.as(Double.self) {
                            Text(metric.axisLabelText(for: axisValue))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(plotAreaBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(
                                        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.48),
                                        lineWidth: 0.75
                                    )
                            }
                    }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 22)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(cardBorderColor, lineWidth: 0.8)
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.16 : 0.60),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 22)
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.16 : 0.08),
            radius: colorScheme == .dark ? 22 : 16,
            y: colorScheme == .dark ? 12 : 8
        )
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.96) : Color.black.opacity(0.80)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.56) : Color.black.opacity(0.46)
    }

    private var gridColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.11) : Color.black.opacity(0.08)
    }

    private var plotAreaBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.04 : 0.40),
                metric.accentColor(for: colorScheme).opacity(colorScheme == .dark ? 0.035 : 0.025)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(metric.accentColor(for: colorScheme).opacity(colorScheme == .dark ? 0.05 : 0.028))
            }
    }

    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.17) : Color.white.opacity(0.72)
    }

    private var xAxisMarkDates: [Date] {
        let dates = snapshot.chartPoints.map(\.startDate)

        switch range {
        case .week, .year:
            return dates
        case .month:
            return snapshot.chartPoints.enumerated().compactMap { index, point in
                let shouldShow = index == 0 || index == snapshot.chartPoints.count - 1 || index % 5 == 0
                return shouldShow ? point.startDate : nil
            }
        }
    }

    private func xAxisLabel(for date: Date) -> String {
        switch range {
        case .week:
            return date.formatted(.dateTime.weekday(.abbreviated))
        case .month:
            return date.formatted(.dateTime.day())
        case .year:
            return date.formatted(.dateTime.month(.abbreviated))
        }
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
            return colorScheme == .dark
                ? Color(red: 0.28, green: 0.60, blue: 0.98)
                : Color(red: 0.18, green: 0.45, blue: 0.84)
        case .sessionTime:
            return colorScheme == .dark
                ? Color(red: 0.66, green: 0.42, blue: 0.96)
                : Color(red: 0.51, green: 0.34, blue: 0.80)
        case .focusTime:
            return colorScheme == .dark
                ? Color(red: 0.17, green: 0.78, blue: 0.35)
                : Color(red: 0.17, green: 0.60, blue: 0.31)
        case .breakTime:
            return colorScheme == .dark
                ? Color(red: 1.0, green: 0.64, blue: 0.23)
                : Color(red: 0.90, green: 0.56, blue: 0.18)
        }
    }

    func barFill(for colorScheme: ColorScheme) -> AnyShapeStyle {
        let accent = accentColor(for: colorScheme)

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    accent.opacity(colorScheme == .dark ? 0.92 : 0.74),
                    accent.opacity(colorScheme == .dark ? 0.68 : 0.52)
                ],
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

    func bucketValue(for point: ProductivityChartPoint) -> Double {
        switch self {
        case .focusSessions:
            return Double(point.completedFocusCount)
        case .sessionTime:
            return point.sessionTime
        case .focusTime:
            return point.focusTime
        case .breakTime:
            return point.breakTime
        }
    }

    func axisLabelText(for value: Double) -> String {
        switch self {
        case .focusSessions:
            return "\(Int(value.rounded()))"
        case .sessionTime, .focusTime, .breakTime:
            return Self.axisDurationText(value)
        }
    }

    func annotationText(for value: Double) -> String {
        switch self {
        case .focusSessions:
            return "\(Int(value.rounded()))"
        case .sessionTime, .focusTime, .breakTime:
            return Self.annotationDurationText(value)
        }
    }

    func chartUpperBound(for points: [ProductivityChartPoint]) -> Double {
        let maxValue = points.map(bucketValue(for:)).max() ?? 0

        switch self {
        case .focusSessions:
            return Self.niceCountUpperBound(for: maxValue)
        case .sessionTime, .focusTime, .breakTime:
            return Self.niceDurationUpperBound(for: maxValue)
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

    private static func axisDurationText(_ value: Double) -> String {
        let duration = max(0, value)
        if duration < 3600 {
            return "\(Int((duration / 60).rounded()))m"
        }

        let hours = duration / 3600
        if hours < 10 {
            return String(format: "%.1fh", hours)
        }

        return "\(Int(hours.rounded()))h"
    }

    private static func annotationDurationText(_ value: Double) -> String {
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

    private static func niceCountUpperBound(for maxValue: Double) -> Double {
        guard maxValue > 0 else { return 4 }

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

        return ceil(padded / step) * step
    }

    private static func niceDurationUpperBound(for maxValue: Double) -> Double {
        guard maxValue > 0 else { return 3600 }

        let padded = maxValue * 1.18
        let step: Double

        switch padded {
        case ..<3600.0:
            step = 15 * 60
        case ..<(4 * 3600.0):
            step = 30 * 60
        case ..<(12 * 3600.0):
            step = 60 * 60
        case ..<(36 * 3600.0):
            step = 2 * 3600
        default:
            step = 4 * 3600
        }

        return ceil(padded / step) * step
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

    var chartUnit: Calendar.Component {
        switch self {
        case .week, .month:
            return .day
        case .year:
            return .month
        }
    }

    var highlightWidth: CGFloat {
        switch self {
        case .week:
            return 18
        case .month:
            return 8
        case .year:
            return 14
        }
    }

    var barCornerRadius: CGFloat {
        switch self {
        case .week:
            return 8
        case .month:
            return 5
        case .year:
            return 7
        }
    }
}
