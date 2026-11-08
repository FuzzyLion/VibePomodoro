import SwiftUI

struct FocusPageContent: View {
    @EnvironmentObject private var store: PomodoroStore

    let renderState: FocusRenderState
    let layout: FocusScreenLayout
    let bubbleCenter: CGPoint
    let isChromeHidden: Bool
    let onBackgroundTap: (CGPoint) -> Void
    let onRequestFinish: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            onBackgroundTap(value.location)
                        }
                )

            BubbleTimerView(renderState: renderState.bubble)
                .frame(
                    width: FocusScreenLayout.bubbleDiameter,
                    height: FocusScreenLayout.bubbleDiameter
                )
                .position(bubbleCenter)

            Group {
                FocusProgressDotsChrome(
                    renderState: renderState,
                    topPadding: layout.progressDotsTop(bubbleCenterY: bubbleCenter.y)
                )

                FocusTopChrome(
                    renderState: renderState,
                    layout: layout,
                    onReset: store.resetCurrentStep,
                    onRequestFinish: onRequestFinish
                )

                FocusBottomChrome(
                    renderState: renderState,
                    topPadding: layout.bottomChromeTop(bubbleCenterY: bubbleCenter.y),
                    onPrimary: store.togglePrimaryAction,
                    onBack: store.goBackOneStep,
                    onSkip: store.skipCurrentStep
                )
            }
            .opacity(isChromeHidden ? 0 : 1)
            .allowsHitTesting(!isChromeHidden)
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .center)
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
    let onReset: () -> Void
    let onRequestFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                FocusStatusTitle(text: renderState.statusText, phase: renderState.phase)
                    .fixedSize(horizontal: true, vertical: false)

                HStack {
                    FocusActionSlot(size: FocusScreenLayout.topActionButtonHitSize) {
                        if renderState.canReset {
                            topButton("arrow.counterclockwise", label: "Reset current step", action: onReset)
                        }
                    }

                    Spacer(minLength: FocusScreenLayout.topChromeInnerSpacing)

                    FocusActionSlot(size: FocusScreenLayout.topActionButtonHitSize) {
                        if renderState.showsFinish {
                            topButton("flag.checkered", label: "Finish session early", action: onRequestFinish)
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

    private func topButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        FocusIconButton(
            systemImage: systemImage,
            diameter: FocusScreenLayout.topActionButtonVisualSize,
            symbolSize: 17,
            accessibilityLabel: label,
            action: action
        )
    }
}

private struct FocusBottomChrome: View {
    let renderState: FocusRenderState
    let topPadding: CGFloat
    let onPrimary: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: FocusScreenLayout.bottomControlSpacing) {
            GlassEffectContainer(spacing: FocusScreenLayout.bottomGlassMergeSpacing) {
                HStack(spacing: FocusScreenLayout.bottomControlSpacing) {
                    FocusActionSlot(size: FocusScreenLayout.bottomSecondaryButtonHitSize) {
                        if renderState.showsBack {
                            sideButton("chevron.left.2", label: "Back to last step", action: onBack)
                        }
                    }

                    FocusPrimaryControlButton(
                        action: renderState.primaryAction,
                        phase: renderState.phase,
                        onTap: onPrimary
                    )

                    FocusActionSlot(size: FocusScreenLayout.bottomSecondaryButtonHitSize) {
                        if renderState.canSkip {
                            sideButton("chevron.right.2", label: "Skip current step", action: onSkip)
                        }
                    }
                }
            }
        }
        .frame(width: FocusScreenLayout.bottomControlRowWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, topPadding)
        .padding(.horizontal, FocusScreenLayout.horizontalPadding)
    }

    private func sideButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        FocusIconButton(
            systemImage: systemImage,
            diameter: FocusScreenLayout.bottomSecondaryButtonSize,
            symbolSize: 18,
            accessibilityLabel: label,
            action: action
        )
    }
}

/// Owns a control's hit area and keeps its space when the control is hidden.
private struct FocusActionSlot<Content: View>: View {
    let size: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        Color.clear
            .frame(width: size, height: size)
            .overlay { content() }
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
