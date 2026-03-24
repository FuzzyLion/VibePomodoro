import SwiftUI

struct BubbleRenderState: Equatable {
    let phase: SessionPhase
    let actionTitle: String
    let targetEndDate: Date?
    let remainingDuration: TimeInterval
    let progress: Double
    let plannedDuration: TimeInterval
    let isAnimating: Bool
    let shouldTickSeconds: Bool

    var animationRefreshInterval: TimeInterval {
        isAnimating ? 1.0 / 12.0 : 60.0
    }

    var textRefreshInterval: TimeInterval {
        shouldTickSeconds ? 1.0 : 60.0
    }

    func remainingDuration(at now: Date) -> TimeInterval {
        guard shouldTickSeconds, let targetEndDate else { return remainingDuration }
        return max(0, targetEndDate.timeIntervalSince(now))
    }

    func progress(at now: Date) -> Double {
        guard shouldTickSeconds, plannedDuration > 0 else { return progress }
        let dynamicRemainingDuration = remainingDuration(at: now)
        return min(1, max(0, 1 - (dynamicRemainingDuration / plannedDuration)))
    }

    func timeText(at now: Date) -> String {
        Self.formattedTime(remainingDuration(at: now))
    }

    func isFinalDisplayedSecond(at now: Date) -> Bool {
        timeText(at: now) == "00:01"
    }

    private static func formattedTime(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct FocusRenderState: Equatable {
    let phase: SessionPhase
    let statusText: String
    let canSkip: Bool
    let canReset: Bool
    let canGoBack: Bool
    let shouldShowBackAction: Bool
    let nodeStates: [SessionProgressNodeState]
    let bubble: BubbleRenderState

    @MainActor
    static func build(store: PomodoroStore, scenePhase: ScenePhase) -> FocusRenderState {
        let session = store.activeSession
        let phase = session?.currentPhase ?? .focus
        let hasElapsedTime = session.map(Self.hasElapsedTime) ?? false
        let canGoBack = session.map { $0.currentStepIndex > 0 || hasElapsedTime } ?? false
        let shouldShowBackAction = session.map { session in
            switch session.runState {
            case .idle:
                return hasElapsedTime
            case .running, .paused, .completed:
                return true
            }
        } ?? false
        let canReset = session.map(Self.canResetCurrentStep) ?? false
        let runState = session?.runState ?? .idle
        let isFocusVisible = scenePhase == .active && store.selectedTab == .focus
        let isAnimating = isFocusVisible && runState == .running
        let shouldTickSeconds = isFocusVisible && runState == .running
        let plannedDuration = session?.currentStep?.plannedDuration ?? store.settings.focusDuration

        return FocusRenderState(
            phase: phase,
            statusText: statusText(for: session, phase: phase),
            canSkip: session?.currentStep != nil,
            canReset: canReset,
            canGoBack: canGoBack,
            shouldShowBackAction: shouldShowBackAction,
            nodeStates: nodeStates(for: session, fallbackRounds: store.settings.targetRounds),
            bubble: BubbleRenderState(
                phase: phase,
                actionTitle: primaryActionTitle(for: runState, hasSession: session != nil),
                targetEndDate: session?.targetEndDate,
                remainingDuration: store.remainingDuration(),
                progress: store.elapsedRatio(),
                plannedDuration: plannedDuration,
                isAnimating: isAnimating,
                shouldTickSeconds: shouldTickSeconds
            )
        )
    }

    @MainActor
    private static func primaryActionTitle(for runState: SessionRunState, hasSession: Bool) -> String {
        guard hasSession else { return "Start" }

        switch runState {
        case .idle:
            return "Start"
        case .running:
            return "Pause"
        case .paused:
            return "Resume"
        case .completed:
            return "Start Again"
        }
    }

    @MainActor
    private static func statusText(for session: SessionSnapshot?, phase: SessionPhase) -> String {
        guard let session else { return "READY" }
        guard session.runState != .completed else { return "COMPLETE" }

        switch phase {
        case .focus:
            return "FOCUS"
        case .shortBreak:
            return "SHORT BREAK"
        case .longBreak:
            return "LONG BREAK"
        }
    }

    @MainActor
    private static func canResetCurrentStep(for session: SessionSnapshot) -> Bool {
        guard session.runState != .completed,
              let step = session.currentStep else { return false }

        return session.runState == .running
            || session.runState == .paused
            || session.accumulatedDuration(for: step) > 0
    }

    @MainActor
    private static func hasElapsedTime(for session: SessionSnapshot) -> Bool {
        if !session.segments.isEmpty {
            return true
        }

        guard session.runState == .running,
              let currentSegmentStartDate = session.currentSegmentStartDate else {
            return false
        }

        return Date.now > currentSegmentStartDate
    }

    @MainActor
    private static func nodeStates(
        for session: SessionSnapshot?,
        fallbackRounds: Int
    ) -> [SessionProgressNodeState] {
        let totalRounds = max(1, session?.targetRounds ?? fallbackRounds)

        guard let session else {
            return (1...totalRounds).map { $0 == 1 ? .half : .inactive }
        }

        if session.runState == .completed {
            return Array(repeating: .filled, count: totalRounds)
        }

        let currentRound = session.currentStep?.roundNumber ?? 1
        let currentPhase = session.currentPhase ?? .focus

        return (1...totalRounds).map { round in
            if round < currentRound {
                return .filled
            }

            if round == currentRound {
                return currentPhase == .focus ? .half : .filled
            }

            return .inactive
        }
    }
}

struct FocusScreen: View {
    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            let layout = FocusScreenLayout(size: proxy.size)
            let renderState = FocusRenderState.build(store: store, scenePhase: scenePhase)

            VStack(spacing: layout.verticalSpacing) {
                Spacer(minLength: layout.topSpacing)

                PhaseStatusBadge(text: renderState.statusText, phase: renderState.phase)
                    .fixedSize(horizontal: true, vertical: false)

                BubbleTimerView(
                    renderState: renderState.bubble,
                    action: store.togglePrimaryAction
                )
                .frame(
                    width: FocusScreenLayout.bubbleDiameter,
                    height: FocusScreenLayout.bubbleDiameter
                )
                .padding(.top, layout.bubbleTopPadding)

                SessionProgressPill(
                    phase: renderState.phase,
                    nodeStates: renderState.nodeStates
                )
                .fixedSize(horizontal: true, vertical: false)
                .padding(.top, layout.progressTopPadding)

                HStack(spacing: FocusScreenLayout.secondaryActionSpacing) {
                    SecondaryActionButton(
                        title: "Skip",
                        systemImage: "forward.end",
                        isEnabled: renderState.canSkip,
                        glassTint: renderState.phase.glassTint,
                        action: store.skipCurrentStep
                    )
                    .frame(maxWidth: .infinity)

                    SecondaryActionButton(
                        title: "Reset",
                        systemImage: "arrow.counterclockwise",
                        isEnabled: renderState.canReset,
                        glassTint: renderState.phase.glassTint,
                        action: store.resetCurrentStep
                    )
                    .frame(maxWidth: .infinity)
                }
                .frame(width: FocusScreenLayout.secondaryActionRowWidth)
                .padding(.top, layout.secondaryActionTopPadding)

                if renderState.shouldShowBackAction {
                    TertiaryActionButton(
                        title: "Back to last step",
                        systemImage: "chevron.left",
                        isEnabled: renderState.canGoBack,
                        action: store.goBackOneStep
                    )
                    .padding(.top, layout.backActionTopPadding)
                }

                Spacer(minLength: layout.bottomSpacing)
            }
            .padding(.horizontal, FocusScreenLayout.horizontalPadding)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
    }
}

struct FocusScreenLayout {
    static let bubbleDiameter: CGFloat = 280
    static let horizontalPadding: CGFloat = 24
    static let secondaryActionRowWidth: CGFloat = 261.29
    static let secondaryActionSpacing: CGFloat = 16

    let size: CGSize

    var isCompact: Bool {
        size.height < 760
    }

    var topSpacing: CGFloat {
        isCompact ? max(56, size.height * 0.13) : max(74, size.height * 0.16)
    }

    var verticalSpacing: CGFloat {
        isCompact ? 18 : 24
    }

    var bubbleTopPadding: CGFloat {
        isCompact ? 10 : 18
    }

    var progressTopPadding: CGFloat {
        isCompact ? 0 : 6
    }

    var secondaryActionTopPadding: CGFloat {
        isCompact ? 6 : 12
    }

    var backActionTopPadding: CGFloat {
        isCompact ? -2 : 0
    }

    var bottomSpacing: CGFloat {
        max(72, size.height * 0.18)
    }
}
