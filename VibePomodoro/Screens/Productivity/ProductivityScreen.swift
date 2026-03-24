import Charts
import SwiftUI

private enum ProductivityLayout {
    static let sectionSpacing: CGFloat = 14
    static let pageHorizontalInset: CGFloat = 18
    static let pageTopInset: CGFloat = 12
    static let pageBottomInset: CGFloat = 28

    enum TrendGroup {
        static let populatedTopInset: CGFloat = 8
        static let emptyTopInset: CGFloat = 4
    }

    enum SummaryCard {
        static let contentInset: CGFloat = 20
        static let cornerRadius: CGFloat = 28
        static let stackSpacing: CGFloat = 17
        static let verticalPadding: CGFloat = 20
        static let titleTracking: CGFloat = 0.72
        static let titleDarkOpacity: Double = 0.54
        static let titleLightOpacity: Double = 0.45
        static let valueDarkOpacity: Double = 0.98
        static let valueLightOpacity: Double = 0.84
        static let metaDarkOpacity: Double = 0.64
        static let metaLightOpacity: Double = 0.52
        static let dividerDarkOpacity: Double = 0.10
        static let dividerLightOpacity: Double = 0.08
        static let accentDarkOpacity: Double = 0.94
        static let accentLightOpacity: Double = 0.94
        static let accentGlowDarkPrimaryOpacity: Double = 0.12
        static let accentGlowLightPrimaryOpacity: Double = 0.07
        static let accentGlowDarkSecondaryOpacity: Double = 0.05
        static let accentGlowLightSecondaryOpacity: Double = 0.025
        static let accentGlowStartRadius: CGFloat = 10
        static let accentGlowEndRadius: CGFloat = 220
    }

    enum PrimaryMetric {
        static let spacing: CGFloat = 10
        static let titleTracking: CGFloat = 0.65
        static let accessibilityValueFontSize: CGFloat = 36
        static let defaultValueFontSize: CGFloat = 44
        static let accessibilityMinimumScaleFactor: CGFloat = 0.9
        static let defaultMinimumScaleFactor: CGFloat = 0.72
    }

    enum SecondaryMetrics {
        static let accessibilitySpacing: CGFloat = 14
        static let standardSpacing: CGFloat = 16
        static let valueSpacing: CGFloat = 6
        static let titleDarkOpacity: Double = 0.94
        static let titleLightOpacity: Double = 0.94
        static let dividerDarkOpacity: Double = 0.10
        static let dividerLightOpacity: Double = 0.08
        static let valueDarkOpacity: Double = 0.94
        static let valueLightOpacity: Double = 0.78
        static let labelMinimumScaleFactor: CGFloat = 0.85
        static let valueMinimumScaleFactor: CGFloat = 0.78
        static let verticalDividerHeight: CGFloat = 42
    }

    enum EmptyState {
        static let horizontalPadding: CGFloat = 6
        static let topPadding: CGFloat = 2
        static let bottomPadding: CGFloat = 4
    }

    enum TrendCard {
        static let contentInset: CGFloat = 18
        static let cornerRadius: CGFloat = 26
        static let stackSpacing: CGFloat = 14
        static let headerSpacing: CGFloat = 10
        static let iconSize: CGFloat = 15
        static let iconFrame: CGFloat = 36
        static let iconCornerRadius: CGFloat = 12
        static let iconChipDarkOpacity: Double = 0.085
        static let iconChipLightOpacity: Double = 0.058
        static let accentLabelDarkOpacity: Double = 0.90
        static let accentLabelLightOpacity: Double = 0.84
        static let primaryTextDarkOpacity: Double = 0.94
        static let primaryTextLightOpacity: Double = 0.80
        static let secondaryTextDarkOpacity: Double = 0.54
        static let secondaryTextLightOpacity: Double = 0.48
        static let gridDarkOpacity: Double = 0.10
        static let gridLightOpacity: Double = 0.08
        static let accentOverlayDarkOpacity: Double = 0.022
        static let accentOverlayLightOpacity: Double = 0.010
        static let chartHeight: CGFloat = 186
        static let chartBottomPadding: CGFloat = 22
        static let xAxisOffset: CGFloat = 8
    }

    enum RangeBadge {
        static let titleTracking: CGFloat = 0.45
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 6
        static let fillDarkOpacity: Double = 0.16
        static let fillLightOpacity: Double = 0.10
        static let strokeDarkOpacity: Double = 0.18
        static let strokeLightOpacity: Double = 0.10
        static let textDarkOpacity: Double = 0.95
        static let textLightOpacity: Double = 0.88
        static let strokeWidth: CGFloat = 0.8
    }

    enum ChartAxis {
        static let labelMinimumScaleFactor: CGFloat = 0.72
    }
}

struct ProductivityScreen: View {
    @EnvironmentObject private var store: PomodoroStore
    @State private var selectedRange: ProductivityRange = .week

    private var renderState: ProductivityMetricsSnapshot {
        store.productivitySnapshot(for: selectedRange)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: ProductivityLayout.sectionSpacing) {
                    ProductivitySummaryStrip(snapshot: renderState)

                    if renderState.completedSessionCount == 0 {
                        ProductivityEmptyStateNote()
                    }

                    VStack(alignment: .leading, spacing: ProductivityLayout.sectionSpacing) {
                        ForEach(ProductivityChartMetricKind.allCases) { metric in
                            ProductivityTrendCard(
                                metric: metric,
                                snapshot: renderState,
                                range: selectedRange
                            )
                        }
                    }
                    .padding(
                        .top,
                        renderState.completedSessionCount == 0
                            ? ProductivityLayout.TrendGroup.emptyTopInset
                            : ProductivityLayout.TrendGroup.populatedTopInset
                    )
                }
                .padding(.horizontal, ProductivityLayout.pageHorizontalInset)
                .padding(.top, ProductivityLayout.pageTopInset)
                .padding(.bottom, ProductivityLayout.pageBottomInset)
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

private struct ProductivityCardChromeStyle {
    let cornerRadius: CGFloat
    let highlightHorizontalInset: CGFloat
    let borderLineWidth: CGFloat
    let borderDarkOpacity: Double
    let borderLightOpacity: Double
    let highlightDarkOpacity: Double
    let highlightLightOpacity: Double
    let shadowDarkOpacity: Double
    let shadowLightOpacity: Double
    let shadowDarkRadius: CGFloat
    let shadowLightRadius: CGFloat
    let shadowDarkYOffset: CGFloat
    let shadowLightYOffset: CGFloat
    let surfaceDarkTopOpacity: Double
    let surfaceLightTopOpacity: Double
    let surfaceDarkBottomOpacity: Double
    let surfaceLightBottomOpacity: Double

    static func summary(contentInset: CGFloat, cornerRadius: CGFloat) -> Self {
        ProductivityCardChromeStyle(
            cornerRadius: cornerRadius,
            highlightHorizontalInset: contentInset,
            borderLineWidth: 0.85,
            borderDarkOpacity: 0.15,
            borderLightOpacity: 0.66,
            highlightDarkOpacity: 0.12,
            highlightLightOpacity: 0.46,
            shadowDarkOpacity: 0.13,
            shadowLightOpacity: 0.05,
            shadowDarkRadius: 16,
            shadowLightRadius: 10,
            shadowDarkYOffset: 8,
            shadowLightYOffset: 5,
            surfaceDarkTopOpacity: 0.035,
            surfaceLightTopOpacity: 0.20,
            surfaceDarkBottomOpacity: 0.01,
            surfaceLightBottomOpacity: 0.08
        )
    }

    static func trend(contentInset: CGFloat, cornerRadius: CGFloat) -> Self {
        ProductivityCardChromeStyle(
            cornerRadius: cornerRadius,
            highlightHorizontalInset: contentInset,
            borderLineWidth: 0.75,
            borderDarkOpacity: 0.13,
            borderLightOpacity: 0.60,
            highlightDarkOpacity: 0.08,
            highlightLightOpacity: 0.40,
            shadowDarkOpacity: 0.10,
            shadowLightOpacity: 0.04,
            shadowDarkRadius: 14,
            shadowLightRadius: 8,
            shadowDarkYOffset: 7,
            shadowLightYOffset: 4,
            surfaceDarkTopOpacity: 0,
            surfaceLightTopOpacity: 0,
            surfaceDarkBottomOpacity: 0,
            surfaceLightBottomOpacity: 0
        )
    }

    func borderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(borderDarkOpacity) : Color.white.opacity(borderLightOpacity)
    }

    func topHighlightGradient(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? highlightDarkOpacity : highlightLightOpacity),
                Color.white.opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func shadowColor(for colorScheme: ColorScheme) -> Color {
        Color.black.opacity(colorScheme == .dark ? shadowDarkOpacity : shadowLightOpacity)
    }

    func shadowRadius(for colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? shadowDarkRadius : shadowLightRadius
    }

    func shadowYOffset(for colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? shadowDarkYOffset : shadowLightYOffset
    }

    func surfaceGradient(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? surfaceDarkTopOpacity : surfaceLightTopOpacity),
                Color.white.opacity(colorScheme == .dark ? surfaceDarkBottomOpacity : surfaceLightBottomOpacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct ProductivityGlassCardModifier<AccentOverlay: View>: ViewModifier {
    let colorScheme: ColorScheme
    let style: ProductivityCardChromeStyle
    let accentOverlay: AccentOverlay

    func body(content: Content) -> some View {
        content
            .background(cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .strokeBorder(style.borderColor(for: colorScheme), lineWidth: style.borderLineWidth)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .fill(style.topHighlightGradient(for: colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, style.highlightHorizontalInset)
            }
            .shadow(
                color: style.shadowColor(for: colorScheme),
                radius: style.shadowRadius(for: colorScheme),
                y: style.shadowYOffset(for: colorScheme)
            )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
            .fill(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .fill(style.surfaceGradient(for: colorScheme))
            }
            .overlay {
                accentOverlay
            }
    }
}

private extension View {
    func productivityGlassCard<AccentOverlay: View>(
        colorScheme: ColorScheme,
        style: ProductivityCardChromeStyle,
        @ViewBuilder accentOverlay: () -> AccentOverlay
    ) -> some View {
        modifier(
            ProductivityGlassCardModifier(
                colorScheme: colorScheme,
                style: style,
                accentOverlay: accentOverlay()
            )
        )
    }
}

private struct ProductivitySummaryStrip: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let snapshot: ProductivityMetricsSnapshot
    private let contentInset = ProductivityLayout.SummaryCard.contentInset
    private let cornerRadius = ProductivityLayout.SummaryCard.cornerRadius

    var body: some View {
        VStack(alignment: .leading, spacing: ProductivityLayout.SummaryCard.stackSpacing) {
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
        .padding(.vertical, ProductivityLayout.SummaryCard.verticalPadding)
        .productivityGlassCard(
            colorScheme: colorScheme,
            style: .summary(contentInset: contentInset, cornerRadius: cornerRadius)
        ) {
            summaryAccentOverlay
        }
    }

    private var header: some View {
        Text("ALL TIME COMPLETED SESSIONS")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(headerTextColor)
            .tracking(ProductivityLayout.SummaryCard.titleTracking)
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
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.SummaryCard.titleDarkOpacity)
            : Color.black.opacity(ProductivityLayout.SummaryCard.titleLightOpacity)
    }

    private var primaryValueColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.SummaryCard.valueDarkOpacity)
            : Color.black.opacity(ProductivityLayout.SummaryCard.valueLightOpacity)
    }

    private var metaTextColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.SummaryCard.metaDarkOpacity)
            : Color.black.opacity(ProductivityLayout.SummaryCard.metaLightOpacity)
    }

    private var dividerColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(ProductivityLayout.SummaryCard.dividerDarkOpacity)
            : Color.black.opacity(ProductivityLayout.SummaryCard.dividerLightOpacity)
    }

    private var sessionTitleColor: Color {
        colorScheme == .dark
            ? VibePalette.warmAmberAccent.opacity(ProductivityLayout.SummaryCard.accentDarkOpacity)
            : VibePalette.warmAmberAccentDeep.opacity(ProductivityLayout.SummaryCard.accentLightOpacity)
    }

    private var summaryAccentOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [
                        VibePalette.warmAmberAccent.opacity(
                            colorScheme == .dark
                                ? ProductivityLayout.SummaryCard.accentGlowDarkPrimaryOpacity
                                : ProductivityLayout.SummaryCard.accentGlowLightPrimaryOpacity
                        ),
                        VibePalette.warmAmberAccent.opacity(
                            colorScheme == .dark
                                ? ProductivityLayout.SummaryCard.accentGlowDarkSecondaryOpacity
                                : ProductivityLayout.SummaryCard.accentGlowLightSecondaryOpacity
                        ),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: ProductivityLayout.SummaryCard.accentGlowStartRadius,
                    endRadius: ProductivityLayout.SummaryCard.accentGlowEndRadius
                )
            )
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
        VStack(alignment: .leading, spacing: ProductivityLayout.PrimaryMetric.spacing) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(titleColor)
                .textCase(.uppercase)
                .tracking(ProductivityLayout.PrimaryMetric.titleTracking)

            Text(value)
                .font(
                    .system(
                        size: dynamicTypeSize.isAccessibilitySize
                            ? ProductivityLayout.PrimaryMetric.accessibilityValueFontSize
                            : ProductivityLayout.PrimaryMetric.defaultValueFontSize,
                        weight: .semibold
                    )
                )
                .foregroundStyle(valueColor)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(
                    dynamicTypeSize.isAccessibilitySize
                        ? ProductivityLayout.PrimaryMetric.accessibilityMinimumScaleFactor
                        : ProductivityLayout.PrimaryMetric.defaultMinimumScaleFactor
                )
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
                accessibilityLayout
            } else {
                standardLayout
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metrics: [ProductivitySecondaryMetricDescriptor] {
        [
            ProductivitySecondaryMetricDescriptor(
                title: "Daily Focus Avg",
                value: ProductivityValueFormatting.summaryAverageFocusText(snapshot.averageFocusHoursPerDay),
                accessibilityValue: ProductivityValueFormatting.summaryAverageFocusActiveDayAccessibilityValue(snapshot.averageFocusHoursPerDay),
                titleColor: averageTitleColor
            ),
            ProductivitySecondaryMetricDescriptor(
                title: "Streak",
                value: ProductivityValueFormatting.summaryStreakText(snapshot.streakLength),
                accessibilityValue: ProductivityValueFormatting.summaryStreakAccessibilityValue(snapshot.streakLength),
                titleColor: streakTitleColor
            )
        ]
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: ProductivityLayout.SecondaryMetrics.accessibilitySpacing) {
            ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                secondaryMetric(metric)

                if index < metrics.count - 1 {
                    horizontalDivider
                }
            }
        }
    }

    private var standardLayout: some View {
        HStack(alignment: .top, spacing: ProductivityLayout.SecondaryMetrics.standardSpacing) {
            ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                secondaryMetric(metric)

                if index < metrics.count - 1 {
                    verticalDivider
                }
            }
        }
    }

    @ViewBuilder
    private func secondaryMetric(_ metric: ProductivitySecondaryMetricDescriptor) -> some View {
        ProductivitySecondarySummaryItem(
            title: metric.title,
            value: metric.value,
            accessibilityValue: metric.accessibilityValue,
            titleColor: metric.titleColor,
            colorScheme: colorScheme
        )
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(width: 1, height: ProductivityLayout.SecondaryMetrics.verticalDividerHeight)
            .frame(maxHeight: .infinity, alignment: .center)
    }

    private var horizontalDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1)
    }

    private var dividerColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(ProductivityLayout.SecondaryMetrics.dividerDarkOpacity)
            : Color.black.opacity(ProductivityLayout.SecondaryMetrics.dividerLightOpacity)
    }

    private var averageTitleColor: Color {
        colorScheme == .dark
            ? VibePalette.softJade.opacity(ProductivityLayout.SecondaryMetrics.titleDarkOpacity)
            : VibePalette.softJadeDeep.opacity(ProductivityLayout.SecondaryMetrics.titleLightOpacity)
    }

    private var streakTitleColor: Color {
        colorScheme == .dark
            ? VibePalette.softMist.opacity(ProductivityLayout.SecondaryMetrics.titleDarkOpacity)
            : VibePalette.softMistDeep.opacity(ProductivityLayout.SecondaryMetrics.titleLightOpacity)
    }
}

private struct ProductivitySecondaryMetricDescriptor: Identifiable {
    let title: String
    let value: String
    let accessibilityValue: String
    let titleColor: Color

    var id: String { title }
}

private struct ProductivitySecondarySummaryItem: View {
    let title: String
    let value: String
    let accessibilityValue: String
    let titleColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: ProductivityLayout.SecondaryMetrics.valueSpacing) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(titleColor)
                .lineLimit(2)
                .minimumScaleFactor(ProductivityLayout.SecondaryMetrics.labelMinimumScaleFactor)

            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(ProductivityLayout.SecondaryMetrics.valueMinimumScaleFactor)
                .lineLimit(1)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
    }

    private var valueColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.SecondaryMetrics.valueDarkOpacity)
            : Color.black.opacity(ProductivityLayout.SecondaryMetrics.valueLightOpacity)
    }
}

private struct ProductivityEmptyStateNote: View {
    var body: some View {
        Text("Complete a full session to start filling these charts. Productivity only reflects finished sessions.")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, ProductivityLayout.EmptyState.horizontalPadding)
            .padding(.top, ProductivityLayout.EmptyState.topPadding)
            .padding(.bottom, ProductivityLayout.EmptyState.bottomPadding)
    }
}

private struct ProductivityTrendCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let metric: ProductivityChartMetricKind
    let snapshot: ProductivityMetricsSnapshot
    let range: ProductivityRange

    private let contentInset = ProductivityLayout.TrendCard.contentInset
    private let cornerRadius = ProductivityLayout.TrendCard.cornerRadius

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
        accentColor.opacity(
            colorScheme == .dark
                ? ProductivityLayout.TrendCard.accentLabelDarkOpacity
                : ProductivityLayout.TrendCard.accentLabelLightOpacity
        )
    }

    var body: some View {
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
                            buckets: displayBuckets,
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
        let slotWidth = plotFrame.width / CGFloat(max(buckets.count, 1))

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

private enum ProductivityChartMetricKind: CaseIterable, Identifiable {
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
