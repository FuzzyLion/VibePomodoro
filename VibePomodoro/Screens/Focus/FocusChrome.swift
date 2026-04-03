import SwiftUI

struct FocusPageContent: View {
    let renderState: FocusRenderState
    let layout: FocusScreenLayout
    let size: CGSize
    let isCompletionSummaryPresented: Bool
    let bubbleCenter: CGPoint
    let bottomChromeTopPadding: CGFloat
    let chromeOpacity: Double
    let bubbleControlOpacity: Double
    let isChromeInteractive: Bool
    let backgroundTapAction: (CGPoint) -> Void
    let primaryAction: () -> Void
    let goBackAction: () -> Void
    let requestFinishAction: () -> Void
    let skipAction: () -> Void
    let resetAction: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            backgroundTapAction(value.location)
                        }
                )

            BubbleTimerView(
                renderState: renderState.bubble,
                controlVisibility: bubbleControlOpacity,
                controlIsInteractive: isChromeInteractive,
                action: primaryAction
            )
            .frame(
                width: FocusScreenLayout.bubbleDiameter,
                height: FocusScreenLayout.bubbleDiameter
            )
            .position(bubbleCenter)

            FocusTopChrome(
                renderState: renderState,
                layout: layout,
                goBackAction: goBackAction,
                requestFinishAction: requestFinishAction
            )
            .opacity(chromeOpacity)
            .allowsHitTesting(isChromeInteractive)

            FocusBottomChrome(
                renderState: renderState,
                layout: layout,
                topPadding: bottomChromeTopPadding,
                skipAction: skipAction,
                resetAction: resetAction
            )
            .opacity(chromeOpacity)
            .allowsHitTesting(isChromeInteractive)
        }
        .frame(width: size.width, height: size.height, alignment: .center)
        .allowsHitTesting(!isCompletionSummaryPresented)
    }
}

private struct FocusTopChrome: View {
    let renderState: FocusRenderState
    let layout: FocusScreenLayout
    let goBackAction: () -> Void
    let requestFinishAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                PhaseStatusBadge(text: renderState.statusText, phase: renderState.phase)
                    .fixedSize(horizontal: true, vertical: false)

                HStack {
                    FocusActionSlot {
                        if renderState.shouldShowBackAction {
                            FocusCornerIconButton(
                                systemImage: "chevron.left",
                                accessibilityLabel: "Back to last step",
                                isEnabled: renderState.canGoBack,
                                action: goBackAction
                            )
                        }
                    }

                    Spacer(minLength: layout.topChromeInnerSpacing)

                    FocusActionSlot {
                        if renderState.shouldShowFinishAction {
                            FocusCornerIconButton(
                                systemImage: "flag.checkered",
                                accessibilityLabel: "Finish session early",
                                isEnabled: true,
                                action: requestFinishAction
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
}

private struct FocusBottomChrome: View {
    let renderState: FocusRenderState
    let layout: FocusScreenLayout
    let topPadding: CGFloat
    let skipAction: () -> Void
    let resetAction: () -> Void

    var body: some View {
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
                    action: skipAction
                )
                .frame(maxWidth: .infinity)

                SecondaryActionButton(
                    title: "Reset",
                    systemImage: "arrow.counterclockwise",
                    isEnabled: renderState.canReset,
                    glassTint: renderState.phase.glassTint,
                    action: resetAction
                )
                .frame(maxWidth: .infinity)
            }
            .frame(width: FocusScreenLayout.secondaryActionRowWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, topPadding)
        .padding(.horizontal, FocusScreenLayout.horizontalPadding)
    }
}

private struct FocusActionSlot<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
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
}
