import SwiftUI

struct FocusPageContent: View {
    let renderState: FocusRenderState
    let layout: FocusScreenLayout
    let size: CGSize
    let bubbleCenter: CGPoint
    let bottomChromeTopPadding: CGFloat
    let chromeOpacity: Double
    let isChromeInteractive: Bool
    let backgroundTapAction: (CGPoint) -> Void
    let primaryAction: () -> Void
    let goBackAction: () -> Void
    let resetAction: () -> Void
    let requestFinishAction: () -> Void
    let skipAction: () -> Void

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
                renderState: renderState.bubble
            )
            .frame(
                width: FocusScreenLayout.bubbleDiameter,
                height: FocusScreenLayout.bubbleDiameter
            )
            .position(bubbleCenter)

            FocusTopChrome(
                renderState: renderState,
                layout: layout,
                resetAction: resetAction,
                requestFinishAction: requestFinishAction
            )
            .opacity(chromeOpacity)
            .allowsHitTesting(isChromeInteractive)

            FocusBottomChrome(
                renderState: renderState,
                layout: layout,
                topPadding: bottomChromeTopPadding,
                primaryAction: primaryAction,
                goBackAction: goBackAction,
                skipAction: skipAction
            )
            .opacity(chromeOpacity)
            .allowsHitTesting(isChromeInteractive)
        }
        .frame(width: size.width, height: size.height, alignment: .center)
    }
}

struct FocusCompletionBackdropBubble: View {
    @Environment(\.colorScheme) private var colorScheme

    let renderState: BubbleRenderState
    let size: CGSize
    let bubbleCenter: CGPoint

    var body: some View {
        BubbleTimerView(
            renderState: renderState,
            showsForegroundContent: false
        )
        .frame(
            width: FocusScreenLayout.bubbleDiameter,
            height: FocusScreenLayout.bubbleDiameter
        )
        .position(bubbleCenter)
        .opacity(colorScheme == .dark ? 0.18 : 0.14)
        .blur(radius: colorScheme == .dark ? 5 : 4)
        .frame(width: size.width, height: size.height, alignment: .center)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct FocusTopChrome: View {
    let renderState: FocusRenderState
    let layout: FocusScreenLayout
    let resetAction: () -> Void
    let requestFinishAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                FocusStatusTitle(text: renderState.statusText, phase: renderState.phase)
                    .fixedSize(horizontal: true, vertical: false)

                HStack {
                    FocusActionSlot {
                        FocusTopBarButton(
                            systemImage: "arrow.counterclockwise",
                            isEnabled: renderState.canReset,
                            accessibilityLabel: "Reset current step",
                            action: resetAction
                        )
                    }

                    Spacer(minLength: layout.topChromeInnerSpacing)

                    FocusActionSlot {
                        if renderState.shouldShowFinishAction {
                            FocusTopBarButton(
                                systemImage: "flag.checkered",
                                isEnabled: true,
                                accessibilityLabel: "Finish session early",
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
    let primaryAction: () -> Void
    let goBackAction: () -> Void
    let skipAction: () -> Void

    var body: some View {
        VStack(spacing: layout.bottomChromeSpacing) {
            SessionProgressDots(
                phase: renderState.phase,
                nodeStates: renderState.nodeStates
            )
            .fixedSize(horizontal: true, vertical: false)

            HStack(spacing: FocusScreenLayout.bottomControlSpacing) {
                FocusBottomSecondaryButton(
                    systemImage: "backward.end.fill",
                    isEnabled: renderState.shouldShowBackAction && renderState.canGoBack,
                    accessibilityLabel: "Back to last step",
                    action: goBackAction
                )

                FocusPrimaryControlButton(
                    title: renderState.bubble.actionTitle,
                    systemImage: primaryActionIconName,
                    action: primaryAction
                )

                FocusBottomSecondaryButton(
                    systemImage: "forward.end.fill",
                    isEnabled: renderState.canSkip,
                    accessibilityLabel: "Skip current step",
                    action: skipAction
                )
            }
            .frame(width: FocusScreenLayout.bottomControlRowWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, topPadding)
        .padding(.horizontal, FocusScreenLayout.horizontalPadding)
    }

    private var primaryActionIconName: String {
        switch renderState.bubble.actionTitle {
        case "Pause":
            return "pause.fill"
        case "Resume", "Start", "Start Again":
            return "play.fill"
        default:
            return "play.fill"
        }
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
