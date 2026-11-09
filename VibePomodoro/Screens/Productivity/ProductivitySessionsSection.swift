import SwiftUI

/// The sessions behind the bars: the latest in the range, or those that started in the tapped slot.
struct ProductivitySessionsCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let sessions: [CompletedSession]
    let buckets: [ProductivityDisplayBucket]
    let range: ProductivityRange
    let selectedSlot: Int?

    private let contentInset = ProductivityLayout.TrendCard.contentInset
    private let cornerRadius = ProductivityLayout.TrendCard.cornerRadius

    private var selectedBucket: ProductivityDisplayBucket? {
        guard let selectedSlot, buckets.indices.contains(selectedSlot) else { return nil }
        return buckets[selectedSlot]
    }

    var body: some View {
        let selected = selectedBucket
        let rows = listedRows(for: selected)

        VStack(alignment: .leading, spacing: ProductivityLayout.Sessions.stackSpacing) {
            Text("Sessions")
                .productivityFont(.cardTitle)
                .foregroundStyle(ProductivityTextColors.primary(colorScheme))

            if rows.sessions.isEmpty {
                Text(emptyText(for: selected))
                    .productivityFont(.caption)
                    .foregroundStyle(ProductivityTextColors.secondary(colorScheme))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rows.sessions.enumerated()), id: \.element.id) { index, session in
                        if index > 0 {
                            Rectangle()
                                .fill(dividerColor)
                                .frame(height: 1)
                        }

                        ProductivitySessionRow(session: session)
                            .padding(.vertical, ProductivityLayout.Sessions.rowVerticalPadding)
                    }
                }

                // A month of sessions doesn't fit; the latest five stand for it.
                if selected != nil, rows.hiddenCount > 0 {
                    Text("\(rows.hiddenCount) more")
                        .productivityFont(.caption)
                        .foregroundStyle(ProductivityTextColors.secondary(colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, contentInset)
        .padding(.vertical, contentInset)
        .productivityGlassCard(
            colorScheme: colorScheme,
            style: .trend(contentInset: contentInset, cornerRadius: cornerRadius)
        ) {
            Color.clear
        }
    }

    private func listedRows(for selected: ProductivityDisplayBucket?) -> ProductivitySessionList.Rows {
        if let selected {
            return ProductivitySessionList.rows(from: sessions, startingFrom: selected.startDate, before: selected.endDate)
        }

        guard let start = buckets.first?.startDate, let end = buckets.last?.endDate else {
            return ProductivitySessionList.Rows(sessions: [], hiddenCount: 0)
        }
        return ProductivitySessionList.rows(from: sessions, startingFrom: start, before: end)
    }

    private func emptyText(for selected: ProductivityDisplayBucket?) -> String {
        guard let selected else {
            return "No sessions in the \(range.windowTitle.lowercased())"
        }

        let slot = ProductivityChartFormatting.selectionText(for: selected, range: range)
        return range == .year ? "No sessions in \(slot)" : "No sessions on \(slot)"
    }

    private var dividerColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(ProductivityLayout.Sessions.dividerDarkOpacity)
            : Color.black.opacity(ProductivityLayout.Sessions.dividerLightOpacity)
    }
}

private struct ProductivitySessionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .footnote) private var focusColumnWidth = ProductivityLayout.Sessions.focusColumnWidth

    let session: CompletedSession

    private var rounds: ClosedRange<Int> {
        1...max(1, session.settingsSnapshot.targetRounds)
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: ProductivityLayout.Sessions.stackedRowSpacing) {
                    startLabel

                    HStack(spacing: ProductivityLayout.Sessions.columnSpacing) {
                        markers
                        Spacer(minLength: ProductivityLayout.Sessions.columnSpacing)
                        focusLabel
                    }
                }
            } else {
                HStack(spacing: ProductivityLayout.Sessions.columnSpacing) {
                    startLabel
                    Spacer(minLength: ProductivityLayout.Sessions.columnSpacing)
                    markers
                    focusLabel
                        .frame(minWidth: focusColumnWidth, alignment: .trailing)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ProductivityChartFormatting.sessionStartAccessibilityText(session.startDate))
        .accessibilityValue(accessibilityValue)
        .accessibilityIdentifier("productivity.session")
    }

    private var startLabel: some View {
        Text(ProductivityChartFormatting.sessionStartText(session.startDate))
            .productivityFont(.caption)
            .foregroundStyle(ProductivityTextColors.primary(colorScheme))
            .monospacedDigit()
            .lineLimit(1)
    }

    /// One marker per round, as on the Focus page: filled when the block ran its full length.
    private var markers: some View {
        HStack(spacing: rounds.count > 6
            ? ProductivityLayout.Sessions.compactMarkerSpacing
            : ProductivityLayout.Sessions.markerSpacing
        ) {
            ForEach(rounds, id: \.self) { round in
                ProductivityRoundMarker(isCompleted: session.isFocusRoundCompleted(round))
            }
        }
    }

    private var focusLabel: some View {
        Text(ProductivityValueFormatting.compactDurationText(session.totalFocusTime))
            .productivityFont(.rowValue)
            .foregroundStyle(ProductivityTextColors.primary(colorScheme))
            .monospacedDigit()
            .lineLimit(1)
    }

    private var accessibilityValue: String {
        let completed = rounds.filter { session.isFocusRoundCompleted($0) }.count
        let focus = ProductivityValueFormatting.durationAccessibilityText(session.totalFocusTime)
        return "\(completed) of \(rounds.count) focus blocks, \(focus) of focus"
    }
}

/// The Focus page's round marker: filled with the focus color when the block ran its full length,
/// outlined when it didn't.
private struct ProductivityRoundMarker: View {
    @Environment(\.colorScheme) private var colorScheme

    let isCompleted: Bool

    var body: some View {
        Circle()
            .fill(colorScheme == .dark ? Color.white.opacity(0.14) : VibePalette.labelSecondary.opacity(0.16))
            .overlay {
                if isCompleted {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [SessionPhase.focus.tintColor, SessionPhase.focus.shadowColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    Circle()
                        .strokeBorder(
                            SessionPhase.focus.shadowColor.opacity(colorScheme == .dark ? 0.85 : 0.75),
                            lineWidth: 1.2
                        )
                }
            }
            .frame(width: ProductivityLayout.Sessions.markerSize, height: ProductivityLayout.Sessions.markerSize)
    }
}
