import SwiftUI

struct PomodoroPhaseBadge: View {
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

struct PomodoroRemainingTimeText: View {
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

    static func pausedText(for duration: TimeInterval?) -> String {
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

struct PomodoroCountdownText: View {
    let targetEndDate: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            Text(PomodoroRemainingTimeText.pausedText(for: targetEndDate.timeIntervalSince(timeline.date)))
        }
    }
}

struct PomodoroRoundProgress: View {
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

struct PomodoroExpandedProgressView: View {
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

struct PomodoroPhaseDot: View {
    let phase: PomodoroActivityPhase

    var body: some View {
        Circle()
            .fill(phase.activityStyle.accent)
            .frame(width: 9, height: 9)
    }
}
