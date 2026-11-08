import Foundation
import SwiftUI

struct BubbleTimerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let renderState: BubbleRenderState

    @State private var accumulatedWaveTime: TimeInterval = 0
    @State private var waveAnimationStart: Date?
    @State private var morphSourcePhase: SessionPhase = .focus
    @State private var morphTargetPhase: SessionPhase = .focus
    @State private var morphProgress: CGFloat = 1
    @State private var previousRenderState: BubbleRenderState?
    @State private var liquidSourceVisuals = BubbleLiquidVisualState()
    @State private var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        let sphereSize = FocusScreenLayout.bubbleDiameter
        // Until `onChange` starts the morph, a new phase is drawn as the first frame of the
        // morph from the previous one.
        let isPendingPhaseTransition = previousRenderState != nil && renderState.phase != morphTargetPhase

        BubbleVesselLayers(
            renderState: renderState,
            sourcePhase: isPendingPhaseTransition ? morphTargetPhase : morphSourcePhase,
            targetPhase: isPendingPhaseTransition ? renderState.phase : morphTargetPhase,
            morphProgress: isPendingPhaseTransition ? 0 : morphProgress,
            liquidSourceVisuals: isPendingPhaseTransition
                ? BubbleLiquidVisualState(renderState: previousRenderState ?? renderState, at: .now)
                : liquidSourceVisuals,
            waveClock: BubbleWaveClock(
                accumulatedWaveTime: accumulatedWaveTime,
                waveAnimationStart: waveAnimationStart,
                isAnimating: renderingPolicy.animatesSurface
            ),
            renderingPolicy: renderingPolicy
        )
        .frame(width: sphereSize, height: sphereSize)
        .onAppear(perform: handleAppear)
        .onChange(of: renderingPolicy.animatesSurface) { _, newValue in
            handleAnimationStateChange(isAnimating: newValue)
        }
        .onChange(of: renderState) { oldValue, newValue in
            handleRenderStateChange(from: oldValue, to: newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private var renderingPolicy: BubbleRenderingPolicy {
        BubbleRenderingPolicy(
            isAnimating: renderState.isAnimating,
            reduceMotion: reduceMotion,
            lowPowerModeEnabled: isLowPowerModeEnabled
        )
    }

    private func handleAppear() {
        previousRenderState = renderState
        morphSourcePhase = renderState.phase
        morphTargetPhase = renderState.phase
        morphProgress = 1
        liquidSourceVisuals = BubbleLiquidVisualState(renderState: renderState, at: .now)
        if renderingPolicy.animatesSurface && waveAnimationStart == nil {
            waveAnimationStart = .now
        }
    }

    private func handleAnimationStateChange(isAnimating: Bool) {
        let now = Date.now
        if isAnimating {
            waveAnimationStart = now
        } else if let waveAnimationStart {
            accumulatedWaveTime += now.timeIntervalSince(waveAnimationStart)
            self.waveAnimationStart = nil
        }
    }

    private func handleRenderStateChange(from oldValue: BubbleRenderState, to newValue: BubbleRenderState) {
        defer {
            previousRenderState = newValue
        }

        guard oldValue.phase != newValue.phase else { return }

        let now = Date.now
        let oldTargetVisuals = BubbleLiquidVisualState(renderState: oldValue, at: now)
        liquidSourceVisuals = BubbleLiquidVisualState.interpolated(
            from: liquidSourceVisuals,
            to: oldTargetVisuals,
            progress: morphProgress
        )
        // The wave clock keeps running through a phase change, so the surface carries on
        // moving instead of snapping back to its starting shape.

        if reduceMotion {
            morphSourcePhase = newValue.phase
            morphTargetPhase = newValue.phase
            morphProgress = 1
            liquidSourceVisuals = BubbleLiquidVisualState(renderState: newValue, at: now)
            return
        }

        morphSourcePhase = morphTargetPhase
        morphTargetPhase = newValue.phase
        morphProgress = 0

        withAnimation(FocusScreenLayout.phaseMorphAnimation) {
            morphProgress = 1
        }
    }
}

/// The whole vessel at one point of the phase morph. SwiftUI animates `morphProgress` and
/// redraws every layer for each frame, so the outline, glass wall, glow, liquid, and shadow
/// change shape together. When only the outline shape was animatable, layers that cannot
/// interpolate (the glass wall, the liquid canvas, the phase colors) jumped to the next
/// phase on the first frame and the outline caught up with them afterwards.
private struct BubbleVesselLayers: View, Animatable {
    let renderState: BubbleRenderState
    let sourcePhase: SessionPhase
    let targetPhase: SessionPhase
    var morphProgress: CGFloat
    let liquidSourceVisuals: BubbleLiquidVisualState
    let waveClock: BubbleWaveClock
    let renderingPolicy: BubbleRenderingPolicy

    var animatableData: CGFloat {
        get { morphProgress }
        set { morphProgress = newValue }
    }

    var body: some View {
        let sphereSize = FocusScreenLayout.bubbleDiameter
        let phaseMorph = BubblePhaseMorph(
            sourcePhase: sourcePhase,
            targetPhase: targetPhase,
            progress: morphProgress
        )
        let driver = BubbleLiquidDriver(
            renderState: renderState,
            waveClock: waveClock,
            phaseMorph: phaseMorph,
            liquidSourceVisuals: liquidSourceVisuals,
            renderingPolicy: renderingPolicy
        )

        ZStack {
            BubbleGroundLayer(driver: driver)
            BubbleGlassBackdrop(phaseMorph: phaseMorph, sphereSize: sphereSize)
            BubbleGlowBackdrop(
                phaseMorph: phaseMorph,
                glowExpansion: 0.60,
                stepBoundaryCueProgress: 0
            )
            BubbleAnimatedSurfaceLayer(driver: driver)
            BubbleVesselWall(phaseMorph: phaseMorph)
            BubbleGlassRimOverlay(phaseMorph: phaseMorph, sphereSize: sphereSize)
            BubbleForegroundContent(renderState: renderState, driver: driver)
        }
    }
}

/// The liquid at one moment: how full, and how the surface moves.
struct BubbleLiquidFrame {
    let fillRatio: Double
    let wavePhase: Double
    let amplitude: Double
    let boundaryCue: Double
}

/// Computes the liquid for any moment. The liquid, its caustic, and the line that splits
/// the digits all read from here, so they stay on the same wave.
struct BubbleLiquidDriver {
    let renderState: BubbleRenderState
    let waveClock: BubbleWaveClock
    let phaseMorph: BubblePhaseMorph
    let liquidSourceVisuals: BubbleLiquidVisualState
    let renderingPolicy: BubbleRenderingPolicy

    func frame(at date: Date) -> BubbleLiquidFrame {
        let wavePhase = waveClock.phase(at: date)
        let glowExpansion = 0.44 + (sin(wavePhase * 0.42) + 1) * 0.16
        let visuals = BubbleLiquidVisualState.interpolated(
            from: liquidSourceVisuals,
            to: BubbleLiquidVisualState(renderState: renderState, at: date),
            progress: phaseMorph.clampedProgress
        )
        let profile = phaseMorph.shellProfile(for: FocusScreenLayout.bubbleDiameter)
        let boundaryCue = max(0, min(visuals.stepBoundaryCueProgress, 1))

        return BubbleLiquidFrame(
            fillRatio: max(0, min(visuals.fillRatio, 1.08)),
            wavePhase: wavePhase,
            amplitude: (profile.waveAmplitudeBase + glowExpansion * profile.waveAmplitudeRange) * (1 - boundaryCue * 0.08),
            boundaryCue: boundaryCue
        )
    }
}

/// Redraws on the liquid's animation schedule while the surface moves, otherwise once.
struct BubbleLiquidTimeline<Content: View>: View {
    let driver: BubbleLiquidDriver
    @ViewBuilder let content: (BubbleLiquidFrame) -> Content

    var body: some View {
        if driver.renderingPolicy.animatesSurface {
            TimelineView(.periodic(from: .now, by: driver.renderState.animationRefreshInterval)) { context in
                content(driver.frame(at: context.date))
            }
        } else {
            content(driver.frame(at: .now))
        }
    }
}

struct BubblePhaseMorph: Equatable {
    let sourcePhase: SessionPhase
    let targetPhase: SessionPhase
    let progress: CGFloat

    var clampedProgress: CGFloat {
        max(0, min(progress, 1))
    }

    var shape: BubbleGlassShape {
        BubbleGlassShape(
            sourcePhase: sourcePhase,
            targetPhase: targetPhase,
            progress: clampedProgress
        )
    }

    /// Phase colors follow the morph, so the tint shifts with the outline instead of
    /// switching halfway through it.
    var tint: Color { blended { $0.tintColor } }
    var shadow: Color { blended { $0.shadowColor } }
    var glassTint: Color { blended { $0.glassTint } }

    func blended(_ color: (SessionPhase) -> Color) -> Color {
        let progress = clampedProgress
        if sourcePhase == targetPhase || progress >= 1 {
            return color(targetPhase)
        }
        if progress <= 0 {
            return color(sourcePhase)
        }
        return color(sourcePhase).mix(with: color(targetPhase), by: Double(progress))
    }

    func blendedValue(_ value: (SessionPhase) -> Double) -> Double {
        interpolate(value(sourcePhase), value(targetPhase), clampedProgress)
    }

    func shellProfile(for sphereSize: CGFloat) -> BubbleShellProfile {
        BubbleShellProfile.interpolated(
            from: sourcePhase.bubbleShellProfile(for: sphereSize),
            to: targetPhase.bubbleShellProfile(for: sphereSize),
            progress: clampedProgress
        )
    }
}

struct BubbleLiquidVisualState: Equatable {
    let fillRatio: Double
    let stepBoundaryCueProgress: Double

    init(fillRatio: Double = 0.12, stepBoundaryCueProgress: Double = 0) {
        self.fillRatio = fillRatio
        self.stepBoundaryCueProgress = stepBoundaryCueProgress
    }

    init(renderState: BubbleRenderState, at date: Date) {
        let normalizedProgress = max(0, min(renderState.progress(at: date), 1))
        let preCompletionFillRatio = min(0.94, 0.12 + pow(normalizedProgress, 1.28) * 0.82)
        let remainingDuration = renderState.remainingDuration(at: date)
        let clampedRemainingDuration = remainingDuration.isFinite ? max(0, remainingDuration) : 0
        let finalFillWindow: TimeInterval = 2
        let finalFillProgress = max(0, min(1, 1 - clampedRemainingDuration / finalFillWindow))
        let easedFinalFillProgress = finalFillProgress * finalFillProgress * (3 - (2 * finalFillProgress))

        fillRatio = interpolate(preCompletionFillRatio, 1.08, easedFinalFillProgress)
        stepBoundaryCueProgress = renderState.stepBoundaryCueProgress(at: date)
    }

    static func interpolated(
        from source: BubbleLiquidVisualState,
        to target: BubbleLiquidVisualState,
        progress: CGFloat
    ) -> BubbleLiquidVisualState {
        BubbleLiquidVisualState(
            fillRatio: interpolate(source.fillRatio, target.fillRatio, progress),
            stepBoundaryCueProgress: interpolate(
                source.stepBoundaryCueProgress,
                target.stepBoundaryCueProgress,
                progress
            )
        )
    }
}

struct BubbleWaveClock {
    let accumulatedWaveTime: TimeInterval
    let waveAnimationStart: Date?
    let isAnimating: Bool

    func phase(at now: Date) -> Double {
        let animatedDuration: TimeInterval
        if isAnimating, let waveAnimationStart {
            animatedDuration = now.timeIntervalSince(waveAnimationStart)
        } else {
            animatedDuration = 0
        }

        return (accumulatedWaveTime + animatedDuration) * 0.44 * .pi
    }
}
