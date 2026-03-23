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
                VStack(alignment: .leading, spacing: 14) {
                    ProductivitySummaryStrip(snapshot: renderState)

                    if renderState.completedSessionCount == 0 {
                        ProductivityEmptyStateNote()
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(ProductivityMetricKind.chartMetrics) { metric in
                            ProductivityTrendCard(
                                metric: metric,
                                snapshot: renderState,
                                range: selectedRange
                            )
                        }
                    }
                    .padding(.top, renderState.completedSessionCount == 0 ? 4 : 8)
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
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(toolbarIconColor)
        }
        .accessibilityLabel("Time Range")
        .accessibilityValue(selectedRange.displayTitle)
    }

    private var toolbarIconColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.92) : Color.black.opacity(0.66)
    }
}

private struct ProductivitySummaryStrip: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let snapshot: ProductivityMetricsSnapshot
    private let contentInset: CGFloat = 20
    private let cornerRadius: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            header

            ProductivityPrimarySummaryMetric(
                title: "Session Time",
                value: ProductivityValueFormatting.summarySessionTimeText(snapshot.totalSessionTime),
                accessibilityValue: ProductivityValueFormatting.summarySessionTimeAccessibilityValue(snapshot.totalSessionTime),
                titleColor: sessionTitleColor,
                valueColor: primaryValueColor,
                dynamicTypeSize: dynamicTypeSize
            )

            summaryDivider

            ProductivitySecondaryMetricsRow(
                snapshot: snapshot,
                colorScheme: colorScheme,
                dynamicTypeSize: dynamicTypeSize
            )

            Text(metaSummaryText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(metaTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, contentInset)
        .padding(.vertical, 20)
        .background(background)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 0.85)
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.46),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                        )
                )
                .frame(height: 1)
                .padding(.horizontal, contentInset)
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.13 : 0.05),
            radius: colorScheme == .dark ? 16 : 10,
            y: colorScheme == .dark ? 8 : 5
        )
    }

    private var header: some View {
        Text("ALL TIME COMPLETED SESSIONS")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(headerTextColor)
            .tracking(0.72)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
            .minimumScaleFactor(0.92)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1)
    }

    private var metaSummaryText: String {
        guard snapshot.completedSessionCount > 0 else {
            return "No finished sessions yet"
        }

        let sessionsText = snapshot.completedSessionCount == 1
            ? "1 finished session"
            : "\(snapshot.completedSessionCount) finished sessions"
        let focusBlocksText = snapshot.completedFocusCount == 1
            ? "1 focus block"
            : "\(snapshot.completedFocusCount) focus blocks"

        return "\(sessionsText) • \(focusBlocksText)"
    }

    private var headerTextColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.54) : Color.black.opacity(0.45)
    }

    private var primaryValueColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.98) : Color.black.opacity(0.84)
    }

    private var metaTextColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.64) : Color.black.opacity(0.52)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.66)
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var sessionTitleColor: Color {
        colorScheme == .dark
            ? VibePalette.warmAmberAccent.opacity(0.94)
            : VibePalette.warmAmberAccentDeep.opacity(0.94)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.035 : 0.20),
                                Color.white.opacity(colorScheme == .dark ? 0.01 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                VibePalette.warmAmberAccent.opacity(colorScheme == .dark ? 0.12 : 0.07),
                                VibePalette.warmAmberAccent.opacity(colorScheme == .dark ? 0.05 : 0.025),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 10,
                            endRadius: 220
                        )
                    )
            }
    }
}

private struct ProductivityPrimarySummaryMetric: View {
    let title: String
    let value: String
    let accessibilityValue: String
    let titleColor: Color
    let valueColor: Color
    let dynamicTypeSize: DynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(titleColor)
                .textCase(.uppercase)
                .tracking(0.65)

            Text(value)
                .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 36 : 44, weight: .semibold))
                .foregroundStyle(valueColor)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.9 : 0.72)
                .multilineTextAlignment(.leading)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
    }
}

private struct ProductivitySecondaryMetricsRow: View {
    let snapshot: ProductivityMetricsSnapshot
    let colorScheme: ColorScheme
    let dynamicTypeSize: DynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 14) {
                    secondaryMetric(
                        title: "Daily Focus Avg",
                        value: ProductivityValueFormatting.summaryAverageFocusText(snapshot.averageFocusHoursPerDay),
                        accessibilityValue: ProductivityValueFormatting.summaryAverageFocusActiveDayAccessibilityValue(snapshot.averageFocusHoursPerDay),
                        titleColor: averageTitleColor
                    )

                    horizontalDivider

                    secondaryMetric(
                        title: "Streak",
                        value: ProductivityValueFormatting.summaryStreakText(snapshot.streakLength),
                        accessibilityValue: ProductivityValueFormatting.summaryStreakAccessibilityValue(snapshot.streakLength),
                        titleColor: streakTitleColor
                    )
                }
            } else {
                HStack(alignment: .top, spacing: 16) {
                    secondaryMetric(
                        title: "Daily Focus Avg",
                        value: ProductivityValueFormatting.summaryAverageFocusText(snapshot.averageFocusHoursPerDay),
                        accessibilityValue: ProductivityValueFormatting.summaryAverageFocusActiveDayAccessibilityValue(snapshot.averageFocusHoursPerDay),
                        titleColor: averageTitleColor
                    )

                    verticalDivider

                    secondaryMetric(
                        title: "Streak",
                        value: ProductivityValueFormatting.summaryStreakText(snapshot.streakLength),
                        accessibilityValue: ProductivityValueFormatting.summaryStreakAccessibilityValue(snapshot.streakLength),
                        titleColor: streakTitleColor
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func secondaryMetric(
        title: String,
        value: String,
        accessibilityValue: String,
        titleColor: Color
    ) -> some View {
        ProductivitySecondarySummaryItem(
            title: title,
            value: value,
            accessibilityValue: accessibilityValue,
            titleColor: titleColor,
            colorScheme: colorScheme
        )
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(width: 1, height: 42)
            .frame(maxHeight: .infinity, alignment: .center)
    }

    private var horizontalDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1)
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var averageTitleColor: Color {
        colorScheme == .dark
            ? VibePalette.softJade.opacity(0.94)
            : VibePalette.softJadeDeep.opacity(0.94)
    }

    private var streakTitleColor: Color {
        colorScheme == .dark
            ? VibePalette.softMist.opacity(0.94)
            : VibePalette.softMistDeep.opacity(0.94)
    }
}

private struct ProductivitySecondarySummaryItem: View {
    let title: String
    let value: String
    let accessibilityValue: String
    let titleColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(titleColor)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.78)
                .lineLimit(1)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
    }

    private var valueColor: Color {
        colorScheme == .dark ? VibePalette.warmBackground.opacity(0.94) : Color.black.opacity(0.78)
    }
}

private struct ProductivityEmptyStateNote: View {
    var body: some View {
        Text("Complete a full session to start filling these charts. Productivity only reflects finished sessions.")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.top, 2)
            .padding(.bottom, 4)
    }
}

private struct ProductivityTrendCard: View {
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

    private var slotDomain: ClosedRange<Double> {
        let bucketCount = max(displayBuckets.count, 1)
        return -0.5...(Double(bucketCount) - 0.5)
    }

    private var accentColor: Color {
        metric.accentColor(for: colorScheme)
    }

    private var accentLabelColor: Color {
        accentColor.opacity(colorScheme == .dark ? 0.90 : 0.84)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: metric.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accentLabelColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accentColor.opacity(colorScheme == .dark ? 0.085 : 0.058))
                    )

                Text(metric.title)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(accentLabelColor)

                Spacer()

                ProductivityRangeBadge(
                    title: range.displayTitle,
                    tint: accentLabelColor,
                    colorScheme: colorScheme
                )
            }

            Text(metric.rangeValueText(from: displayBuckets))
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(primaryTextColor)
                .minimumScaleFactor(0.76)
                .lineLimit(1)
                .monospacedDigit()

            Chart(displayBuckets) { bucket in
                let value = metric.bucketValue(for: bucket)

                BarMark(
                    x: .value("Bucket", bucket.slotValue),
                    y: .value(metric.title, value),
                    width: .fixed(range.barWidth)
                )
                .clipShape(TopRoundedBarShape(radius: range.barTopCornerRadius))
                .foregroundStyle(metric.barFill(for: colorScheme))
                .opacity(value > 0 ? 1 : 0.10)
                .annotation(position: .top, alignment: .center) {
                    if shouldShowAnnotation(for: value) {
                        Text(metric.annotationText(for: value))
                            .font(.system(size: range.annotationFontSize, weight: .semibold))
                            .foregroundStyle(accentLabelColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .padding(.bottom, range.annotationBottomPadding)
                    }
                }
            }
            .frame(height: 186)
            .padding(.bottom, 22)
            .chartLegend(.hidden)
            .chartYScale(domain: 0...axisStyle.upperBound)
            .chartXScale(domain: slotDomain)
            .chartXAxis(.hidden)
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
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let plotFrame = proxy.plotFrame {
                        ProductivityCustomXAxis(
                            buckets: displayBuckets,
                            range: range,
                            plotFrame: geometry[plotFrame],
                            textColor: secondaryTextColor
                        )
                        .offset(y: geometry[plotFrame].maxY + 8)
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
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.40),
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
            color: Color.black.opacity(colorScheme == .dark ? 0.10 : 0.04),
            radius: colorScheme == .dark ? 14 : 8,
            y: colorScheme == .dark ? 7 : 4
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
            .fill(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(accentColor.opacity(colorScheme == .dark ? 0.022 : 0.010))
            }
    }

    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.13) : Color.white.opacity(0.60)
    }

    private func shouldShowAnnotation(for value: Double) -> Bool {
        value > 0
    }
}

private struct ProductivityRangeBadge: View {
    let title: String
    let tint: Color
    let colorScheme: ColorScheme

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(badgeTextColor)
            .tracking(0.45)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(colorScheme == .dark ? 0.16 : 0.10))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(tint.opacity(colorScheme == .dark ? 0.18 : 0.10), lineWidth: 0.8)
            }
    }

    private var badgeTextColor: Color {
        colorScheme == .dark ? tint.opacity(0.95) : tint.opacity(0.88)
    }
}

private struct ProductivityCustomXAxis: View {
    let buckets: [ProductivityDisplayBucket]
    let range: ProductivityRange
    let plotFrame: CGRect
    let textColor: Color

    var body: some View {
        let slotWidth = plotFrame.width / CGFloat(max(buckets.count, 1))

        ZStack(alignment: .topLeading) {
            ForEach(Array(buckets.enumerated()), id: \.element.id) { index, bucket in
                Text(ProductivityChartFormatting.xAxisLabel(for: bucket.labelDate, range: range))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(width: slotWidth, alignment: .center)
                    .position(
                        x: plotFrame.minX + slotWidth * (CGFloat(index) + 0.5),
                        y: 8
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct TopRoundedBarShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let clampedRadius = min(radius, rect.width / 2, rect.height)
        guard clampedRadius > 0 else {
            return Path(CGRect(origin: rect.origin, size: rect.size))
        }

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + clampedRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + clampedRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - clampedRadius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + clampedRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private enum ProductivityMetricKind: CaseIterable, Identifiable {
    case focusSessions
    case sessionTime
    case focusTime
    case breakTime

    static let chartMetrics: [ProductivityMetricKind] = [
        .focusSessions,
        .focusTime,
        .breakTime
    ]

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

    func rangeValueText(from buckets: [ProductivityDisplayBucket]) -> String {
        switch self {
        case .focusSessions:
            return "\(Int(rangeTotal(from: buckets).rounded()))"
        case .sessionTime, .focusTime, .breakTime:
            return ProductivityValueFormatting.compactDurationText(rangeTotal(from: buckets))
        }
    }

    func rangeTotal(from buckets: [ProductivityDisplayBucket]) -> Double {
        buckets.reduce(0) { partialResult, bucket in
            partialResult + bucketValue(for: bucket)
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

private enum ProductivityValueFormatting {
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

    static func averageFocusText(_ hoursPerDay: Double) -> String {
        compactDurationText(hoursPerDay * 3600)
    }

    static func streakText(_ streakLength: Int) -> String {
        if streakLength == 1 {
            return "1 day"
        }
        return "\(streakLength) days"
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
