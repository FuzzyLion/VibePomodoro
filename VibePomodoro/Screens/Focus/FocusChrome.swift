import SwiftUI

struct FocusPageContent: View {
    let renderState: FocusRenderState
    let layout: FocusScreenLayout
    let size: CGSize
    let bubbleCenter: CGPoint
    let progressDotsTopPadding: CGFloat
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

            FocusProgressDotsChrome(
                renderState: renderState,
                topPadding: progressDotsTopPadding
            )
            .opacity(chromeOpacity)

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
        let bubbleShape = BubbleGlassShape(phase: renderState.phase)
        let isDark = colorScheme == .dark

        ZStack {
            bubbleShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.030 : 0.145),
                            renderState.phase.tintColor.opacity(isDark ? 0.030 : 0.060),
                            renderState.phase.shadowColor.opacity(isDark ? 0.018 : 0.035)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            bubbleShape
                .stroke(
                    Color.white.opacity(isDark ? 0.12 : 0.34),
                    lineWidth: isDark ? 0.9 : 1.0
                )

            bubbleShape
                .stroke(
                    renderState.phase.shadowColor.opacity(isDark ? 0.035 : 0.045),
                    lineWidth: 10
                )
                .blur(radius: isDark ? 7 : 5)
                .scaleEffect(1.012)
        }
        .frame(
            width: FocusScreenLayout.bubbleDiameter,
            height: FocusScreenLayout.bubbleDiameter
        )
        .position(bubbleCenter)
        .opacity(isDark ? 0.28 : 0.32)
        .blur(radius: isDark ? 3.2 : 2.6)
        .frame(width: size.width, height: size.height, alignment: .center)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct FocusProgressDotsChrome: View {
    let renderState: FocusRenderState
    let topPadding: CGFloat

    var body: some View {
        SessionProgressDots(
            phase: renderState.phase,
            nodeStates: renderState.nodeStates
        )
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, topPadding)
        .allowsHitTesting(false)
        .modifier(
            FocusPhaseBreathModifier(
                phase: renderState.phase,
                lift: 2.2,
                scaleAmount: 0.015,
                opacityDrop: 0.06,
                shadowBoost: 0.08
            )
        )
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
                    FocusActionSlot(size: FocusScreenLayout.topActionButtonHitSize) {
                        FocusTopBarButton(
                            systemImage: "arrow.counterclockwise",
                            isEnabled: renderState.canReset,
                            accessibilityLabel: "Reset current step",
                            action: resetAction
                        )
                    }

                    Spacer(minLength: layout.topChromeInnerSpacing)

                    FocusActionSlot(size: FocusScreenLayout.topActionButtonHitSize) {
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
        .padding(.horizontal, FocusScreenLayout.topChromeHorizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .modifier(
            FocusPhaseBreathModifier(
                phase: renderState.phase,
                lift: 1.2,
                scaleAmount: 0.010,
                opacityDrop: 0.04,
                shadowBoost: 0
            )
        )
    }
}

private struct FocusBottomChrome: View {
    let renderState: FocusRenderState
    let topPadding: CGFloat
    let primaryAction: () -> Void
    let goBackAction: () -> Void
    let skipAction: () -> Void

    var body: some View {
        HStack(spacing: FocusScreenLayout.bottomControlSpacing) {
            GlassEffectContainer(spacing: FocusScreenLayout.bottomGlassMergeSpacing) {
                HStack(spacing: FocusScreenLayout.bottomControlSpacing) {
                    FocusActionSlot(size: FocusScreenLayout.bottomSecondaryButtonHitSize) {
                        FocusBottomSecondaryButton(
                            systemImage: "chevron.left.2",
                            isEnabled: renderState.shouldShowBackAction && renderState.canGoBack,
                            accessibilityLabel: "Back to last step",
                            action: goBackAction
                        )
                    }

                    FocusPrimaryControlButton(
                        title: renderState.bubble.actionTitle,
                        systemImage: primaryActionIconName,
                        action: primaryAction
                    )

                    FocusActionSlot(size: FocusScreenLayout.bottomSecondaryButtonHitSize) {
                        FocusBottomSecondaryButton(
                            systemImage: "chevron.right.2",
                            isEnabled: renderState.canSkip,
                            accessibilityLabel: "Skip current step",
                            action: skipAction
                        )
                    }
                }
            }
        }
        .frame(width: FocusScreenLayout.bottomControlRowWidth)
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
    let size: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(width: size, height: size)
            .contentShape(Rectangle())
    }
}

private struct FocusPhaseBreathModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let phase: SessionPhase
    let lift: CGFloat
    let scaleAmount: CGFloat
    let opacityDrop: Double
    let shadowBoost: Double

    @State private var pulse: CGFloat = 0
    @State private var pulseTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .scaleEffect(1 + (pulse * scaleAmount))
            .offset(y: -pulse * lift)
            .opacity(1 - (Double(pulse) * opacityDrop))
            .shadow(
                color: phase.shadowColor.opacity(Double(pulse) * shadowBoost),
                radius: Double(pulse) * 10,
                y: Double(pulse) * 2
            )
            .onChange(of: phase) { oldValue, newValue in
                guard oldValue != newValue else { return }
                triggerPhaseBreath()
            }
            .onDisappear {
                pulseTask?.cancel()
            }
    }

    private func triggerPhaseBreath() {
        pulseTask?.cancel()

        guard !reduceMotion else {
            pulse = 0
            return
        }

        withAnimation(FocusScreenLayout.phaseChromeBreathInAnimation) {
            pulse = 1
        }

        pulseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: FocusScreenLayout.phaseChromeBreathHoldDuration)
            guard !Task.isCancelled else { return }

            withAnimation(FocusScreenLayout.phaseChromeBreathOutAnimation) {
                pulse = 0
            }
        }
    }
}
