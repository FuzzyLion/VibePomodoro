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
    /// Once the session has ended, the vessel shows what was focused instead of a countdown.
    let summary: BubbleSessionSummary?

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

/// What the vessel holds once a session has ended.
struct BubbleSessionSummary: Equatable {
    let focusTime: TimeInterval
    /// The focus time as a share of the focus time the session planned, from 0 to 1.
    let focusShare: Double

    init(focusTime: TimeInterval, focusShare: Double) {
        self.focusTime = max(0, focusTime)
        self.focusShare = focusShare.isFinite ? min(1, max(0, focusShare)) : 0
    }

    init(session: SessionSnapshot, statistics: SessionStatistics) {
        let plannedFocusTime = session.steps
            .filter { $0.phase == .focus }
            .reduce(0) { $0 + $1.plannedDuration }
        self.init(
            focusTime: statistics.focusTime,
            focusShare: plannedFocusTime > 0 ? statistics.focusTime / plannedFocusTime : 0
        )
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
    /// Closes a finished session and returns to Ready.
    case done

    var title: String {
        switch self {
        case .start:
            return "Start"
        case .pause:
            return "Pause"
        case .resume:
            return "Resume"
        case .done:
            return "Done"
        }
    }

    var systemImage: String {
        switch self {
        case .pause:
            return "pause.fill"
        case .done:
            return "checkmark"
        case .start, .resume:
            return "play.fill"
        }
    }
}

struct FocusRenderState: Equatable {
    let phase: SessionPhase
    let statusText: String
    /// A short note under the status, shown when a session was finished early.
    let statusDetail: String?
    let primaryAction: FocusPrimaryAction
    /// Secondary controls appear only when they can act; Back waits until timing has begun.
    let canSkip: Bool
    let canReset: Bool
    let showsBack: Bool
    let showsFinish: Bool
    let nodeStates: [SessionProgressNodeState]
    /// The session's breakdown under the round markers once it has ended.
    let summaryCaption: String?
    let bubble: BubbleRenderState

    /// A finished session stays on the page until Done: the vessel holds the focus total and
    /// Done is the only control.
    var isSessionComplete: Bool {
        bubble.summary != nil
    }

    @MainActor
    static func build(store: PomodoroStore, scenePhase: ScenePhase) -> FocusRenderState {
        let session = store.activeSession
        let now = Date.now
        let phase = displayPhase(for: session)
        let hasElapsedTime = session?.hasElapsedTime(now: now) ?? false
        let runState = session?.runState ?? .idle
        let isComplete = runState == .completed
        let isFocusVisible = scenePhase == .active && store.selectedTab == .focus
        let isTicking = isFocusVisible && runState == .running
        // A session that ends before its last step still has a current step.
        let endedEarly = isComplete && (session.map { $0.currentStepIndex < $0.steps.count } ?? false)
        let statistics = isComplete ? session?.statistics(now: now) : nil

        return FocusRenderState(
            phase: phase,
            statusText: isComplete
                ? (endedEarly ? "Session finished" : "Session complete")
                : (session == nil ? "Ready" : phase.title),
            statusDetail: endedEarly ? "Saved what you completed so far." : nil,
            primaryAction: primaryAction(for: runState),
            canSkip: !isComplete && session?.currentStep != nil,
            canReset: session.map(canResetCurrentStep) ?? false,
            showsBack: !isComplete && (session.map { session in
                (session.runState != .idle || hasElapsedTime)
                    && (session.currentStepIndex > 0 || hasElapsedTime)
            } ?? false),
            showsFinish: !isComplete && hasElapsedTime,
            nodeStates: nodeStates(for: session, fallbackRounds: store.settings.targetRounds),
            summaryCaption: statistics.map {
                summaryCaption(for: $0, targetRounds: session?.targetRounds ?? store.settings.targetRounds)
            },
            bubble: BubbleRenderState(
                phase: phase,
                targetEndDate: session?.targetEndDate,
                remainingDuration: store.remainingDuration(),
                progress: store.elapsedRatio(),
                plannedDuration: session?.currentStep?.plannedDuration ?? store.settings.focusDuration,
                isAnimating: isTicking,
                shouldTickSeconds: isTicking,
                summary: session.flatMap { session in
                    statistics.map { BubbleSessionSummary(session: session, statistics: $0) }
                }
            )
        )
    }

    /// The completed focus blocks out of the planned ones, and the time spent on breaks.
    static func summaryCaption(for statistics: SessionStatistics, targetRounds: Int) -> String {
        let rounds = max(1, targetRounds)
        let blocks = "\(statistics.completedFocusCount) of \(rounds) focus \(rounds == 1 ? "block" : "blocks")"
        guard statistics.breakTime >= 1 else { return blocks }
        return "\(blocks) · \(FocusCompletionFormatting.durationText(statistics.breakTime)) break"
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

    private static func primaryAction(for runState: SessionRunState) -> FocusPrimaryAction {
        switch runState {
        case .idle:
            return .start
        case .running:
            return .pause
        case .paused:
            return .resume
        case .completed:
            return .done
        }
    }

    private static func canResetCurrentStep(for session: SessionSnapshot) -> Bool {
        guard session.runState != .completed,
              let step = session.currentStep else { return false }

        return session.runState == .running
            || session.runState == .paused
            || session.accumulatedDuration(for: step) > 0
    }

    static func nodeStates(
        for session: SessionSnapshot?,
        fallbackRounds: Int
    ) -> [SessionProgressNodeState] {
        let totalRounds = max(1, session?.targetRounds ?? fallbackRounds)

        guard let session else {
            return (1...totalRounds).map { $0 == 1 ? .half : .inactive }
        }

        // A session that reached its end has no current step, so every round is behind it.
        let currentRound = session.currentStep?.roundNumber ?? totalRounds
        // Once a session has ended, the focus block it stopped in is no longer running.
        let isInFocus = session.runState != .completed && session.currentPhase == .focus

        return (1...totalRounds).map { round in
            if round > currentRound {
                return .inactive
            }

            if round == currentRound, isInFocus {
                return .half
            }

            return session.isFocusRoundCompleted(round) ? .filled : .skipped
        }
    }
}
