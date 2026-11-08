import SwiftUI

struct BubbleRenderState: Equatable {
    static let visibleAnimationRefreshInterval: TimeInterval = 1.0 / 12.0

    let phase: SessionPhase
    let targetEndDate: Date?
    let remainingDuration: TimeInterval
    let progress: Double
    let plannedDuration: TimeInterval
    let isAnimating: Bool
    let shouldTickSeconds: Bool

    var animationRefreshInterval: TimeInterval {
        isAnimating ? Self.visibleAnimationRefreshInterval : 60.0
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

    func stepBoundaryCueProgress(at now: Date) -> Double {
        guard shouldTickSeconds, targetEndDate != nil else { return 0 }

        let cueWindow: TimeInterval = 3
        let clampedRemaining = min(max(remainingDuration(at: now), 0), cueWindow)
        let normalized = 1 - (clampedRemaining / cueWindow)
        return normalized * normalized * (3 - (2 * normalized))
    }

    private static func formattedTime(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct BubbleRenderingPolicy: Equatable {
    let animatesSurface: Bool
    /// The caustic light, the threads inside the liquid and the glow beneath the vessel, is
    /// extra layer and blur work, so Low Power Mode leaves it out.
    let rendersCaustic: Bool

    init(isAnimating: Bool, reduceMotion: Bool, lowPowerModeEnabled: Bool) {
        animatesSurface = isAnimating && !reduceMotion
        rendersCaustic = !lowPowerModeEnabled
    }
}

enum FocusPrimaryAction: Equatable {
    case start
    case pause
    case resume
    case startAgain

    var title: String {
        switch self {
        case .start:
            return "Start"
        case .pause:
            return "Pause"
        case .resume:
            return "Resume"
        case .startAgain:
            return "Start Again"
        }
    }

    var systemImage: String {
        self == .pause ? "pause.fill" : "play.fill"
    }
}

struct FocusRenderState: Equatable {
    let phase: SessionPhase
    let statusText: String
    let primaryAction: FocusPrimaryAction
    /// Secondary controls appear only when they can act; Back waits until timing has begun.
    let canSkip: Bool
    let canReset: Bool
    let showsBack: Bool
    let showsFinish: Bool
    let nodeStates: [SessionProgressNodeState]
    let bubble: BubbleRenderState

    @MainActor
    static func build(store: PomodoroStore, scenePhase: ScenePhase) -> FocusRenderState {
        let session = store.activeSession
        let now = Date.now
        let phase = displayPhase(for: session)
        let hasElapsedTime = session?.hasElapsedTime(now: now) ?? false
        let runState = session?.runState ?? .idle
        let isFocusVisible = scenePhase == .active && store.selectedTab == .focus
        let isTicking = isFocusVisible && runState == .running

        return FocusRenderState(
            phase: phase,
            statusText: statusText(for: session, phase: phase),
            primaryAction: primaryAction(for: session),
            canSkip: session?.currentStep != nil,
            canReset: session.map(canResetCurrentStep) ?? false,
            showsBack: session.map { session in
                (session.runState != .idle || hasElapsedTime)
                    && (session.currentStepIndex > 0 || hasElapsedTime)
            } ?? false,
            showsFinish: session.map { $0.runState != .completed && hasElapsedTime } ?? false,
            nodeStates: nodeStates(for: session, fallbackRounds: store.settings.targetRounds),
            bubble: BubbleRenderState(
                phase: phase,
                targetEndDate: session?.targetEndDate,
                remainingDuration: store.remainingDuration(),
                progress: store.elapsedRatio(),
                plannedDuration: session?.currentStep?.plannedDuration ?? store.settings.focusDuration,
                isAnimating: isTicking,
                shouldTickSeconds: isTicking
            )
        )
    }

    private static func displayPhase(for session: SessionSnapshot?) -> SessionPhase {
        guard let session else { return .focus }

        if let currentPhase = session.currentPhase {
            return currentPhase
        }

        if session.runState == .completed {
            return session.steps.last?.phase ?? .focus
        }

        return .focus
    }

    private static func primaryAction(for session: SessionSnapshot?) -> FocusPrimaryAction {
        switch session?.runState ?? .idle {
        case .idle:
            return .start
        case .running:
            return .pause
        case .paused:
            return .resume
        case .completed:
            return .startAgain
        }
    }

    private static func statusText(for session: SessionSnapshot?, phase: SessionPhase) -> String {
        guard let session else { return "Ready" }
        return session.runState == .completed ? "Complete" : phase.title
    }

    private static func canResetCurrentStep(for session: SessionSnapshot) -> Bool {
        guard session.runState != .completed,
              let step = session.currentStep else { return false }

        return session.runState == .running
            || session.runState == .paused
            || session.accumulatedDuration(for: step) > 0
    }

    private static func nodeStates(
        for session: SessionSnapshot?,
        fallbackRounds: Int
    ) -> [SessionProgressNodeState] {
        let totalRounds = max(1, session?.targetRounds ?? fallbackRounds)

        guard let session else {
            return (1...totalRounds).map { $0 == 1 ? .half : .inactive }
        }

        // A finished session has no current step, so every round is behind it.
        let currentRound = session.currentStep?.roundNumber ?? totalRounds

        return (1...totalRounds).map { round in
            if round > currentRound {
                return .inactive
            }

            if round == currentRound, session.currentPhase == .focus {
                return .half
            }

            return session.isFocusRoundCompleted(round) ? .filled : .skipped
        }
    }
}
