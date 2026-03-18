import SwiftUI

struct FocusScreen: View {
    @EnvironmentObject private var store: PomodoroStore

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let compactLayout = size.height < 760
            let topSpacing = compactLayout ? max(56, size.height * 0.13) : max(74, size.height * 0.16)

            VStack(spacing: compactLayout ? 18 : 24) {
                Spacer(minLength: topSpacing)

                PhaseStatusBadge(text: store.statusText, phase: store.currentPhase)
                    .fixedSize(horizontal: true, vertical: false)

                TimelineView(.animation) { context in
                    BubbleTimerView(
                        phase: store.currentPhase,
                        timeText: Self.formattedTime(store.remainingDuration(now: context.date)),
                        progress: store.elapsedRatio(now: context.date),
                        actionTitle: store.primaryActionTitle,
                        now: context.date,
                        isAnimating: store.currentRunState == .running,
                        action: store.togglePrimaryAction
                    )
                }
                .frame(width: 280, height: 280)
                .padding(.top, compactLayout ? 10 : 18)

                SessionProgressPill(
                    phase: store.currentPhase,
                    nodeStates: sessionNodeStates
                )
                .fixedSize(horizontal: true, vertical: false)
                .padding(.top, compactLayout ? 0 : 6)

                HStack(spacing: 16) {
                    SecondaryActionButton(
                        title: "Skip",
                        systemImage: "forward.end",
                        isEnabled: store.canSkip,
                        glassTint: store.currentPhase.glassTint,
                        action: store.skipCurrentStep
                    )
                    .frame(width: 118.04)

                    SecondaryActionButton(
                        title: "Reset",
                        systemImage: "arrow.counterclockwise",
                        isEnabled: store.canResetCurrentStep,
                        glassTint: store.currentPhase.glassTint,
                        action: store.resetCurrentStep
                    )
                    .frame(width: 127.25)
                }
                .frame(width: 261.29)
                .padding(.top, compactLayout ? 6 : 12)

                if store.shouldShowBackAction {
                    TertiaryActionButton(
                        title: "Back to last step",
                        systemImage: "chevron.left",
                        isEnabled: store.canGoBack,
                        action: store.goBackOneStep
                    )
                    .padding(.top, compactLayout ? -2 : 0)
                }

                Spacer(minLength: max(72, size.height * 0.18))
            }
            .padding(.horizontal, 24)
            .frame(width: size.width, height: size.height, alignment: .top)
        }
    }

    private var sessionNodeStates: [SessionProgressNodeState] {
        let totalRounds = max(1, store.activeSession?.targetRounds ?? store.settings.targetRounds)
        guard let session = store.activeSession else {
            return (1...totalRounds).map { $0 == 1 ? .half : .inactive }
        }

        let safeStepIndex = min(session.currentStepIndex, session.steps.count)

        return (1...totalRounds).map { round in
            guard let focusIndex = session.steps.firstIndex(where: { $0.phase == .focus && $0.roundNumber == round }) else {
                return .inactive
            }

            if session.runState == .completed || safeStepIndex > focusIndex {
                return .filled
            }

            if safeStepIndex == focusIndex && session.currentPhase == .focus {
                return .half
            }

            return .inactive
        }
    }

    static func formattedTime(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
