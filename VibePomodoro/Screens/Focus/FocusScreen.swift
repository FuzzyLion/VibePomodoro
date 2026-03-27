import SwiftUI
import UIKit

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
    let shouldShowFinishAction: Bool
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
        let shouldShowFinishAction = session.map { session in
            session.runState != .completed && hasElapsedTime
        } ?? false
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
            shouldShowFinishAction: shouldShowFinishAction,
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var isImmersive = false
    @State private var isShowingFinishConfirmation = false
    @State private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @State private var completionSummaryState: FocusCompletionSummaryState?
    @State private var immersiveHintVisible = false
    @State private var immersiveHintDismissTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let layout = FocusScreenLayout(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            let renderState = FocusRenderState.build(store: store, scenePhase: scenePhase)
            ZStack {
                pageContent(renderState: renderState, layout: layout, size: proxy.size)
                    .opacity(completionSummaryState == nil ? 1 : 0.22)
                    .blur(radius: completionSummaryState == nil ? 0 : 10)
                    .animation(.easeOut(duration: 0.22), value: completionSummaryState != nil)

                if let completionSummaryState {
                    FocusCompletionSummaryView(state: completionSummaryState) {
                        handleCompletionDismissal()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    .zIndex(2)
                } else if isImmersive && immersiveHintVisible {
                    immersiveHintBanner
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .toolbar(isImmersive && completionSummaryState == nil ? .hidden : .visible, for: .tabBar)
            .onAppear {
                syncVoiceOverState()
                syncCompletionSummary(with: store.activeSession)
                syncImmersiveState()
            }
            .onChange(of: store.activeSession?.id) { _, _ in
                syncCompletionSummary(with: store.activeSession)
                syncImmersiveState()
            }
            .onChange(of: store.activeSession?.runState) { _, _ in
                syncCompletionSummary(with: store.activeSession)
                syncImmersiveState()
            }
            .onChange(of: store.selectedTab) { _, _ in
                syncImmersiveState()
            }
            .onChange(of: scenePhase) { _, _ in
                syncCompletionSummary(with: store.activeSession)
                syncImmersiveState()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
                syncVoiceOverState()
                syncImmersiveState()
            }
            .alert("Finish session early?", isPresented: $isShowingFinishConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Finish session early") {
                    store.finishSessionEarly()
                }
            } message: {
                Text("This will end the current session and show the completion summary.")
            }
        }
    }

    @ViewBuilder
    private func pageContent(
        renderState: FocusRenderState,
        layout: FocusScreenLayout,
        size: CGSize
    ) -> some View {
        ZStack {
            backgroundTapLayer

            bubbleLayer(renderState: renderState)

            if !isImmersive {
                topChrome(renderState: renderState, layout: layout)
                bottomChrome(renderState: renderState, layout: layout)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .center)
        .allowsHitTesting(completionSummaryState == nil)
    }

    private var immersiveHintBanner: some View {
        Text("Tap anywhere to show controls")
            .font(.system(size: 13, weight: .semibold, design: .default))
            .foregroundStyle(VibePalette.glassTextMedium(for: colorScheme))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background {
                Capsule(style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    }
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.30), lineWidth: 0.85)
                    }
            }
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .offset(y: FocusScreenLayout.immersiveHintOffset)
        .allowsHitTesting(false)
    }

    private var backgroundTapLayer: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                handleBackgroundTap()
            }
    }

    @ViewBuilder
    private func bubbleLayer(renderState: FocusRenderState) -> some View {
        let bubbleView = BubbleTimerView(
            renderState: renderState.bubble,
            showsControlButton: !isImmersive && completionSummaryState == nil,
            action: store.togglePrimaryAction
        )
        .frame(
            width: FocusScreenLayout.bubbleDiameter,
            height: FocusScreenLayout.bubbleDiameter
        )

        if isImmersive {
            bubbleView
                .contentShape(Circle())
                .onTapGesture {
                    handleImmersiveBubbleTap()
                }
        } else {
            bubbleView
        }
    }

    private func topChrome(
        renderState: FocusRenderState,
        layout: FocusScreenLayout
    ) -> some View {
        VStack(spacing: 0) {
            ZStack {
                PhaseStatusBadge(text: renderState.statusText, phase: renderState.phase)
                    .fixedSize(horizontal: true, vertical: false)

                HStack {
                    topActionSlot {
                        if renderState.shouldShowBackAction {
                            FocusCornerIconButton(
                                systemImage: "chevron.left",
                                accessibilityLabel: "Back to last step",
                                isEnabled: renderState.canGoBack,
                                action: store.goBackOneStep
                            )
                        }
                    }

                    Spacer(minLength: layout.topChromeInnerSpacing)

                    topActionSlot {
                        if renderState.shouldShowFinishAction {
                            FocusCornerIconButton(
                                systemImage: "flag.checkered",
                                accessibilityLabel: "Finish session early",
                                isEnabled: true,
                                action: requestFinishConfirmation
                            )
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, layout.topChromePadding)
        .padding(.horizontal, FocusScreenLayout.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func bottomChrome(
        renderState: FocusRenderState,
        layout: FocusScreenLayout
    ) -> some View {
        VStack(spacing: layout.bottomChromeSpacing) {
            SessionProgressPill(
                phase: renderState.phase,
                nodeStates: renderState.nodeStates
            )
            .fixedSize(horizontal: true, vertical: false)

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, layout.bottomChromeTopPadding)
        .padding(.horizontal, FocusScreenLayout.horizontalPadding)
    }

    @ViewBuilder
    private func topActionSlot<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Circle()
                .fill(Color.clear)
            content()
        }
        .frame(
            width: FocusScreenLayout.topActionButtonSize,
            height: FocusScreenLayout.topActionButtonSize
        )
    }

    private func handleBackgroundTap() {
        guard canEnterImmersiveMode else { return }
        toggleImmersiveMode()
    }

    private func handleImmersiveBubbleTap() {
        guard canEnterImmersiveMode, isImmersive else { return }
        store.togglePrimaryAction()
    }

    private func toggleImmersiveMode() {
        let newValue = !isImmersive
        withAnimation(.easeOut(duration: 0.18)) {
            isImmersive = newValue
        }

        if newValue {
            showImmersiveHint()
        } else {
            hideImmersiveHint()
        }
    }

    private func showImmersiveHint() {
        immersiveHintDismissTask?.cancel()

        withAnimation(.easeOut(duration: 0.18)) {
            immersiveHintVisible = true
        }

        immersiveHintDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.18)) {
                immersiveHintVisible = false
            }
        }
    }

    private func hideImmersiveHint() {
        immersiveHintDismissTask?.cancel()
        immersiveHintVisible = false
    }

    private var canEnterImmersiveMode: Bool {
        completionSummaryState == nil
            && store.currentRunState == .running
            && store.selectedTab == .focus
            && scenePhase == .active
            && !isVoiceOverRunning
    }

    private var shouldKeepImmersiveMode: Bool {
        completionSummaryState == nil
            && store.currentRunState == .running
            && store.selectedTab == .focus
            && !isVoiceOverRunning
    }

    private func syncImmersiveState() {
        guard shouldKeepImmersiveMode else {
            if isImmersive {
                withAnimation(.easeOut(duration: 0.18)) {
                    isImmersive = false
                }
            }
            hideImmersiveHint()
            isShowingFinishConfirmation = false
            return
        }

        if scenePhase != .active {
            hideImmersiveHint()
            isShowingFinishConfirmation = false
        }
    }

    private func syncVoiceOverState() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    }

    private func syncCompletionSummary(with session: SessionSnapshot?) {
        guard let session, session.runState == .completed else {
            if completionSummaryState != nil {
                completionSummaryState = nil
            }
            isShowingFinishConfirmation = false
            return
        }

        let updatedState = FocusCompletionSummaryState.make(from: session)
        if completionSummaryState != updatedState {
            completionSummaryState = updatedState
        }
        isImmersive = false
        hideImmersiveHint()
        isShowingFinishConfirmation = false
    }

    private func requestFinishConfirmation() {
        isShowingFinishConfirmation = true
    }

    private func handleCompletionDismissal() {
        hideImmersiveHint()
        isImmersive = false
        isShowingFinishConfirmation = false
        completionSummaryState = nil
        store.dismissCompletedSession()
    }
}

struct FocusScreenLayout {
    static let bubbleDiameter: CGFloat = 280
    static let horizontalPadding: CGFloat = 24
    static let topActionButtonSize: CGFloat = 44
    static let secondaryActionRowWidth: CGFloat = 261.29
    static let secondaryActionSpacing: CGFloat = 16
    static let immersiveHintOffset: CGFloat = -188

    let size: CGSize
    let safeAreaInsets: EdgeInsets

    var isCompact: Bool {
        size.height < 760
    }

    var topChromePadding: CGFloat {
        if safeAreaInsets.top > FocusScreenLayout.topActionButtonSize {
            return safeAreaInsets.top - FocusScreenLayout.topActionButtonSize + (isCompact ? 2 : 4)
        }

        return safeAreaInsets.top + (isCompact ? 2 : 4)
    }

    var topChromeInnerSpacing: CGFloat {
        20
    }

    var bottomChromeSpacing: CGFloat {
        isCompact ? 16 : 18
    }

    var bottomChromeTopPadding: CGFloat {
        (size.height / 2) + (FocusScreenLayout.bubbleDiameter / 2) + (isCompact ? 16 : 22)
    }
}
