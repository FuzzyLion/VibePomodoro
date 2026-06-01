import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

struct PomodoroLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            PomodoroLockScreenLiveActivityContainer(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    PomodoroExpandedIslandContent(state: context.state)
                }
            } compactLeading: {
                PomodoroPhaseDot(phase: context.state.phase)
                    .frame(width: 13, height: 13)
            } compactTrailing: {
                EmptyView()
            } minimal: {
                PomodoroMinimalView(state: context.state)
            }
        }
    }
}

private struct PomodoroExpandedIslandContent: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                PomodoroPhaseBadge(state: state)
                    .frame(height: 24, alignment: .leading)

                Spacer(minLength: 12)

                PomodoroRemainingTimeText(state: state, size: .expanded)
                    .frame(width: 82, height: 24, alignment: .trailing)
            }

            PomodoroExpandedProgressView(state: state)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 2)
        .padding(.bottom, 4)
    }
}

private struct PomodoroLockScreenLiveActivityContainer: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        let palette = PomodoroLiveActivityPalette()

        PomodoroLockScreenLiveActivityView(state: state, palette: palette)
            .activityBackgroundTint(palette.cardBackground)
            .activitySystemActionForegroundColor(state.phase.activityStyle.accent)
    }
}

private struct PomodoroLockScreenLiveActivityView: View {
    let state: PomodoroActivityAttributes.ContentState
    let palette: PomodoroLiveActivityPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                PomodoroPhaseBadge(state: state, foregroundColor: palette.primaryText)
                Spacer(minLength: 12)
                Text("Round \(state.roundNumber)/\(state.targetRounds)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
                    .monospacedDigit()
            }

            PomodoroRemainingTimeText(state: state, size: .lockScreen, foregroundColor: palette.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            PomodoroRoundProgress(state: state, inactiveColor: palette.inactiveProgress)
        }
        .padding(18)
    }
}

private struct PomodoroPhaseBadge: View {
    let state: PomodoroActivityAttributes.ContentState
    var foregroundColor: Color = .primary

    var body: some View {
        HStack(spacing: 7) {
            PomodoroPhaseDot(phase: state.phase)
            Text(state.phase.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(foregroundColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityLabel(state.phase.title)
    }
}

private struct PomodoroRemainingTimeText: View {
    enum Size {
        case compact
        case expanded
        case lockScreen
    }

    let state: PomodoroActivityAttributes.ContentState
    let size: Size
    var foregroundColor: Color = .primary

    var body: some View {
        Group {
            if state.runState == .running, let targetEndDate = state.targetEndDate {
                if targetEndDate > Date.now {
                    if size == .lockScreen {
                        PomodoroCountdownText(targetEndDate: targetEndDate)
                    } else {
                        Text(timerInterval: Date.now...targetEndDate, countsDown: true)
                    }
                } else {
                    Text(Self.pausedText(for: 0))
                }
            } else if state.runState == .completed {
                Text("Done")
            } else {
                Text(Self.pausedText(for: state.pausedRemainingDuration))
            }
        }
        .font(font)
        .foregroundStyle(foregroundColor)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(minimumScaleFactor)
        .accessibilityLabel(accessibilityText)
    }

    private var font: Font {
        switch size {
        case .compact:
            return .caption2.weight(.semibold)
        case .expanded:
            return .title3.weight(.semibold)
        case .lockScreen:
            return .system(size: 38, weight: .semibold, design: .rounded)
        }
    }

    private var minimumScaleFactor: CGFloat {
        switch size {
        case .compact:
            return 0.62
        case .expanded, .lockScreen:
            return 0.72
        }
    }

    private var accessibilityText: String {
        switch state.runState {
        case .running:
            return "Remaining time"
        case .paused:
            return "Paused with \(Self.pausedText(for: state.pausedRemainingDuration)) remaining"
        case .completed:
            return "Session complete"
        }
    }

    fileprivate static func pausedText(for duration: TimeInterval?) -> String {
        let remaining = max(0, Int((duration ?? 0).rounded()))
        let hours = remaining / 3_600
        let minutes = (remaining % 3_600) / 60
        let seconds = remaining % 60

        if hours > 0 {
            return "\(hours):\(twoDigits(minutes)):\(twoDigits(seconds))"
        }

        return "\(minutes):\(twoDigits(seconds))"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}

private struct PomodoroCountdownText: View {
    let targetEndDate: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            Text(PomodoroRemainingTimeText.pausedText(for: targetEndDate.timeIntervalSince(timeline.date)))
        }
    }
}

private struct PomodoroRoundProgress: View {
    let state: PomodoroActivityAttributes.ContentState
    var inactiveColor: Color = Color.secondary.opacity(0.22)

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...max(1, state.targetRounds), id: \.self) { round in
                Capsule()
                    .fill(progressFill(for: round))
                    .frame(maxWidth: .infinity)
                    .frame(height: 5)
            }
        }
        .accessibilityLabel("Round \(state.roundNumber) of \(state.targetRounds)")
    }

    private func progressFill(for round: Int) -> AnyShapeStyle {
        guard round <= state.roundNumber else {
            return AnyShapeStyle(inactiveColor)
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    state.phase.activityStyle.accent,
                    state.phase.activityStyle.deepAccent
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

private struct PomodoroExpandedProgressView: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Round \(state.roundNumber)/\(state.targetRounds)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.66))
                .monospacedDigit()
                .lineLimit(1)

            PomodoroRoundProgress(state: state)
                .frame(height: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }
}

private struct PomodoroPhaseDot: View {
    let phase: PomodoroActivityPhase

    var body: some View {
        Circle()
            .fill(phase.activityStyle.accent)
            .frame(width: 9, height: 9)
    }
}

private struct PomodoroMinimalView: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        Circle()
            .fill(state.phase.activityStyle.accent)
            .frame(width: 7, height: 7)
            .accessibilityLabel(state.phase.title)
    }
}

private struct PomodoroLiveActivityPalette {
    var cardBackground: Color {
        Color(Self.dynamicColor(light: .white, dark: .black))
    }

    var primaryText: Color {
        Color(Self.dynamicColor(light: .black, dark: .white))
    }

    var secondaryText: Color {
        Color(Self.dynamicColor(
            light: UIColor.black.withAlphaComponent(0.62),
            dark: UIColor.white.withAlphaComponent(0.72)
        ))
    }

    var inactiveProgress: Color {
        Color(Self.dynamicColor(
            light: UIColor.black.withAlphaComponent(0.14),
            dark: UIColor.white.withAlphaComponent(0.22)
        ))
    }

    private static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

private struct PomodoroPhaseActivityStyle {
    let accent: Color
    let deepAccent: Color
}

private extension PomodoroActivityPhase {
    var activityStyle: PomodoroPhaseActivityStyle {
        switch self {
        case .focus:
            return PomodoroPhaseActivityStyle(
                accent: Color(red: 0.85, green: 0.70, blue: 0.40),
                deepAccent: Color(red: 0.76, green: 0.58, blue: 0.25)
            )
        case .shortBreak:
            return PomodoroPhaseActivityStyle(
                accent: Color(red: 0.71, green: 0.82, blue: 0.90),
                deepAccent: Color(red: 0.52, green: 0.65, blue: 0.75)
            )
        case .longBreak:
            return PomodoroPhaseActivityStyle(
                accent: Color(red: 0.66, green: 0.80, blue: 0.74),
                deepAccent: Color(red: 0.48, green: 0.66, blue: 0.60)
            )
        }
    }
}

#Preview("Lock Screen", as: .content, using: PomodoroActivityAttributes()) {
    PomodoroLiveActivityWidget()
} contentStates: {
    PomodoroActivityAttributes.ContentState(
        sessionID: UUID().uuidString,
        phase: .focus,
        roundNumber: 2,
        targetRounds: 4,
        runState: .running,
        targetEndDate: Date().addingTimeInterval(12 * 60),
        pausedRemainingDuration: nil
    )
    PomodoroActivityAttributes.ContentState(
        sessionID: UUID().uuidString,
        phase: .shortBreak,
        roundNumber: 2,
        targetRounds: 4,
        runState: .paused,
        targetEndDate: nil,
        pausedRemainingDuration: 4 * 60 + 22
    )
}
