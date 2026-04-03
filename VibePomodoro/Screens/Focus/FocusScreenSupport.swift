import SwiftUI

enum FocusScreenSupport {
    static func bubblePosition(
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect,
        stableBubbleAnchor: CGPoint?,
        isImmersive: Bool,
        isRestoringImmersiveLayout: Bool
    ) -> CGPoint {
        CGPoint(
            x: size.width / 2,
            y: resolvedBubbleCenterY(
                layout: layout,
                containerFrame: containerFrame,
                stableBubbleAnchor: stableBubbleAnchor,
                isImmersive: isImmersive,
                isRestoringImmersiveLayout: isRestoringImmersiveLayout
            )
        )
    }

    static func bubbleHitFrame(
        layout: FocusScreenLayout,
        size: CGSize,
        containerFrame: CGRect,
        stableBubbleAnchor: CGPoint?,
        isImmersive: Bool,
        isRestoringImmersiveLayout: Bool
    ) -> CGRect {
        let bubbleCenter = bubblePosition(
            layout: layout,
            size: size,
            containerFrame: containerFrame,
            stableBubbleAnchor: stableBubbleAnchor,
            isImmersive: isImmersive,
            isRestoringImmersiveLayout: isRestoringImmersiveLayout
        )
        let radius = FocusScreenLayout.bubbleDiameter / 2

        return CGRect(
            x: bubbleCenter.x - radius,
            y: bubbleCenter.y - radius,
            width: FocusScreenLayout.bubbleDiameter,
            height: FocusScreenLayout.bubbleDiameter
        )
    }

    static func bottomChromeTopPadding(
        layout: FocusScreenLayout,
        bubbleCenterY: CGFloat
    ) -> CGFloat {
        bubbleCenterY + (FocusScreenLayout.bubbleDiameter / 2) + layout.bottomChromeOffset
    }

    static func shouldRefreshStableBubbleAnchor(
        containerSize: CGSize,
        stableBubbleAnchor: CGPoint?,
        stableBubbleAnchorContainerSize: CGSize,
        isImmersive: Bool,
        isRestoringImmersiveLayout: Bool
    ) -> Bool {
        guard !isRestoringImmersiveLayout else { return false }
        guard !isImmersive else { return stableBubbleAnchor == nil }
        guard stableBubbleAnchor != nil else { return true }

        let widthDelta = abs(stableBubbleAnchorContainerSize.width - containerSize.width)
        let heightDelta = abs(stableBubbleAnchorContainerSize.height - containerSize.height)

        return widthDelta > FocusScreenLayout.immersiveAnchorResetEpsilon
            || heightDelta > FocusScreenLayout.immersiveAnchorResetEpsilon
    }

    static func shouldEndImmersiveLayoutRestore(
        containerSize: CGSize,
        stableBubbleAnchorContainerSize: CGSize
    ) -> Bool {
        guard stableBubbleAnchorContainerSize != .zero else { return true }

        let widthDelta = abs(stableBubbleAnchorContainerSize.width - containerSize.width)
        let heightDelta = abs(stableBubbleAnchorContainerSize.height - containerSize.height)

        return widthDelta <= FocusScreenLayout.layoutSettlingEpsilon
            && heightDelta <= FocusScreenLayout.layoutSettlingEpsilon
    }

    static func chromeOpacity(
        hasCompletionSummary: Bool,
        immersiveVisualsHidden: Bool
    ) -> Double {
        hasCompletionSummary || immersiveVisualsHidden ? 0 : 1
    }

    static func isChromeInteractive(
        hasCompletionSummary: Bool,
        immersiveVisualsHidden: Bool
    ) -> Bool {
        !hasCompletionSummary && !immersiveVisualsHidden
    }

    static func shouldHideSystemOverlays(
        hasCompletionSummary: Bool,
        immersiveVisualsHidden: Bool
    ) -> Bool {
        !hasCompletionSummary && immersiveVisualsHidden
    }

    static func targetTabBarHidden(
        selectedTab: AppTab,
        hasCompletionSummary: Bool,
        immersiveVisualsHidden: Bool
    ) -> Bool {
        selectedTab == .focus && !hasCompletionSummary && immersiveVisualsHidden
    }

    private static func resolvedBubbleCenterY(
        layout: FocusScreenLayout,
        containerFrame: CGRect,
        stableBubbleAnchor: CGPoint?,
        isImmersive: Bool,
        isRestoringImmersiveLayout: Bool
    ) -> CGFloat {
        guard let stableBubbleAnchor,
              shouldUseStableContentAnchor(
                stableBubbleAnchor: stableBubbleAnchor,
                isImmersive: isImmersive,
                isRestoringImmersiveLayout: isRestoringImmersiveLayout
              ) else {
            return layout.defaultBubbleCenterY
        }

        return stableBubbleAnchor.y - containerFrame.minY
    }

    private static func shouldUseStableContentAnchor(
        stableBubbleAnchor _: CGPoint,
        isImmersive: Bool,
        isRestoringImmersiveLayout: Bool
    ) -> Bool {
        return isImmersive || isRestoringImmersiveLayout
    }
}
