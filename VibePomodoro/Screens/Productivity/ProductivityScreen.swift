import SwiftUI

enum ProductivityLayout {
    static let sectionSpacing: CGFloat = 14
    static let pageHorizontalInset: CGFloat = 18
    static let pageTopInset: CGFloat = 12
    static let pageBottomInset: CGFloat = 60

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

private struct ProductivityRenderState: Equatable {
    let selectedRange: ProductivityRange
    let snapshot: ProductivityMetricsSnapshot
    let displayBuckets: [ProductivityDisplayBucket]

    static func build(store: PomodoroStore, selectedRange: ProductivityRange) -> Self {
        let snapshot = store.productivitySnapshot(for: selectedRange)

        return ProductivityRenderState(
            selectedRange: selectedRange,
            snapshot: snapshot,
            displayBuckets: ProductivityChartDisplay.displayBuckets(
                from: snapshot.chartPoints,
                range: selectedRange
            )
        )
    }

    var showsEmptyState: Bool {
        snapshot.completedSessionCount == 0
    }

    var trendTopInset: CGFloat {
        showsEmptyState
            ? ProductivityLayout.TrendGroup.emptyTopInset
            : ProductivityLayout.TrendGroup.populatedTopInset
    }
}

struct ProductivityScreen: View {
    @EnvironmentObject private var store: PomodoroStore
    @State private var selectedRange: ProductivityRange = .week

    var body: some View {
        let renderState = ProductivityRenderState.build(store: store, selectedRange: selectedRange)

        NavigationStack {
            ZStack {
                VibeBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: ProductivityLayout.sectionSpacing) {
                        ProductivitySummaryStrip(snapshot: renderState.snapshot)

                        if renderState.showsEmptyState {
                            ProductivityEmptyStateNote()
                        }

                        VStack(alignment: .leading, spacing: ProductivityLayout.sectionSpacing) {
                            ForEach(ProductivityChartMetricKind.allCases) { metric in
                                ProductivityTrendCard(
                                    metric: metric,
                                    buckets: renderState.displayBuckets,
                                    range: renderState.selectedRange
                                )
                            }
                        }
                        .padding(.top, renderState.trendTopInset)
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
}

private struct ProductivityRangeToolbarMenu: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selectedRange: ProductivityRange

    var body: some View {
        Menu {
            ForEach(ProductivityRange.allCases) { range in
                Button {
                    selectRange(range)
                } label: {
                    ProductivityRangeMenuItemLabel(
                        title: range.displayTitle,
                        isSelected: selectedRange == range
                    )
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

    private func selectRange(_ range: ProductivityRange) {
        selectedRange = range
    }
}

private struct ProductivityRangeMenuItemLabel: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(title)

            Spacer(minLength: 12)

            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}
