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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isImmersive = false
    @State private var isShowingFinishConfirmation = false
    @State private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @State private var completionSummaryState: FocusCompletionSummaryState?
    @State private var immersiveVisualsHidden = false
    @State private var stableBubbleAnchor: CGPoint?
    @State private var stableBubbleAnchorContainerSize: CGSize = .zero
    @State private var isRestoringImmersiveLayout = false
    @State private var immersiveLayoutRestoreTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let layout = FocusScreenLayout(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            let containerFrame = proxy.frame(in: .global)
            let renderState = FocusRenderState.build(store: store, scenePhase: scenePhase)
            ZStack {
                pageContent(
                    renderState: renderState,
                    layout: layout,
                    size: proxy.size,
                    containerFrame: containerFrame
                )
                    .opacity(completionSummaryState == nil ? 1 : 0.22)
                    .blur(radius: completionSummaryState == nil ? 0 : 10)
                    .animation(.easeOut(duration: 0.22), value: completionSummaryState != nil)

                if let completionSummaryState {
                    FocusCompletionSummaryView(state: completionSummaryState) {
                        handleCompletionDismissal()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    .zIndex(2)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .statusBarHidden(shouldHideSystemOverlays)
            .persistentSystemOverlays(shouldHideSystemOverlays ? .hidden : .visible)
            .preference(
                key: FocusTabBarVisibilityPreferenceKey.self,
                value: shouldHideTabBarChrome
            )
            .onAppear {
                syncVoiceOverState()
                syncCompletionSummary(with: store.activeSession)
                syncImmersiveState()
                syncBubbleAnchor(layout: layout, containerFrame: containerFrame)
                syncImmersiveVisualState()
            }
            .onChange(of: layout.bubbleAnchorSignature) { _, _ in
                syncBubbleAnchor(layout: layout, containerFrame: containerFrame)
            }
            .onChange(of: isImmersive) { _, _ in
                syncBubbleAnchor(layout: layout, containerFrame: containerFrame)
                syncImmersiveVisualState()
            }
            .onChange(of: isRestoringImmersiveLayout) { _, _ in
                syncBubbleAnchor(layout: layout, containerFrame: containerFrame)
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
        size: CGSize,
        containerFrame: CGRect
    ) -> some View {
        ZStack {
            backgroundTapLayer(
                layout: layout,
                size: size,
                containerFrame: containerFrame
            )

            bubbleLayer(
                renderState: renderState,
                layout: layout,
                size: size,
                containerFrame: containerFrame
            )

            topChrome(renderState: renderState, layout: layout)
                .opacity(chromeOpacity)
                .allowsHitTesting(isChromeInteractive)

            bottomChrome(
                renderState: renderState,
                layout: layout,
                size: size,
                containerFrame: containerFrame
            )
            .opacity(chromeOpacity)
            .allowsHitTesting(isChromeInteractive)
        }
        .frame(width: size.width, height: size.height, alignment: .center)
        .allowsHitTesting(completionSummaryState == nil)
    }

    private func backgroundTapLayer(
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect
    ) -> some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        handleScreenTap(
                            at: value.location,
                            layout: layout,
                            size: size,
                            containerFrame: containerFrame
                        )
                    }
            )
    }

    @ViewBuilder
    private func bubbleLayer(
        renderState: FocusRenderState,
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect
    ) -> some View {
        let bubbleView = BubbleTimerView(
            renderState: renderState.bubble,
            controlVisibility: bubbleControlOpacity,
            controlIsInteractive: isChromeInteractive,
            action: store.togglePrimaryAction
        )
        .frame(
            width: FocusScreenLayout.bubbleDiameter,
            height: FocusScreenLayout.bubbleDiameter
        )
        .position(bubblePosition(layout: layout, size: size, containerFrame: containerFrame))

        bubbleView
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
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect
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
        .padding(
            .top,
            bottomChromeTopPadding(
                layout: layout,
                size: size,
                containerFrame: containerFrame
            )
        )
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

    private func handleScreenTap(
        at location: CGPoint,
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect
    ) {
        guard canEnterImmersiveMode else { return }

        if isImmersive {
            toggleImmersiveMode(force: false)
            return
        }

        guard !bubbleHitFrame(layout: layout, size: size, containerFrame: containerFrame).contains(location) else {
            return
        }

        toggleImmersiveMode(force: true)
    }

    private func toggleImmersiveMode(force newValue: Bool? = nil) {
        setImmersiveMode(newValue ?? !isImmersive)
    }

    private func setImmersiveMode(_ newValue: Bool) {
        setImmersiveVisualsHidden(newValue)

        guard isImmersive != newValue || (newValue == false && isRestoringImmersiveLayout) else {
            return
        }

        if newValue {
            endImmersiveLayoutRestore()
            isImmersive = true
            return
        }

        let wasImmersive = isImmersive
        isImmersive = false

        if wasImmersive {
            beginImmersiveLayoutRestore()
        }
    }

    private func beginImmersiveLayoutRestore() {
        immersiveLayoutRestoreTask?.cancel()
        isRestoringImmersiveLayout = true

        immersiveLayoutRestoreTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: FocusScreenLayout.immersiveLayoutRestoreFallbackDelay)
            guard !Task.isCancelled else { return }
            guard !isImmersive else { return }
            isRestoringImmersiveLayout = false
        }
    }

    private func endImmersiveLayoutRestore() {
        immersiveLayoutRestoreTask?.cancel()
        immersiveLayoutRestoreTask = nil
        isRestoringImmersiveLayout = false
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
                setImmersiveMode(false)
            } else {
                endImmersiveLayoutRestore()
            }
            setImmersiveVisualsHidden(false)
            isShowingFinishConfirmation = false
            return
        }

        if scenePhase != .active {
            isShowingFinishConfirmation = false
        }
    }

    private func bubblePosition(
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect
    ) -> CGPoint {
        CGPoint(
            x: size.width / 2,
            y: resolvedBubbleCenterY(
                layout: layout,
                size: size,
                containerFrame: containerFrame
            )
        )
    }

    private func bubbleHitFrame(
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect
    ) -> CGRect {
        let bubbleCenter = bubblePosition(layout: layout, size: size, containerFrame: containerFrame)
        let radius = FocusScreenLayout.bubbleDiameter / 2

        return CGRect(
            x: bubbleCenter.x - radius,
            y: bubbleCenter.y - radius,
            width: FocusScreenLayout.bubbleDiameter,
            height: FocusScreenLayout.bubbleDiameter
        )
    }

    private func bottomChromeTopPadding(
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect
    ) -> CGFloat {
        resolvedBubbleCenterY(
            layout: layout,
            size: size,
            containerFrame: containerFrame
        ) + (FocusScreenLayout.bubbleDiameter / 2) + layout.bottomChromeOffset
    }

    private func resolvedBubbleCenterY(
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect
    ) -> CGFloat {
        let defaultCenterY = layout.defaultBubbleCenterY

        guard let stableBubbleAnchor, shouldUseStableContentAnchor else {
            return defaultCenterY
        }

        return stableBubbleAnchor.y - containerFrame.minY
    }

    private func syncBubbleAnchor(layout: FocusScreenLayout, containerFrame: CGRect) {
        if isRestoringImmersiveLayout,
           shouldEndImmersiveLayoutRestore(for: containerFrame.size) {
            endImmersiveLayoutRestore()
        }

        guard shouldRefreshStableBubbleAnchor(for: containerFrame.size) else { return }

        stableBubbleAnchor = CGPoint(
            x: containerFrame.midX,
            y: containerFrame.minY + layout.defaultBubbleCenterY
        )
        stableBubbleAnchorContainerSize = containerFrame.size
    }

    private func shouldRefreshStableBubbleAnchor(for containerSize: CGSize) -> Bool {
        guard !isRestoringImmersiveLayout else { return false }
        guard !isImmersive else { return stableBubbleAnchor == nil }
        guard stableBubbleAnchor != nil else { return true }

        let widthDelta = abs(stableBubbleAnchorContainerSize.width - containerSize.width)
        let heightDelta = abs(stableBubbleAnchorContainerSize.height - containerSize.height)

        return widthDelta > FocusScreenLayout.immersiveAnchorResetEpsilon
            || heightDelta > FocusScreenLayout.immersiveAnchorResetEpsilon
    }

    private func shouldEndImmersiveLayoutRestore(for containerSize: CGSize) -> Bool {
        guard stableBubbleAnchorContainerSize != .zero else { return true }

        let widthDelta = abs(stableBubbleAnchorContainerSize.width - containerSize.width)
        let heightDelta = abs(stableBubbleAnchorContainerSize.height - containerSize.height)

        return widthDelta <= FocusScreenLayout.layoutSettlingEpsilon
            && heightDelta <= FocusScreenLayout.layoutSettlingEpsilon
    }

    private var shouldUseStableContentAnchor: Bool {
        stableBubbleAnchor != nil && (isImmersive || isRestoringImmersiveLayout)
    }

    private var chromeOpacity: Double {
        completionSummaryState == nil && !immersiveVisualsHidden ? 1 : 0
    }

    private var bubbleControlOpacity: Double {
        chromeOpacity
    }

    private var isChromeInteractive: Bool {
        completionSummaryState == nil && !immersiveVisualsHidden
    }

    private var shouldHideSystemOverlays: Bool {
        completionSummaryState == nil && immersiveVisualsHidden
    }

    private var shouldHideTabBarChrome: Bool {
        store.selectedTab == .focus && completionSummaryState == nil && immersiveVisualsHidden
    }

    private func syncImmersiveVisualState() {
        setImmersiveVisualsHidden(isImmersive && completionSummaryState == nil)
    }

    private func setImmersiveVisualsHidden(_ hidden: Bool) {
        guard immersiveVisualsHidden != hidden else { return }

        if reduceMotion {
            immersiveVisualsHidden = hidden
            return
        }

        withAnimation(FocusScreenLayout.immersiveVisualFadeAnimation) {
            immersiveVisualsHidden = hidden
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
        setImmersiveMode(false)
        setImmersiveVisualsHidden(false)
        isShowingFinishConfirmation = false
    }

    private func requestFinishConfirmation() {
        isShowingFinishConfirmation = true
    }

    private func handleCompletionDismissal() {
        setImmersiveMode(false)
        isShowingFinishConfirmation = false
        completionSummaryState = nil
        store.dismissCompletedSession()
    }
}

fileprivate struct FocusBubbleAnchorSignature: Equatable {
    let size: CGSize
    let topInset: CGFloat
    let bottomInset: CGFloat
}

struct FocusScreenLayout {
    static let bubbleDiameter: CGFloat = 280
    static let horizontalPadding: CGFloat = 24
    static let topActionButtonSize: CGFloat = 44
    static let secondaryActionRowWidth: CGFloat = 261.29
    static let secondaryActionSpacing: CGFloat = 16
    static let immersiveAnchorResetEpsilon: CGFloat = 1
    static let layoutSettlingEpsilon: CGFloat = 1
    static let immersiveLayoutRestoreFallbackDelay: UInt64 = 450_000_000
    static let immersiveVisualFadeAnimation = Animation.easeOut(duration: 0.18)

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

    var defaultBubbleCenterY: CGFloat {
        size.height / 2
    }

    var bottomChromeOffset: CGFloat {
        isCompact ? 16 : 22
    }

    fileprivate var bubbleAnchorSignature: FocusBubbleAnchorSignature {
        FocusBubbleAnchorSignature(
            size: size,
            topInset: safeAreaInsets.top,
            bottomInset: safeAreaInsets.bottom
        )
    }
}
