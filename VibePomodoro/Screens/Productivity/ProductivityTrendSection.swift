import Charts
import SwiftUI

struct ProductivityRangeCaption: View {
    @Environment(\.colorScheme) private var colorScheme

    let range: ProductivityRange
    let buckets: [ProductivityDisplayBucket]

    var body: some View {
        let dates = ProductivityChartFormatting.rangeDatesText(for: buckets, range: range)
        let caption = "\(range.windowTitle) • \(dates)"

        Text(caption)
            .productivityFont(.caption)
            .foregroundStyle(textColor)
            .monospacedDigit()
            .padding(.horizontal, ProductivityLayout.TrendGroup.captionHorizontalPadding)
            .accessibilityLabel("\(range.windowTitle), \(dates)")
    }

    private var textColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.TrendCard.secondaryTextDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.secondaryTextLightOpacity)
    }
}

struct ProductivityTrendCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title3) private var iconFrame = ProductivityLayout.TrendCard.iconFrame

    let metric: ProductivityChartMetricKind
    let buckets: [ProductivityDisplayBucket]
    let range: ProductivityRange
    /// Shared by the three cards: their days line up, so one tap shows the same day in each.
    @Binding var selectedSlot: Int?

    private let contentInset = ProductivityLayout.TrendCard.contentInset
    private let cornerRadius = ProductivityLayout.TrendCard.cornerRadius

    private var accentColor: Color {
        metric.accentColor(for: colorScheme)
    }

    private var accentLabelColor: Color {
        colorScheme == .dark
            ? accentColor.opacity(ProductivityLayout.TrendCard.accentLabelDarkOpacity)
            : metric.inkColor
    }

    private var selectedBucket: ProductivityDisplayBucket? {
        guard let selectedSlot, buckets.indices.contains(selectedSlot) else { return nil }
        return buckets[selectedSlot]
    }

    var body: some View {
        let isAccessibilitySize = dynamicTypeSize.isAccessibilitySize
        let selectionText = selectedBucket.map { ProductivityChartFormatting.selectionText(for: $0, range: range) }
        let headlineText = selectedBucket.map { metric.valueText(for: metric.bucketValue(for: $0)) }
            ?? metric.rangeValueText(from: buckets)

        VStack(alignment: .leading, spacing: ProductivityLayout.TrendCard.stackSpacing) {
            HStack(spacing: ProductivityLayout.TrendCard.headerSpacing) {
                // The icon only repeats the title, so at accessibility sizes the title takes its room.
                if !isAccessibilitySize {
                    icon
                }

                Text(metric.title)
                    .productivityFont(.cardTitle)
                    .foregroundStyle(accentLabelColor)

                Spacer(minLength: ProductivityLayout.TrendCard.headerSpacing)

                if !isAccessibilitySize, let selectionText {
                    selectionLabel(selectionText)
                }
            }

            if isAccessibilitySize, let selectionText {
                selectionLabel(selectionText)
            }

            Text(headlineText)
                .productivityFont(.cardFigure)
                .foregroundStyle(primaryTextColor)
                .minimumScaleFactor(0.76)
                .lineLimit(1)
                .monospacedDigit()

            ProductivityTrendChart(
                metric: metric,
                buckets: buckets,
                range: range,
                selectedSlot: $selectedSlot
            )
            // Seven day names share the plot's width with the value column, so axis labels stop
            // growing at xxLarge; a tapped bar's date and value, in the header above, carry the
            // detail at any size.
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
        .padding(.horizontal, contentInset)
        .padding(.vertical, contentInset)
        .productivityGlassCard(
            colorScheme: colorScheme,
            style: .trend(contentInset: contentInset, cornerRadius: cornerRadius)
        ) {
            trendAccentOverlay
        }
    }

    private var icon: some View {
        Image(systemName: metric.systemImage)
            .productivityFont(.cardIcon)
            .foregroundStyle(accentLabelColor)
            .frame(width: iconFrame, height: iconFrame)
            .background(
                RoundedRectangle(cornerRadius: ProductivityLayout.TrendCard.iconCornerRadius, style: .continuous)
                    .fill(
                        accentColor.opacity(
                            colorScheme == .dark
                                ? ProductivityLayout.TrendCard.iconChipDarkOpacity
                                : ProductivityLayout.TrendCard.iconChipLightOpacity
                        )
                    )
            )
    }

    private func selectionLabel(_ text: String) -> some View {
        Text(text)
            .productivityFont(.caption)
            .foregroundStyle(secondaryTextColor)
            .lineLimit(1)
            .monospacedDigit()
    }

    private var primaryTextColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.TrendCard.primaryTextDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.primaryTextLightOpacity)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.TrendCard.secondaryTextDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.secondaryTextLightOpacity)
    }

    private var trendAccentOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                accentColor.opacity(
                    colorScheme == .dark
                        ? ProductivityLayout.TrendCard.accentOverlayDarkOpacity
                        : ProductivityLayout.TrendCard.accentOverlayLightOpacity
                )
            )
    }
}

private struct ProductivityTrendChart: View {
    @Environment(\.colorScheme) private var colorScheme
    /// Room beneath the plot for the day labels, growing with them.
    @ScaledMetric(relativeTo: .caption2) private var labelRowHeight = ProductivityLayout.TrendCard.chartBottomPadding

    let metric: ProductivityChartMetricKind
    let buckets: [ProductivityDisplayBucket]
    let range: ProductivityRange
    @Binding var selectedSlot: Int?

    var body: some View {
        let axisStyle = metric.axisStyle(for: buckets)
        let bucketCount = max(buckets.count, 1)
        let slotDomain = -0.5...(Double(bucketCount) - 0.5)

        Chart(buckets) { bucket in
            let value = metric.bucketValue(for: bucket)

            BarMark(
                x: .value("Bucket", bucket.slotValue),
                y: .value(metric.title, value),
                width: .fixed(range.barWidth)
            )
            .clipShape(TopRoundedBarShape(radius: range.barTopCornerRadius))
            .foregroundStyle(metric.barFill(for: colorScheme))
            .opacity(barOpacity(for: bucket, value: value))
            .accessibilityLabel(ProductivityChartFormatting.selectionAccessibilityText(for: bucket, range: range))
            .accessibilityValue(metric.valueAccessibilityText(for: value))
        }
        .frame(height: ProductivityLayout.TrendCard.chartHeight)
        .padding(.bottom, labelRowHeight)
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
                        ProductivityAxisValueLabel(text: metric.axisLabelText(for: axisValue), color: secondaryTextColor)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let plotAnchor = proxy.plotFrame {
                    let plotFrame = geometry[plotAnchor]

                    ZStack(alignment: .topLeading) {
                        // Taps only, so a drag that starts on the chart still scrolls the page.
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                toggleSelection(atX: location.x - plotFrame.minX, plotWidth: plotFrame.width)
                            }
                            .accessibilityHidden(true)

                        ProductivityCustomXAxis(
                            buckets: buckets,
                            range: range,
                            plotFrame: plotFrame,
                            textColor: secondaryTextColor
                        )
                        .offset(y: plotFrame.maxY + ProductivityLayout.TrendCard.xAxisOffset)
                    }
                }
            }
        }
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.TrendCard.secondaryTextDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.secondaryTextLightOpacity)
    }

    private var gridColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(ProductivityLayout.TrendCard.gridDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.gridLightOpacity)
    }

    private func barOpacity(for bucket: ProductivityDisplayBucket, value: Double) -> Double {
        guard value > 0 else { return 0.10 }
        guard let selectedSlot else { return 1 }
        return bucket.slotIndex == selectedSlot ? 1 : ProductivityLayout.TrendCard.unselectedBarOpacity
    }

    /// Tapping a bar shows its day in every card; tapping it again, or the axis labels, returns to the totals.
    private func toggleSelection(atX x: CGFloat, plotWidth: CGFloat) {
        let slot = ProductivityChartDisplay.slotIndex(atX: x, plotWidth: plotWidth, slotCount: buckets.count)

        withAnimation(.easeOut(duration: 0.15)) {
            selectedSlot = slot == selectedSlot ? nil : slot
        }
    }
}

/// A fixed column keeps the three plots the same width, so days line up across cards.
private struct ProductivityAxisValueLabel: View {
    @ScaledMetric(relativeTo: .caption2) private var width = ProductivityLayout.ChartAxis.valueLabelWidth

    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .productivityFont(.axisLabel)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(ProductivityLayout.ChartAxis.labelMinimumScaleFactor)
            .frame(width: width, alignment: .leading)
    }
}

private struct ProductivityCustomXAxis: View {
    @ScaledMetric(relativeTo: .caption2) private var labelCenterY: CGFloat = 8

    let buckets: [ProductivityDisplayBucket]
    let range: ProductivityRange
    let plotFrame: CGRect
    let textColor: Color

    var body: some View {
        if hasValidPlotFrame {
            ZStack(alignment: .topLeading) {
                ForEach(Array(buckets.enumerated()), id: \.element.id) { index, bucket in
                    if range.showsAxisLabel(atSlot: index, slotCount: buckets.count) {
                        Text(ProductivityChartFormatting.xAxisLabel(for: bucket.labelDate, range: range))
                            .productivityFont(.axisLabel)
                            .foregroundStyle(textColor)
                            .lineLimit(1)
                            .minimumScaleFactor(ProductivityLayout.ChartAxis.labelMinimumScaleFactor)
                            .frame(width: labelWidth, alignment: .center)
                            .position(
                                x: plotFrame.minX + slotWidth * (CGFloat(index) + 0.5),
                                y: labelCenterY
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var hasValidPlotFrame: Bool {
        plotFrame.width.isFinite
            && plotFrame.height.isFinite
            && plotFrame.width > 0
            && plotFrame.height > 0
    }

    private var slotWidth: CGFloat {
        plotFrame.width / CGFloat(max(buckets.count, 1))
    }

    /// A sparse label may use the empty slots around it.
    private var labelWidth: CGFloat {
        slotWidth * CGFloat(range.axisLabelStride)
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

enum ProductivityChartMetricKind: CaseIterable, Identifiable {
    case focusSessions
    case focusTime
    case breakTime

    var id: String { title }

    var title: String {
        switch self {
        case .focusSessions:
            return "Focus Blocks"
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
        case .focusTime:
            return colorScheme == .dark ? VibePalette.amberGold : VibePalette.amberGoldDeep
        case .breakTime:
            return colorScheme == .dark ? VibePalette.softJade : VibePalette.softJadeDeep
        }
    }

    /// Light-mode text color for the card's title, badge, and bar values.
    var inkColor: Color {
        switch self {
        case .focusSessions:
            return VibePalette.softMistInk
        case .focusTime:
            return VibePalette.amberGoldInk
        case .breakTime:
            return VibePalette.softJadeInk
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
        case .focusTime, .breakTime:
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
        case .focusTime, .breakTime:
            return ProductivityChartFormatting.axisDurationText(value)
        }
    }

    /// One bar's value, shown in the card's figure while the bar is selected.
    func valueText(for value: Double) -> String {
        switch self {
        case .focusSessions:
            return "\(Int(value.rounded()))"
        case .focusTime, .breakTime:
            return ProductivityValueFormatting.compactDurationText(value)
        }
    }

    func valueAccessibilityText(for value: Double) -> String {
        switch self {
        case .focusSessions:
            let count = Int(value.rounded())
            return count == 1 ? "1 focus block" : "\(count) focus blocks"
        case .focusTime, .breakTime:
            return ProductivityValueFormatting.durationAccessibilityText(value)
        }
    }

    func axisStyle(for buckets: [ProductivityDisplayBucket]) -> ProductivityNumericAxisStyle {
        let maxValue = buckets.map(bucketValue(for:)).max() ?? 0

        switch self {
        case .focusSessions:
            return ProductivityChartFormatting.countAxisStyle(for: maxValue)
        case .focusTime, .breakTime:
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
}
