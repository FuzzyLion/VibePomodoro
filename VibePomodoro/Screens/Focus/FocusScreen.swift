import SwiftUI
import UIKit

struct FocusScreen: View {
    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var tabBarChromeHidden: Bool
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
            let frameState = FocusScreenFrameState(
                proxy: proxy,
                store: store,
                scenePhase: scenePhase,
                stableBubbleAnchor: stableBubbleAnchor,
                isImmersive: isImmersive,
                isRestoringImmersiveLayout: isRestoringImmersiveLayout,
                hasCompletionSummary: completionSummaryState != nil
            )
            let pageContent = FocusPageContent(
                renderState: frameState.renderState,
                layout: frameState.layout,
                size: frameState.size,
                bubbleCenter: frameState.bubbleCenter,
                progressDotsTopPadding: frameState.progressDotsTopPadding,
                bottomChromeTopPadding: frameState.bottomChromeTopPadding,
                chromeOpacity: chromeOpacity,
                isChromeInteractive: isChromeInteractive,
                backgroundTapAction: { location in
                    handleScreenTap(at: location, frameState: frameState)
                },
                primaryAction: store.togglePrimaryAction,
                goBackAction: store.goBackOneStep,
                resetAction: store.resetCurrentStep,
                requestFinishAction: requestFinishConfirmation,
                skipAction: store.skipCurrentStep
            )
            .opacity(frameState.hasCompletionSummary ? 0 : 1)
            .allowsHitTesting(!frameState.hasCompletionSummary)
            .accessibilityHidden(frameState.hasCompletionSummary)

            let completionBackdrop = FocusCompletionBackdropBubble(
                renderState: frameState.renderState.bubble,
                size: frameState.size,
                bubbleCenter: frameState.bubbleCenter
            )
            .opacity(frameState.hasCompletionSummary ? 1 : 0)

            ZStack {
                pageContent
                completionBackdrop

                if let completionSummaryState {
                    FocusCompletionSummaryView(state: completionSummaryState) {
                        handleCompletionDismissal()
                    }
                    .zIndex(2)
                }
            }
            .frame(width: frameState.size.width, height: frameState.size.height, alignment: .top)
            .statusBarHidden(shouldHideSystemOverlays)
            .persistentSystemOverlays(shouldHideSystemOverlays ? .hidden : .visible)
            .onAppear(perform: {
                handleAppearance(frameState: frameState)
            })
            .onChange(of: frameState.layout.bubbleAnchorSignature) { _, _ in
                handleBubbleAnchorSignatureChange(frameState: frameState)
            }
            .onChange(of: isImmersive) { _, _ in
                handleImmersiveStateChange(frameState: frameState)
            }
            .onChange(of: isRestoringImmersiveLayout) { _, _ in
                handleImmersiveLayoutRestoreChange(frameState: frameState)
            }
            .onChange(of: store.activeSession?.id) { _, _ in
                handleSessionStateChange()
            }
            .onChange(of: store.activeSession?.runState) { _, _ in
                handleSessionStateChange()
            }
            .onChange(of: store.selectedTab) { _, _ in
                handleSelectedTabChange()
            }
            .onChange(of: scenePhase) { _, _ in
                handleScenePhaseChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
                handleVoiceOverStatusChange()
            }
            .alert("Finish session early?", isPresented: $isShowingFinishConfirmation) {
                Button("Cancel", role: .cancel, action: cancelFinishConfirmation)
                Button("Finish session early", action: confirmFinishEarly)
            } message: {
                Text("This will end the current session and show the completion summary.")
            }
        }
    }

    private func handleScreenTap(
        at location: CGPoint,
        frameState: FocusScreenFrameState
    ) {
        handleScreenTap(
            at: location,
            layout: frameState.layout,
            size: frameState.size,
            containerFrame: frameState.containerFrame
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

        guard !FocusScreenSupport.bubbleHitFrame(
            layout: layout,
            size: size,
            containerFrame: containerFrame,
            stableBubbleAnchor: stableBubbleAnchor,
            isImmersive: isImmersive,
            isRestoringImmersiveLayout: isRestoringImmersiveLayout
        ).contains(location) else {
            return
        }

        toggleImmersiveMode(force: true)
    }

    private func handleAppearance(frameState: FocusScreenFrameState) {
        handleAppearance(layout: frameState.layout, containerFrame: frameState.containerFrame)
    }

    private func handleAppearance(layout: FocusScreenLayout, containerFrame: CGRect) {
        syncVoiceOverState()
        syncCompletionSummary(with: store.activeSession)
        syncImmersiveState()
        syncBubbleAnchor(layout: layout, containerFrame: containerFrame)
        syncImmersiveVisualState()
    }

    private func handleBubbleAnchorSignatureChange(
        frameState: FocusScreenFrameState
    ) {
        handleBubbleAnchorSignatureChange(layout: frameState.layout, containerFrame: frameState.containerFrame)
    }

    private func handleBubbleAnchorSignatureChange(
        layout: FocusScreenLayout,
        containerFrame: CGRect
    ) {
        syncBubbleAnchor(layout: layout, containerFrame: containerFrame)
    }

    private func handleImmersiveStateChange(
        frameState: FocusScreenFrameState
    ) {
        handleImmersiveStateChange(layout: frameState.layout, containerFrame: frameState.containerFrame)
    }

    private func handleImmersiveStateChange(
        layout: FocusScreenLayout,
        containerFrame: CGRect
    ) {
        syncBubbleAnchor(layout: layout, containerFrame: containerFrame)
        syncImmersiveVisualState()
    }

    private func handleImmersiveLayoutRestoreChange(
        frameState: FocusScreenFrameState
    ) {
        handleImmersiveLayoutRestoreChange(layout: frameState.layout, containerFrame: frameState.containerFrame)
    }

    private func handleImmersiveLayoutRestoreChange(
        layout: FocusScreenLayout,
        containerFrame: CGRect
    ) {
        syncBubbleAnchor(layout: layout, containerFrame: containerFrame)
    }

    private func handleSessionStateChange() {
        syncCompletionSummary(with: store.activeSession)
        syncImmersiveState()
    }

    private func handleSelectedTabChange() {
        syncImmersiveState()
    }

    private func handleScenePhaseChange() {
        syncCompletionSummary(with: store.activeSession)
        syncImmersiveState()
    }

    private func handleVoiceOverStatusChange() {
        syncVoiceOverState()
        syncImmersiveState()
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
            && store.selectedTab == .focus
            && scenePhase == .active
            && !isVoiceOverRunning
    }

    private var shouldKeepImmersiveMode: Bool {
        completionSummaryState == nil
            && store.selectedTab == .focus
            && scenePhase == .active
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

    private func syncBubbleAnchor(layout: FocusScreenLayout, containerFrame: CGRect) {
        if isRestoringImmersiveLayout,
           FocusScreenSupport.shouldEndImmersiveLayoutRestore(
            containerSize: containerFrame.size,
            stableBubbleAnchorContainerSize: stableBubbleAnchorContainerSize
           ) {
            endImmersiveLayoutRestore()
        }

        guard FocusScreenSupport.shouldRefreshStableBubbleAnchor(
            containerSize: containerFrame.size,
            stableBubbleAnchor: stableBubbleAnchor,
            stableBubbleAnchorContainerSize: stableBubbleAnchorContainerSize,
            isImmersive: isImmersive,
            isRestoringImmersiveLayout: isRestoringImmersiveLayout
        ) else { return }

        stableBubbleAnchor = CGPoint(
            x: containerFrame.midX,
            y: containerFrame.minY + layout.defaultBubbleCenterY
        )
        stableBubbleAnchorContainerSize = containerFrame.size
    }

    private var chromeOpacity: Double {
        FocusScreenSupport.chromeOpacity(
            hasCompletionSummary: completionSummaryState != nil,
            immersiveVisualsHidden: immersiveVisualsHidden
        )
    }

    private var isChromeInteractive: Bool {
        FocusScreenSupport.isChromeInteractive(
            hasCompletionSummary: completionSummaryState != nil,
            immersiveVisualsHidden: immersiveVisualsHidden
        )
    }

    private var shouldHideSystemOverlays: Bool {
        FocusScreenSupport.shouldHideSystemOverlays(
            hasCompletionSummary: completionSummaryState != nil,
            immersiveVisualsHidden: immersiveVisualsHidden
        )
    }

    private func syncImmersiveVisualState() {
        setImmersiveVisualsHidden(isImmersive && completionSummaryState == nil)
    }

    private func setImmersiveVisualsHidden(_ hidden: Bool) {
        let targetTabBarHidden = FocusScreenSupport.targetTabBarHidden(
            selectedTab: store.selectedTab,
            hasCompletionSummary: completionSummaryState != nil,
            immersiveVisualsHidden: hidden
        )

        guard immersiveVisualsHidden != hidden || tabBarChromeHidden != targetTabBarHidden else {
            return
        }

        if reduceMotion {
            immersiveVisualsHidden = hidden
            tabBarChromeHidden = targetTabBarHidden
            return
        }

        withAnimation(FocusScreenLayout.immersiveVisualFadeAnimation) {
            immersiveVisualsHidden = hidden
            tabBarChromeHidden = targetTabBarHidden
        }
    }

    private func syncVoiceOverState() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    }

    private func syncCompletionSummary(with session: SessionSnapshot?) {
        guard let session, session.runState == .completed else {
            if completionSummaryState != nil {
                if reduceMotion {
                    completionSummaryState = nil
                } else {
                    withAnimation(FocusCompletionMotion.containerFadeOutAnimation) {
                        completionSummaryState = nil
                    }
                }
            }
            isShowingFinishConfirmation = false
            return
        }

        let updatedState = FocusCompletionSummaryState.make(from: session)
        if completionSummaryState != updatedState {
            if reduceMotion {
                completionSummaryState = updatedState
            } else {
                withAnimation(FocusCompletionMotion.containerFadeInAnimation) {
                    completionSummaryState = updatedState
                }
            }
        }
        setImmersiveMode(false)
        setImmersiveVisualsHidden(false)
        isShowingFinishConfirmation = false
    }

    private func requestFinishConfirmation() {
        isShowingFinishConfirmation = true
    }

    private func cancelFinishConfirmation() {
        isShowingFinishConfirmation = false
    }

    private func confirmFinishEarly() {
        store.finishSessionEarly()
    }

    private func handleCompletionDismissal() {
        if reduceMotion {
            completionSummaryState = nil
        } else {
            withAnimation(FocusCompletionMotion.containerFadeOutAnimation) {
                completionSummaryState = nil
            }
        }
        setImmersiveMode(false)
        setImmersiveVisualsHidden(false)
        isShowingFinishConfirmation = false
        store.dismissCompletedSession()
    }
}
