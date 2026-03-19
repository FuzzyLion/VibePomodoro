import Charts
import SwiftUI

struct ProductivityScreen: View {
    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedRange: ProductivityRange = .week

    var body: some View {
        if shouldTickLiveSnapshot {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content(renderState: store.productivitySnapshot(for: selectedRange, now: context.date))
            }
        } else {
            content(renderState: store.productivitySnapshot(for: selectedRange))
        }
    }

    private var shouldTickLiveSnapshot: Bool {
        scenePhase == .active && store.selectedTab == .productivity && store.currentRunState == .running
    }

    private func content(renderState: ProductivityMetricsSnapshot) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 10)

                SectionTitle(
                    title: "Productivity",
                    subtitle: "Patterns that stay calm, readable, and honest."
                )

                GlassPanel {
                    Picker("Range", selection: $selectedRange) {
                        ForEach(ProductivityRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(VibePalette.focusTint)
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("FOCUS TIME")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        Chart(renderState.chartPoints) { point in
                            BarMark(
                                x: .value("Bucket", point.label),
                                y: .value("Hours", point.focusTime / 3600)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        VibePalette.focusTint.opacity(0.95),
                                        VibePalette.focusTint.opacity(0.42)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 240)
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label)
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                                    .foregroundStyle(Color.secondary.opacity(0.16))
                                AxisValueLabel {
                                    if let hours = value.as(Double.self) {
                                        Text(Self.chartHours(hours))
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        if renderState.chartPoints.allSatisfy({ $0.focusTime == 0 }) {
                            Text("Your chart will fill in as completed sessions are recorded.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCard(
                        icon: "flame",
                        title: "Streak",
                        value: "\(renderState.streakLength) days",
                        subtitle: "Consistency over intensity"
                    )

                    MetricCard(
                        icon: "target",
                        title: "Sessions",
                        value: "\(renderState.completedSessionCount)",
                        subtitle: "Completed full cycles"
                    )

                    MetricCard(
                        icon: "clock",
                        title: "Focus Time",
                        value: Self.hoursText(renderState.totalFocusTime),
                        subtitle: String(format: "Avg %.1fh/day", renderState.averageFocusHoursPerDay)
                    )

                    MetricCard(
                        icon: "cup.and.saucer",
                        title: "Break Time",
                        value: Self.hoursText(renderState.totalBreakTime),
                        subtitle: "Recovery is part of rhythm"
                    )
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    private static func chartHours(_ hours: Double) -> String {
        if hours == 0 {
            return "0h"
        }
        if hours < 1 {
            return String(format: "%.0fm", hours * 60)
        }
        return String(format: "%.1fh", hours)
    }

    private static func hoursText(_ duration: TimeInterval) -> String {
        let hours = duration / 3600
        if hours < 1 {
            return "\(Int(duration / 60))m"
        }
        return String(format: "%.1fh", hours)
    }
}
