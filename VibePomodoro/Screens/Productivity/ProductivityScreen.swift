import SwiftUI

enum ProductivityLayout {
    static let sectionSpacing: CGFloat = 14
    static let pageHorizontalInset: CGFloat = 18
    static let pageTopInset: CGFloat = 12
    static let pageBottomInset: CGFloat = 60

    enum TrendGroup {
        static let populatedTopInset: CGFloat = 8
        static let emptyTopInset: CGFloat = 4
        static let captionSpacing: CGFloat = 10
        static let captionHorizontalPadding: CGFloat = 6
    }

    enum SummaryCard {
        static let contentInset: CGFloat = 20
        static let cornerRadius: CGFloat = 28
        static let stackSpacing: CGFloat = 17
        static let verticalPadding: CGFloat = 20
        static let titleTracking: CGFloat = 0.72
        static let dividerDarkOpacity: Double = 0.10
        static let dividerLightOpacity: Double = 0.08
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
        static let accessibilityMinimumScaleFactor: CGFloat = 0.9
        static let defaultMinimumScaleFactor: CGFloat = 0.72
    }

    enum SecondaryMetrics {
        static let accessibilitySpacing: CGFloat = 14
        static let standardSpacing: CGFloat = 16
        static let valueSpacing: CGFloat = 6
        static let dividerDarkOpacity: Double = 0.10
        static let dividerLightOpacity: Double = 0.08
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
        static let gridDarkOpacity: Double = 0.10
        static let gridLightOpacity: Double = 0.08
        static let accentOverlayDarkOpacity: Double = 0.022
        static let accentOverlayLightOpacity: Double = 0.010
        static let chartHeight: CGFloat = 186
        static let chartBottomPadding: CGFloat = 22
        static let xAxisOffset: CGFloat = 8
        static let unselectedBarOpacity: Double = 0.32
    }

    enum RhythmStats {
        static let columnSpacing: CGFloat = 24
        static let labelSpacing: CGFloat = 6
        static let stackedSpacing: CGFloat = 12
        static let dotSize: CGFloat = 7
        static let dotSpacing: CGFloat = 6
        static let valueMinimumScaleFactor: CGFloat = 0.7
    }

    enum RhythmChart {
        static let surfaceLineHeight: CGFloat = 2
        static let trackCornerExtra: CGFloat = 2
        static let trackLightOpacity: Double = 0.035
        static let trackDarkOpacity: Double = 0.045
        /// A step label closer than this to the average yields to the "avg" marker. Points at the
        /// default text size, scaled with the axis labels.
        static let averageLabelClearance: CGFloat = 15
    }

    enum Sessions {
        static let stackSpacing: CGFloat = 12
        static let rowVerticalPadding: CGFloat = 11
        static let stackedRowSpacing: CGFloat = 6
        static let columnSpacing: CGFloat = 12
        static let markerSize: CGFloat = 8.5
        static let markerSpacing: CGFloat = 7
        static let compactMarkerSpacing: CGFloat = 4
        static let focusColumnWidth: CGFloat = 64
        static let dividerLightOpacity: Double = 0.06
        static let dividerDarkOpacity: Double = 0.08
    }

    enum ChartAxis {
        static let labelMinimumScaleFactor: CGFloat = 0.72
        static let valueLabelWidth: CGFloat = 32
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
    @State private var selectedSlot: Int?

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

                        VStack(alignment: .leading, spacing: ProductivityLayout.TrendGroup.captionSpacing) {
                            ProductivityRangeCaption(
                                range: renderState.selectedRange,
                                buckets: renderState.displayBuckets
                            )

                            VStack(alignment: .leading, spacing: ProductivityLayout.sectionSpacing) {
                                ProductivityRhythmCard(
                                    buckets: renderState.displayBuckets,
                                    range: renderState.selectedRange,
                                    selectedSlot: $selectedSlot
                                )

                                // With no history, the empty-state note above already says what will appear here.
                                if !renderState.showsEmptyState {
                                    ProductivitySessionsCard(
                                        sessions: store.completedSessions,
                                        buckets: renderState.displayBuckets,
                                        range: renderState.selectedRange,
                                        selectedSlot: selectedSlot
                                    )
                                }
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
        .onChange(of: selectedRange) {
            selectedSlot = nil
        }
    }
}

private struct ProductivityRangeToolbarMenu: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selectedRange: ProductivityRange

    var body: some View {
        Menu {
            // Each choice is a toggle, so the system draws its checkmark. A checkmark image in a
            // button's label disappears at accessibility text sizes, where menus drop images.
            ForEach(ProductivityRange.allCases) { range in
                Toggle(range.displayTitle, isOn: selection(of: range))
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

    /// Choosing the current range again leaves it chosen.
    private func selection(of range: ProductivityRange) -> Binding<Bool> {
        Binding(
            get: { selectedRange == range },
            set: { isOn in
                if isOn {
                    selectedRange = range
                }
            }
        )
    }
}
