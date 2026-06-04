import SwiftUI

struct PomodoroPhaseBadge: View {
    let state: PomodoroActivityAttributes.ContentState
    var foregroundColor: Color = .primary

    var body: some View {
        Group {
            if state.shouldUseTimelineDisplay {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    content(at: timeline.date)
                }
            } else {
                content(at: .now)
            }
        }
    }

    private func content(at date: Date) -> some View {
        let phase = state.displayPhase(at: date)

        return HStack(spacing: 7) {
            PomodoroCompactProgressMark(state: state, size: .badge)
            Text(phase.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(foregroundColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityLabel(phase.title)
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
            if state.shouldUseTimelineDisplay {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    remainingContent(at: timeline.date)
                }
            } else {
                remainingContent(at: .now)
            }
        }
        .font(font)
        .foregroundStyle(foregroundColor)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(minimumScaleFactor)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private func remainingContent(at date: Date) -> some View {
        switch state.displayRunState(at: date) {
        case .running:
            if let timerInterval = state.displayTimerInterval(at: date) {
                Text(
                    timerInterval: timerInterval,
                    pauseTime: state.displayTimerPauseTime(at: date),
                    countsDown: true
                )
            } else {
                Text(Self.pausedText(for: 0))
            }
        case .paused:
            Text(Self.pausedText(for: state.pausedRemainingDuration))
        case .completed:
            Text("Done")
        }
    }

    private var accessibilityText: String {
        let now = Date.now
        switch state.displayRunState(at: now) {
        case .running:
            return "Remaining time"
        case .paused:
            return "Paused with \(Self.pausedText(for: state.pausedRemainingDuration)) remaining"
        case .completed:
            return "Session complete"
        }
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

struct PomodoroStepProgressBar: View {
    let state: PomodoroActivityAttributes.ContentState
    var inactiveColor: Color = Color.secondary.opacity(0.22)

    var body: some View {
        Group {
            if state.shouldUseTimelineDisplay {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    progressBar(
                        progress: state.stepProgress(at: timeline.date),
                        phase: state.displayPhase(at: timeline.date)
                    )
                }
            } else {
                progressBar(progress: state.stepProgress(at: .now), phase: state.displayPhase(at: .now))
            }
        }
        .accessibilityLabel("Current step progress")
    }

    private func progressBar(progress: Double, phase: PomodoroActivityPhase) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(inactiveColor)

                Capsule()
                    .fill(progressFill(for: phase))
                    .frame(width: max(6, proxy.size.width * progress))
            }
        }
        .frame(height: 5)
    }

    private func progressFill(for phase: PomodoroActivityPhase) -> some ShapeStyle {
        LinearGradient(
            colors: [
                phase.activityStyle.accent,
                phase.activityStyle.secondaryAccent
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct PomodoroExpandedProgressView: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            PomodoroRoundLabel(state: state, size: .expanded)

            PomodoroStepProgressBar(state: state)
                .frame(height: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }
}

struct PomodoroCompactProgressMark: View {
    enum Size {
        case badge
        case compact
        case minimal
    }

    let state: PomodoroActivityAttributes.ContentState
    let size: Size

    var body: some View {
        Group {
            if state.shouldUseTimelineDisplay {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    mark(
                        progress: state.stepProgress(at: timeline.date),
                        phase: state.displayPhase(at: timeline.date)
                    )
                    .accessibilityLabel(state.displayPhase(at: timeline.date).title)
                }
            } else {
                mark(progress: state.stepProgress(at: .now), phase: state.displayPhase(at: .now))
                    .accessibilityLabel(state.displayPhase(at: .now).title)
            }
        }
    }

    private func mark(progress: Double, phase: PomodoroActivityPhase) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(size == .minimal ? 0.18 : 0.14))

            Capsule()
                .fill(progressFill(for: phase))
                .frame(width: max(4, dimensions.width * progress))
        }
        .frame(width: dimensions.width, height: dimensions.height)
    }

    private var dimensions: CGSize {
        switch size {
        case .badge:
            return CGSize(width: 24, height: 13)
        case .compact:
            return CGSize(width: 26, height: 12)
        case .minimal:
            return CGSize(width: 16, height: 7)
        }
    }

    private func progressFill(for phase: PomodoroActivityPhase) -> some ShapeStyle {
        LinearGradient(
            colors: [
                phase.activityStyle.accent,
                phase.activityStyle.secondaryAccent
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct PomodoroRoundLabel: View {
    enum Size {
        case lockScreen
        case expanded
    }

    let state: PomodoroActivityAttributes.ContentState
    let size: Size
    var foregroundColor: Color = Color.white.opacity(0.66)

    var body: some View {
        Group {
            if state.shouldUseTimelineDisplay {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    label(at: timeline.date)
                }
            } else {
                label(at: .now)
            }
        }
    }

    private func label(at date: Date) -> some View {
        Text(state.roundText(at: date))
            .font(font)
            .foregroundStyle(foregroundColor)
            .monospacedDigit()
            .lineLimit(1)
    }

    private var font: Font {
        switch size {
        case .lockScreen:
            return .caption.weight(.semibold)
        case .expanded:
            return .caption2.weight(.semibold)
        }
    }
}

struct PomodoroBreathField: View {
    let phase: PomodoroActivityPhase

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    phase.activityStyle.accent.opacity(0.26),
                    phase.activityStyle.accent.opacity(0)
                ],
                center: .topLeading,
                startRadius: 8,
                endRadius: 160
            )

            RadialGradient(
                colors: [
                    phase.activityStyle.secondaryAccent.opacity(0.14),
                    phase.activityStyle.secondaryAccent.opacity(0)
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 150
            )
        }
        .allowsHitTesting(false)
    }
}
