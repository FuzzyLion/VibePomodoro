import SwiftUI

struct FocusPageContent: View {
    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let renderState: FocusRenderState
    let layout: FocusScreenLayout
    let bubbleCenter: CGPoint
    let isChromeHidden: Bool
    let onBackgroundTap: (CGPoint) -> Void
    let onPrimary: () -> Void
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

                FocusSummaryCaptionChrome(
                    caption: renderState.summaryCaption,
                    topPadding: layout.summaryCaptionTop(bubbleCenterY: bubbleCenter.y)
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
                    onPrimary: onPrimary,
                    onBack: store.goBackOneStep,
                    onSkip: store.skipCurrentStep
                )
            }
            // When a session ends, and when Done closes it, the status, the markers, and the
            // controls change over together rather than switching at once.
            .animation(
                reduceMotion ? FocusCompletionMotion.reducedMotionFade : FocusCompletionMotion.chrome,
                value: renderState.isSessionComplete
            )
            .opacity(isChromeHidden ? 0 : 1)
            .allowsHitTesting(!isChromeHidden)
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .center)
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

/// A finished session's breakdown under the round markers. It arrives after the vessel has
/// started to settle and leaves first when Done is tapped.
private struct FocusSummaryCaptionChrome: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let caption: String?
    let topPadding: CGFloat

    var body: some View {
        ZStack {
            if let caption {
                Text(caption)
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .monospacedDigit()
                    .foregroundStyle(FocusControlColors.captionColor(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 6)))
            }
        }
        .animation(animation, value: caption != nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, topPadding)
        .padding(.horizontal, FocusScreenLayout.horizontalPadding)
        .allowsHitTesting(false)
    }

    private var animation: Animation {
        if reduceMotion {
            return FocusCompletionMotion.reducedMotionFade
        }
        return caption != nil ? FocusCompletionMotion.captionIn : FocusCompletionMotion.captionOut
    }
}

private struct FocusTopChrome: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            // A session finished early says that what was done is kept.
            ZStack {
                if let detail = renderState.statusDetail {
                    Text(detail)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundStyle(FocusControlColors.captionColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: -4)))
                }
            }
            .animation(detailAnimation, value: renderState.statusDetail != nil)

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

    private var detailAnimation: Animation {
        if reduceMotion {
            return FocusCompletionMotion.reducedMotionFade
        }
        return renderState.statusDetail != nil ? FocusCompletionMotion.captionIn : FocusCompletionMotion.captionOut
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
