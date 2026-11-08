import SwiftUI
import UIKit

struct FocusScreen: View {
    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var tabBarChromeHidden: Bool

    /// Tapping the background hides the chrome, the status bar, and the tab bar.
    @State private var isImmersive = false
    /// Hiding the status bar can change the safe area. While that happens, the bubble stays
    /// at its last global position, and leaving immersive mode keeps it there until the
    /// layout has settled back.
    @State private var pinnedBubble: PinnedBubble?
    @State private var completionSummaryState: FocusCompletionSummaryState?
    @State private var isShowingFinishConfirmation = false
    @State private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning

    var body: some View {
        GeometryReader { proxy in
            let layout = FocusScreenLayout(proxy: proxy)
            let summaryState = presentedCompletionSummaryState
            let bubbleCenter = layout.bubbleCenter(
                pinnedGlobalY: summaryState == nil ? pinnedBubble?.globalY : nil
            )
            let renderState = FocusRenderState.build(store: store, scenePhase: scenePhase)

            ZStack {
                if let summaryState {
                    FocusCompletionBackdropBubble(
                        renderState: renderState.bubble,
                        size: layout.size,
                        bubbleCenter: bubbleCenter
                    )

                    FocusCompletionSummaryView(state: summaryState, doneAction: dismissCompletionSummary)
                        .zIndex(2)
                } else {
                    FocusPageContent(
                        renderState: renderState,
                        layout: layout,
                        bubbleCenter: bubbleCenter,
                        isChromeHidden: isImmersive,
                        onBackgroundTap: { location in
                            handleBackgroundTap(at: location, layout: layout, bubbleCenter: bubbleCenter)
                        },
                        onRequestFinish: { isShowingFinishConfirmation = true }
                    )
                }
            }
            .animation(
                reduceMotion ? nil : FocusCompletionMotion.containerFadeInAnimation,
                value: summaryState != nil
            )
            .frame(width: layout.size.width, height: layout.size.height, alignment: .top)
            .statusBarHidden(hidesSystemOverlays)
            .persistentSystemOverlays(hidesSystemOverlays ? .hidden : .visible)
            .onAppear {
                isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
                syncWithStore()
            }
            .onChange(of: store.activeSession?.id) { syncWithStore() }
            .onChange(of: store.activeSession?.runState) { syncWithStore() }
            .onChange(of: store.selectedTab) { syncWithStore() }
            .onChange(of: scenePhase) { syncWithStore() }
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
                isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
                syncWithStore()
            }
            .onChange(of: wantsTabBarHidden, initial: true) { _, hidden in
                tabBarChromeHidden = hidden
            }
            .onChange(of: isImmersive) { releasePinIfSettled(containerSize: layout.size) }
            .onChange(of: layout.size) { _, size in releasePinIfSettled(containerSize: size) }
            .task(id: isRestoringLayout) {
                guard isRestoringLayout else { return }
                try? await Task.sleep(for: FocusScreenLayout.immersiveLayoutRestoreFallbackDelay)
                guard !Task.isCancelled else { return }
                pinnedBubble = nil
            }
            .alert("Finish session early?", isPresented: $isShowingFinishConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Finish session early") { store.finishSessionEarly() }
            } message: {
                Text("This will end the current session and show the completion summary.")
            }
        }
        .background {
            VibeBackground()
        }
    }

    private var presentedCompletionSummaryState: FocusCompletionSummaryState? {
        completionSummaryState ?? FocusCompletionSummaryState(session: store.activeSession)
    }

    private var immersiveModeAllowed: Bool {
        presentedCompletionSummaryState == nil
            && store.selectedTab == .focus
            && scenePhase == .active
            && !isVoiceOverRunning
    }

    private var hidesSystemOverlays: Bool {
        isImmersive && presentedCompletionSummaryState == nil
    }

    private var wantsTabBarHidden: Bool {
        store.selectedTab == .focus && (isImmersive || presentedCompletionSummaryState != nil)
    }

    private var isRestoringLayout: Bool {
        pinnedBubble != nil && !isImmersive
    }

    private func handleBackgroundTap(at location: CGPoint, layout: FocusScreenLayout, bubbleCenter: CGPoint) {
        guard immersiveModeAllowed else { return }

        if isImmersive {
            setImmersive(false)
        } else if !FocusScreenLayout.bubbleFrame(center: bubbleCenter).contains(location) {
            setImmersive(true, capturing: layout)
        }
    }

    private func setImmersive(_ immersive: Bool, capturing layout: FocusScreenLayout? = nil) {
        guard isImmersive != immersive else { return }

        if immersive, pinnedBubble == nil, let layout {
            pinnedBubble = PinnedBubble(globalY: layout.defaultBubbleGlobalY, containerSize: layout.size)
        }

        withAnimation(reduceMotion ? nil : FocusScreenLayout.immersiveVisualFadeAnimation) {
            isImmersive = immersive
        }
    }

    private func releasePinIfSettled(containerSize: CGSize) {
        guard let pinnedBubble, !isImmersive else { return }

        let epsilon = FocusScreenLayout.layoutSettlingEpsilon
        if abs(pinnedBubble.containerSize.width - containerSize.width) <= epsilon,
           abs(pinnedBubble.containerSize.height - containerSize.height) <= epsilon {
            self.pinnedBubble = nil
        }
    }

    private func syncWithStore() {
        syncCompletionSummary()

        guard !immersiveModeAllowed else { return }

        if isImmersive {
            setImmersive(false)
        } else {
            pinnedBubble = nil
        }
        isShowingFinishConfirmation = false
    }

    private func syncCompletionSummary() {
        isShowingFinishConfirmation = false

        let state = FocusCompletionSummaryState(session: store.activeSession)
        guard completionSummaryState != state else { return }

        let animation = state == nil
            ? FocusCompletionMotion.containerFadeOutAnimation
            : FocusCompletionMotion.containerFadeInAnimation
        withAnimation(reduceMotion ? nil : animation) {
            completionSummaryState = state
        }
    }

    private func dismissCompletionSummary() {
        withAnimation(reduceMotion ? nil : FocusCompletionMotion.containerFadeOutAnimation) {
            completionSummaryState = nil
        }
        store.dismissCompletedSession()
        setImmersive(false)
        isShowingFinishConfirmation = false
    }
}

private struct PinnedBubble: Equatable {
    let globalY: CGFloat
    let containerSize: CGSize
}
