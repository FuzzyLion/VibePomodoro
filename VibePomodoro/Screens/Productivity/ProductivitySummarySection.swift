import SwiftUI

struct ProductivitySummaryStrip: View {
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
                .productivityFont(.footnote)
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
            .productivityFont(.sectionLabel)
            .foregroundStyle(headerTextColor)
            .tracking(ProductivityLayout.SummaryCard.titleTracking)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            .minimumScaleFactor(0.92)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1)
    }

    private var metaSummaryText: String {
        ProductivityValueFormatting.summaryMetaText(
            completedSessionCount: snapshot.completedSessionCount,
            completedFocusCount: snapshot.completedFocusCount
        )
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
            : VibePalette.amberGoldInk
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
                .productivityFont(.sectionLabel)
                .foregroundStyle(titleColor)
                .textCase(.uppercase)
                .tracking(ProductivityLayout.PrimaryMetric.titleTracking)

            Text(value)
                .productivityFont(.primaryFigure)
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
            : VibePalette.softJadeInk
    }

    private var streakTitleColor: Color {
        colorScheme == .dark
            ? VibePalette.softMist.opacity(ProductivityLayout.SecondaryMetrics.titleDarkOpacity)
            : VibePalette.softMistInk
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let value: String
    let accessibilityValue: String
    let titleColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: ProductivityLayout.SecondaryMetrics.valueSpacing) {
            Text(title)
                .productivityFont(.metricLabel)
                .foregroundStyle(titleColor)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .minimumScaleFactor(ProductivityLayout.SecondaryMetrics.labelMinimumScaleFactor)

            Text(value)
                .productivityFont(.secondaryFigure)
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

struct ProductivityEmptyStateNote: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("Sessions appear here once they end, including ones you finish early. A session in progress isn't counted until then.")
            .productivityFont(.caption)
            .foregroundStyle(textColor)
            .padding(.horizontal, ProductivityLayout.EmptyState.horizontalPadding)
            .padding(.top, ProductivityLayout.EmptyState.topPadding)
            .padding(.bottom, ProductivityLayout.EmptyState.bottomPadding)
    }

    /// Same gray as the range line beneath it, so the two read as one block.
    private var textColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.TrendCard.secondaryTextDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.secondaryTextLightOpacity)
    }
}
