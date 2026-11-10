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
            .foregroundStyle(ProductivityTextColors.secondary(colorScheme))
            .monospacedDigit()
            .padding(.horizontal, ProductivityLayout.TrendGroup.captionHorizontalPadding)
            .accessibilityLabel("\(range.windowTitle), \(dates)")
    }
}

/// Focus and breaks per slot, stacked like layered liquid, with the range's totals above.
struct ProductivityRhythmCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let buckets: [ProductivityDisplayBucket]
    let range: ProductivityRange
    /// Shared with the sessions card, which lists the tapped slot's sessions.
    @Binding var selectedSlot: Int?

    private let contentInset = ProductivityLayout.TrendCard.contentInset
    private let cornerRadius = ProductivityLayout.TrendCard.cornerRadius

    private var selectedBucket: ProductivityDisplayBucket? {
        guard let selectedSlot, buckets.indices.contains(selectedSlot) else { return nil }
        return buckets[selectedSlot]
    }

    var body: some View {
        let isAccessibilitySize = dynamicTypeSize.isAccessibilitySize
        let rangeTotals = ProductivityRhythmTotals(buckets)
        let selected = selectedBucket
        let selectionText = selected.map { ProductivityChartFormatting.selectionText(for: $0, range: range) }

        VStack(alignment: .leading, spacing: ProductivityLayout.TrendCard.stackSpacing) {
            HStack(spacing: ProductivityLayout.TrendCard.headerSpacing) {
                Text("Rhythm")
                    .productivityFont(.cardTitle)
                    .foregroundStyle(ProductivityTextColors.primary(colorScheme))

                Spacer(minLength: ProductivityLayout.TrendCard.headerSpacing)

                if !isAccessibilitySize, let selectionText {
                    selectionLabel(selectionText)
                }
            }

            if isAccessibilitySize, let selectionText {
                selectionLabel(selectionText)
            }

            ProductivityRhythmStats(
                shown: selected.map { ProductivityRhythmTotals([$0]) } ?? rangeTotals,
                reference: rangeTotals,
                isStacked: isAccessibilitySize
            )

            ProductivityRhythmChart(buckets: buckets, range: range, selectedSlot: $selectedSlot)
                // Seven day names share the plot's width with the value column, so axis labels stop
                // growing at xxLarge; a tapped slot's date and figures, above, carry the detail at any size.
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
        .padding(.horizontal, contentInset)
        .padding(.vertical, contentInset)
        .productivityGlassCard(
            colorScheme: colorScheme,
            style: .trend(contentInset: contentInset, cornerRadius: cornerRadius)
        ) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    VibePalette.amberGold.opacity(
                        colorScheme == .dark
                            ? ProductivityLayout.TrendCard.accentOverlayDarkOpacity
                            : ProductivityLayout.TrendCard.accentOverlayLightOpacity
                    )
                )
        }
    }

    private func selectionLabel(_ text: String) -> some View {
        Text(text)
            .productivityFont(.caption)
            .foregroundStyle(ProductivityTextColors.secondary(colorScheme))
            .lineLimit(1)
            .monospacedDigit()
    }
}

/// Focus, Breaks, and Blocks, for the range or the tapped slot. The dots double as the chart's legend.
private struct ProductivityRhythmStats: View {
    @Environment(\.colorScheme) private var colorScheme

    let shown: ProductivityRhythmTotals
    /// The range's totals hold each column's width, so the row doesn't shift while a slot is selected.
    let reference: ProductivityRhythmTotals
    let isStacked: Bool

    private struct Stat: Identifiable {
        let title: String
        let dot: Color?
        let value: String
        let reference: String
        let role: ProductivityTextRole
        let accessibilityValue: String

        var id: String { title }
    }

    var body: some View {
        if isStacked {
            VStack(alignment: .leading, spacing: ProductivityLayout.RhythmStats.stackedSpacing) {
                ForEach(stats) { stat in
                    VStack(alignment: .leading, spacing: ProductivityLayout.RhythmStats.labelSpacing) {
                        label(stat)
                        value(stat)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(stat.title)
                    .accessibilityValue(stat.accessibilityValue)
                }
            }
        } else {
            Grid(
                alignment: .leading,
                horizontalSpacing: ProductivityLayout.RhythmStats.columnSpacing,
                verticalSpacing: ProductivityLayout.RhythmStats.labelSpacing
            ) {
                GridRow {
                    ForEach(stats) { stat in
                        label(stat)
                            .accessibilityHidden(true)
                    }
                }

                GridRow(alignment: .lastTextBaseline) {
                    ForEach(stats) { stat in
                        value(stat)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(stat.title)
                            .accessibilityValue(stat.accessibilityValue)
                    }
                }
            }
        }
    }

    private var stats: [Stat] {
        [
            Stat(
                title: "Focus",
                dot: ProductivityPhaseColors.focus(colorScheme),
                value: ProductivityValueFormatting.compactDurationText(shown.focusTime),
                reference: ProductivityValueFormatting.compactDurationText(reference.focusTime),
                role: .cardFigure,
                accessibilityValue: ProductivityValueFormatting.durationAccessibilityText(shown.focusTime)
            ),
            Stat(
                title: "Breaks",
                dot: ProductivityPhaseColors.breaks(colorScheme),
                value: ProductivityValueFormatting.compactDurationText(shown.breakTime),
                reference: ProductivityValueFormatting.compactDurationText(reference.breakTime),
                role: .statFigure,
                accessibilityValue: ProductivityValueFormatting.durationAccessibilityText(shown.breakTime)
            ),
            Stat(
                title: "Blocks",
                dot: nil,
                value: "\(shown.completedFocusCount)",
                reference: "\(reference.completedFocusCount)",
                role: .statFigure,
                accessibilityValue: ProductivityValueFormatting.focusBlockCountText(shown.completedFocusCount)
            )
        ]
    }

    private func label(_ stat: Stat) -> some View {
        HStack(spacing: ProductivityLayout.RhythmStats.dotSpacing) {
            if let dot = stat.dot {
                Circle()
                    .fill(dot)
                    .frame(width: ProductivityLayout.RhythmStats.dotSize, height: ProductivityLayout.RhythmStats.dotSize)
            }

            Text(stat.title)
                .productivityFont(.metricLabel)
                .foregroundStyle(ProductivityTextColors.secondary(colorScheme))
        }
    }

    private func value(_ stat: Stat) -> some View {
        ZStack(alignment: .leading) {
            Text(stat.reference)
                .hidden()
            Text(stat.value)
        }
        .productivityFont(stat.role)
        .foregroundStyle(ProductivityTextColors.primary(colorScheme))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(ProductivityLayout.RhythmStats.valueMinimumScaleFactor)
    }
}

private struct ProductivityRhythmChart: View {
    @Environment(\.colorScheme) private var colorScheme
    /// Room beneath the plot for the day labels, growing with them.
    @ScaledMetric(relativeTo: .caption2) private var labelRowHeight = ProductivityLayout.TrendCard.chartBottomPadding
    /// Room the "avg" marker keeps clear on the value axis, growing with the axis labels.
    @ScaledMetric(relativeTo: .caption2) private var averageLabelClearance = ProductivityLayout.RhythmChart.averageLabelClearance

    let buckets: [ProductivityDisplayBucket]
    let range: ProductivityRange
    @Binding var selectedSlot: Int?

    var body: some View {
        let axisStyle = ProductivityChartFormatting.timeAxisStyle(
            for: buckets.map { $0.focusTime + $0.breakTime }.max() ?? 0
        )
        let slotDomain = -0.5...(Double(max(buckets.count, 1)) - 0.5)
        let averageFocus = ProductivityRhythmTotals.averageFocus(over: buckets)
        // The liquid's surface line, two points of column height in data units.
        let surfaceHeight = axisStyle.upperBound * ProductivityLayout.RhythmChart.surfaceLineHeight
            / ProductivityLayout.TrendCard.chartHeight

        Chart {
            ForEach(buckets) { bucket in
                let total = bucket.focusTime + bucket.breakTime
                let opacity = barOpacity(for: bucket)

                // An invisible column spanning the whole slot carries it for VoiceOver. A tap on its
                // accessibility frame lands in the slot's own span; iOS 27 frames a mark placed at a single
                // x from that x to one slot further, which would put the tap on the next slot.
                BarMark(
                    xStart: .value("Slot start", bucket.slotValue - 0.5),
                    xEnd: .value("Slot end", bucket.slotValue + 0.5)
                )
                .foregroundStyle(Color.clear)
                .accessibilityLabel(ProductivityChartFormatting.selectionAccessibilityText(for: bucket, range: range))
                .accessibilityValue(ProductivityRhythmTotals([bucket]).accessibilityText)

                // Week and Year draw an empty glass in every slot, so a day without focus still shows its place.
                BarMark(
                    x: .value("Slot", bucket.slotValue),
                    yStart: .value("Track start", 0),
                    yEnd: .value("Track end", axisStyle.upperBound),
                    width: .fixed(range.barWidth)
                )
                .clipShape(TopRoundedBarShape(radius: range.barTopCornerRadius + ProductivityLayout.RhythmChart.trackCornerExtra))
                .foregroundStyle(range.showsBarTracks ? trackColor : Color.clear)
                .accessibilityHidden(true)

                if bucket.focusTime > 0 {
                    BarMark(
                        x: .value("Slot", bucket.slotValue),
                        yStart: .value("Focus start", 0),
                        yEnd: .value("Focus", bucket.focusTime),
                        width: .fixed(range.barWidth)
                    )
                    .clipShape(TopRoundedBarShape(radius: bucket.breakTime > 0 ? 0 : range.barTopCornerRadius))
                    .foregroundStyle(focusFill)
                    .opacity(opacity)
                    .accessibilityHidden(true)
                }

                if bucket.breakTime > 0 {
                    BarMark(
                        x: .value("Slot", bucket.slotValue),
                        yStart: .value("Breaks start", bucket.focusTime),
                        yEnd: .value("Breaks", total),
                        width: .fixed(range.barWidth)
                    )
                    .clipShape(TopRoundedBarShape(radius: range.barTopCornerRadius))
                    .foregroundStyle(breakFill)
                    .opacity(opacity)
                    .accessibilityHidden(true)
                }

                if total > surfaceHeight * 2 {
                    BarMark(
                        x: .value("Slot", bucket.slotValue),
                        yStart: .value("Surface start", total - surfaceHeight),
                        yEnd: .value("Surface", total),
                        width: .fixed(range.barWidth)
                    )
                    .clipShape(TopRoundedBarShape(radius: range.barTopCornerRadius))
                    .foregroundStyle(surfaceFill)
                    .opacity(opacity)
                    .accessibilityHidden(true)
                }
            }

            if averageFocus > 0 {
                RuleMark(y: .value("Average focus", averageFocus))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(averageColor)
                    .accessibilityLabel("Average focus")
                    .accessibilityValue(ProductivityValueFormatting.durationAccessibilityText(averageFocus))
            }
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
                    // The average's marker takes this column; a step label right beside it steps aside.
                    if let axisValue = value.as(Double.self),
                       !isNearAverage(axisValue, averageFocus: averageFocus, upperBound: axisStyle.upperBound) {
                        ProductivityAxisValueLabel(
                            text: ProductivityChartFormatting.axisDurationText(axisValue),
                            color: ProductivityTextColors.secondary(colorScheme)
                        )
                    }
                }
            }

            AxisMarks(position: .trailing, values: averageFocus > 0 ? [averageFocus] : []) { _ in
                AxisValueLabel {
                    ProductivityAxisValueLabel(text: "avg", color: averageColor)
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
                            textColor: ProductivityTextColors.secondary(colorScheme)
                        )
                        .offset(y: plotFrame.maxY + ProductivityLayout.TrendCard.xAxisOffset)
                    }
                }
            }
        }
    }

    /// The plot fills the chart's height, so points convert to axis units by that height.
    private func isNearAverage(_ value: Double, averageFocus: Double, upperBound: Double) -> Bool {
        guard averageFocus > 0 else { return false }
        let clearance = upperBound * Double(averageLabelClearance / ProductivityLayout.TrendCard.chartHeight)
        return abs(value - averageFocus) <= clearance
    }

    private func barOpacity(for bucket: ProductivityDisplayBucket) -> Double {
        guard let selectedSlot else { return 1 }
        return bucket.slotIndex == selectedSlot ? 1 : ProductivityLayout.TrendCard.unselectedBarOpacity
    }

    /// Tapping a slot shows it in the stats and the sessions; tapping it again, or the axis labels, returns to the range.
    private func toggleSelection(atX x: CGFloat, plotWidth: CGFloat) {
        let slot = ProductivityChartDisplay.slotIndex(atX: x, plotWidth: plotWidth, slotCount: buckets.count)

        withAnimation(.easeOut(duration: 0.15)) {
            selectedSlot = slot == selectedSlot ? nil : slot
        }
    }

    private var isDark: Bool { colorScheme == .dark }

    /// Deeper toward the bottom, like the Focus vessel's liquid: the longer the light's path, the more tint.
    private var focusFill: LinearGradient {
        LinearGradient(
            colors: [
                VibePalette.amberGold.opacity(isDark ? 0.82 : 0.70),
                VibePalette.amberGoldDeep.opacity(isDark ? 0.98 : 0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var breakFill: LinearGradient {
        LinearGradient(
            colors: [
                VibePalette.softJade.opacity(isDark ? 0.72 : 0.62),
                VibePalette.softJadeDeep.opacity(isDark ? 0.92 : 0.86)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Light along the liquid's surface, fading toward the column's walls rather than outlining it.
    private var surfaceFill: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0), .white.opacity(isDark ? 0.55 : 0.75), .white.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var trackColor: Color {
        isDark
            ? Color.white.opacity(ProductivityLayout.RhythmChart.trackDarkOpacity)
            : Color.black.opacity(ProductivityLayout.RhythmChart.trackLightOpacity)
    }

    /// The dashed line and its "avg" label share the focus labels' amber.
    private var averageColor: ContrastAdaptiveColor {
        ProductivityTextColors.focus(colorScheme)
    }

    private var gridColor: Color {
        isDark
            ? Color.white.opacity(ProductivityLayout.TrendCard.gridDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.gridLightOpacity)
    }
}

/// A fixed column keeps the plot's width steady whatever the axis reads.
private struct ProductivityAxisValueLabel: View {
    @ScaledMetric(relativeTo: .caption2) private var width = ProductivityLayout.ChartAxis.valueLabelWidth

    let text: String
    let color: ContrastAdaptiveColor

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
    let textColor: ContrastAdaptiveColor

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
