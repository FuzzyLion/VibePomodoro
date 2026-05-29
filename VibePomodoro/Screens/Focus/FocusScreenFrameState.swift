import SwiftUI

struct FocusScreenFrameState {
    let layout: FocusScreenLayout
    let size: CGSize
    let containerFrame: CGRect
    let renderState: FocusRenderState
    let hasCompletionSummary: Bool
    let bubbleCenter: CGPoint
    let bottomChromeTopPadding: CGFloat
    let progressDotsTopPadding: CGFloat

    init(
        proxy: GeometryProxy,
        store: PomodoroStore,
        scenePhase: ScenePhase,
        stableBubbleAnchor: CGPoint?,
        isImmersive: Bool,
        isRestoringImmersiveLayout: Bool,
        hasCompletionSummary: Bool
    ) {
        let layout = FocusScreenLayout(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
        let containerFrame = proxy.frame(in: .global)
        let bubbleCenter = FocusScreenSupport.bubblePosition(
            layout: layout,
            size: proxy.size,
            containerFrame: containerFrame,
            stableBubbleAnchor: stableBubbleAnchor,
            isImmersive: isImmersive,
            isRestoringImmersiveLayout: isRestoringImmersiveLayout
        )

        self.layout = layout
        self.size = proxy.size
        self.containerFrame = containerFrame
        self.renderState = FocusRenderState.build(store: store, scenePhase: scenePhase)
        self.hasCompletionSummary = hasCompletionSummary
        self.bubbleCenter = bubbleCenter
        self.bottomChromeTopPadding = FocusScreenSupport.bottomChromeTopPadding(
            layout: layout,
            bubbleCenterY: bubbleCenter.y
        )
        self.progressDotsTopPadding = FocusScreenSupport.progressDotsTopPadding(
            layout: layout,
            bubbleCenterY: bubbleCenter.y
        )
    }
}
