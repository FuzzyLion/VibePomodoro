import SwiftUI

struct FocusScreen: View {
    @EnvironmentObject private var store: PomodoroStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer(minLength: 16)

                PhaseStatusBadge(text: store.statusText, phase: store.currentPhase)

                VStack(spacing: 10) {
                    Text(store.currentStepTitle)
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("A calm place to begin the next block.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    BubbleTimerView(
                        phase: store.currentPhase,
                        timeText: Self.formattedTime(store.remainingDuration(now: context.date)),
                        progress: store.elapsedRatio(now: context.date),
                        actionTitle: store.primaryActionTitle,
                        action: store.togglePrimaryAction
                    )
                }

                SessionProgressPill(
                    title: "Focus Session",
                    currentRound: currentRoundDisplay,
                    totalRounds: store.activeSession?.targetRounds ?? store.settings.targetRounds
                )

                HStack(spacing: 16) {
                    SecondaryActionButton(
                        title: "Back",
                        systemImage: "arrow.counterclockwise",
                        isEnabled: store.canGoBack,
                        action: store.goBackOneStep
                    )

                    SecondaryActionButton(
                        title: "Skip",
                        systemImage: "forward.end",
                        isEnabled: store.canSkip,
                        action: store.skipCurrentStep
                    )
                }

                GlassPanel {
                    let stats = store.currentStatistics()

                    HStack(spacing: 12) {
                        focusStat(title: "Focus", value: Self.shortDuration(stats.focusTime))
                        focusStat(title: "Break", value: Self.shortDuration(stats.breakTime))
                        focusStat(title: "Session", value: Self.shortDuration(stats.sessionTime))
                    }
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    private var currentRoundDisplay: Int {
        guard let session = store.activeSession, let step = session.currentStep else { return 1 }
        return min(session.targetRounds, max(1, step.roundNumber))
    }

    private func focusStat(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    static func formattedTime(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func shortDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

