import SwiftUI

struct FocusScreen: View {
    @EnvironmentObject private var store: PomodoroStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer(minLength: 88)

                PhaseStatusBadge(text: store.statusText, phase: store.currentPhase)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    BubbleTimerView(
                        phase: store.currentPhase,
                        timeText: Self.formattedTime(store.remainingDuration(now: context.date)),
                        progress: store.elapsedRatio(now: context.date),
                        actionTitle: store.primaryActionTitle,
                        action: store.togglePrimaryAction
                    )
                }
                .padding(.top, 18)

                SessionProgressPill(
                    title: "Focus Session",
                    currentRound: currentRoundDisplay,
                    totalRounds: store.activeSession?.targetRounds ?? store.settings.targetRounds
                )
                .frame(maxWidth: 228)
                .padding(.top, 4)

                HStack(spacing: 16) {
                    SecondaryActionButton(
                        title: "Skip",
                        systemImage: "forward.end",
                        isEnabled: store.canSkip,
                        action: store.skipCurrentStep
                    )

                    SecondaryActionButton(
                        title: "Back",
                        systemImage: "arrow.counterclockwise",
                        isEnabled: store.canGoBack,
                        action: store.goBackOneStep
                    )
                }
                .frame(maxWidth: 264)
                .padding(.top, 6)

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

    static func formattedTime(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
