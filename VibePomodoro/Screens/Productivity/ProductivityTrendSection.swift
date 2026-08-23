import Charts
import SwiftUI

struct ProductivityTrendCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let metric: ProductivityChartMetricKind
    let buckets: [ProductivityDisplayBucket]
    let range: ProductivityRange

    private let contentInset = ProductivityLayout.TrendCard.contentInset
    private let cornerRadius = ProductivityLayout.TrendCard.cornerRadius

    private var accentColor: Color {
        metric.accentColor(for: colorScheme)
    }

    private var accentLabelColor: Color {
        accentColor.opacity(
            colorScheme == .dark
                ? ProductivityLayout.TrendCard.accentLabelDarkOpacity
                : ProductivityLayout.TrendCard.accentLabelLightOpacity
        )
    }

    var body: some View {
        let axisStyle = metric.axisStyle(for: buckets)
        let bucketCount = max(buckets.count, 1)
        let slotDomain = -0.5...(Double(bucketCount) - 0.5)
        let rangeValueText = metric.rangeValueText(from: buckets)

        VStack(alignment: .leading, spacing: ProductivityLayout.TrendCard.stackSpacing) {
            HStack(spacing: ProductivityLayout.TrendCard.headerSpacing) {
                Image(systemName: metric.systemImage)
                    .font(.system(size: ProductivityLayout.TrendCard.iconSize, weight: .semibold))
                    .foregroundStyle(accentLabelColor)
                    .frame(
                        width: ProductivityLayout.TrendCard.iconFrame,
                        height: ProductivityLayout.TrendCard.iconFrame
                    )
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

            Text(rangeValueText)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(primaryTextColor)
                .minimumScaleFactor(0.76)
                .lineLimit(1)
                .monospacedDigit()

            Chart(buckets) { bucket in
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
            .frame(height: ProductivityLayout.TrendCard.chartHeight)
            .padding(.bottom, ProductivityLayout.TrendCard.chartBottomPadding)
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
                            buckets: buckets,
                            range: range,
                            plotFrame: geometry[plotFrame],
                            textColor: secondaryTextColor
                        )
                        .offset(y: geometry[plotFrame].maxY + ProductivityLayout.TrendCard.xAxisOffset)
                    }
                }
            }
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

    private var gridColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(ProductivityLayout.TrendCard.gridDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.gridLightOpacity)
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
            .tracking(ProductivityLayout.RangeBadge.titleTracking)
            .padding(.horizontal, ProductivityLayout.RangeBadge.horizontalPadding)
            .padding(.vertical, ProductivityLayout.RangeBadge.verticalPadding)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        tint.opacity(
                            colorScheme == .dark
                                ? ProductivityLayout.RangeBadge.fillDarkOpacity
                                : ProductivityLayout.RangeBadge.fillLightOpacity
                        )
                    )
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(
                        tint.opacity(
                            colorScheme == .dark
                                ? ProductivityLayout.RangeBadge.strokeDarkOpacity
                                : ProductivityLayout.RangeBadge.strokeLightOpacity
                        ),
                        lineWidth: ProductivityLayout.RangeBadge.strokeWidth
                    )
            }
    }

    private var badgeTextColor: Color {
        colorScheme == .dark
            ? tint.opacity(ProductivityLayout.RangeBadge.textDarkOpacity)
            : tint.opacity(ProductivityLayout.RangeBadge.textLightOpacity)
    }
}

private struct ProductivityCustomXAxis: View {
    let buckets: [ProductivityDisplayBucket]
    let range: ProductivityRange
    let plotFrame: CGRect
    let textColor: Color

    var body: some View {
        if hasValidPlotFrame {
            ZStack(alignment: .topLeading) {
                ForEach(Array(buckets.enumerated()), id: \.element.id) { index, bucket in
                    Text(ProductivityChartFormatting.xAxisLabel(for: bucket.labelDate, range: range))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(ProductivityLayout.ChartAxis.labelMinimumScaleFactor)
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

    private var hasValidPlotFrame: Bool {
        plotFrame.width.isFinite
            && plotFrame.height.isFinite
            && plotFrame.width > 0
            && plotFrame.height > 0
    }

    private var slotWidth: CGFloat {
        plotFrame.width / CGFloat(max(buckets.count, 1))
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
            return "Focus Sessions"
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

    func annotationText(for value: Double) -> String {
        switch self {
        case .focusSessions:
            return "\(Int(value.rounded()))"
        case .focusTime, .breakTime:
            return ProductivityChartFormatting.annotationDurationText(value)
        }
    }

    func axisStyle(for buckets: [ProductivityDisplayBucket]) -> ProductivityNumericAxisStyle {
        let maxValue = buckets.map(bucketValue(for:)).max() ?? 0

        switch self {
        case .focusSessions:
            return Self.countAxisStyle(for: maxValue)
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
