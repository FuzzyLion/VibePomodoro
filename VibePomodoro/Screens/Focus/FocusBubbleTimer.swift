import Foundation
import SwiftUI

struct BubbleTimerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let renderState: BubbleRenderState

    @State private var accumulatedWaveTime: TimeInterval = 0
    @State private var waveAnimationStart: Date?
    @State private var morphSourcePhase: SessionPhase = .focus
    @State private var morphTargetPhase: SessionPhase = .focus
    /// Whether the morph is heading to the summary of a finished session.
    @State private var morphTargetShowsSummary = false
    @State private var morphProgress: CGFloat = 1
    @State private var previousRenderState: BubbleRenderState?
    @State private var liquidSourceVisuals = BubbleLiquidVisualState()
    /// Keeps the surface moving while the liquid settles at a session's end or drains after it.
    @State private var isSettling = false
    @State private var settleTask: Task<Void, Never>?
    @State private var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        let sphereSize = FocusScreenLayout.bubbleDiameter
        // Until `onChange` starts the morph, a new phase or the end of a session is drawn as the
        // first frame of the morph from the previous state.
        let isPendingTransition = previousRenderState != nil
            && (renderState.phase != morphTargetPhase || (renderState.summary != nil) != morphTargetShowsSummary)

        BubbleVesselLayers(
            renderState: renderState,
            sourcePhase: isPendingTransition ? morphTargetPhase : morphSourcePhase,
            targetPhase: isPendingTransition ? renderState.phase : morphTargetPhase,
            morphProgress: isPendingTransition ? 0 : morphProgress,
            liquidSourceVisuals: isPendingTransition
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
        // The first frame of a transition is drawn at its start even when the change that caused
        // it carries an animation: interpolating it would show the end state for a moment before
        // the morph from `onChange` begins.
        .transaction { transaction in
            if isPendingTransition {
                transaction.animation = nil
            }
        }
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
        .onDisappear {
            settleTask?.cancel()
            settleTask = nil
            isSettling = false
        }
    }

    private var renderingPolicy: BubbleRenderingPolicy {
        BubbleRenderingPolicy(
            isAnimating: renderState.isAnimating || isSettling,
            reduceMotion: reduceMotion,
            lowPowerModeEnabled: isLowPowerModeEnabled
        )
    }

    private func handleAppear() {
        previousRenderState = renderState
        morphSourcePhase = renderState.phase
        morphTargetPhase = renderState.phase
        morphTargetShowsSummary = renderState.summary != nil
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

        let summaryChanged = (oldValue.summary == nil) != (newValue.summary == nil)
        guard oldValue.phase != newValue.phase || summaryChanged else { return }

        let now = Date.now
        let oldTargetVisuals = BubbleLiquidVisualState(renderState: oldValue, at: now)
        liquidSourceVisuals = BubbleLiquidVisualState.interpolated(
            from: liquidSourceVisuals,
            to: oldTargetVisuals,
            progress: morphProgress
        )
        morphTargetShowsSummary = newValue.summary != nil
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

        var animation = FocusScreenLayout.phaseMorphAnimation
        if summaryChanged {
            // When a session ends the liquid settles below the rim; Done drains it into the
            // next session. Either way the surface moves until the liquid comes to rest.
            let isEnding = newValue.summary != nil
            animation = isEnding ? FocusCompletionMotion.settle : FocusCompletionMotion.drain
            keepSurfaceMoving(for: isEnding ? FocusCompletionMotion.settleDuration : FocusCompletionMotion.drainDuration)
        }

        withAnimation(animation) {
            morphProgress = 1
        }
    }

    private func keepSurfaceMoving(for duration: TimeInterval) {
        settleTask?.cancel()
        isSettling = true
        settleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            isSettling = false
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
            BubbleLiquidContent(renderState: renderState, driver: driver)
            BubbleVesselWall(phaseMorph: phaseMorph)
            BubbleGlassRimOverlay(phaseMorph: phaseMorph, sphereSize: sphereSize)
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
            amplitude: (profile.waveAmplitudeBase + glowExpansion * profile.waveAmplitudeRange)
                * (1 - boundaryCue * 0.08)
                * (1 - max(0, min(visuals.surfaceCalm, 1)) * 0.85),
            boundaryCue: boundaryCue
        )
    }
}

/// Redraws on the liquid's animation schedule while the surface moves. The timeline stays in
/// place when the surface stops, so the views inside keep their identity and can animate from
/// one state to the next; a still surface is drawn for the current moment.
struct BubbleLiquidTimeline<Content: View>: View {
    let driver: BubbleLiquidDriver
    @ViewBuilder let content: (BubbleLiquidFrame) -> Content

    var body: some View {
        let animates = driver.renderingPolicy.animatesSurface

        TimelineView(
            .animation(minimumInterval: BubbleRenderState.visibleAnimationRefreshInterval, paused: !animates)
        ) { context in
            content(driver.frame(at: animates ? context.date : .now))
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
    /// Where the liquid rests once a session that met its planned focus time has ended: just
    /// below the rim, so its surface still shows.
    static let fullRestingFillRatio = 0.86

    let fillRatio: Double
    let stepBoundaryCueProgress: Double
    /// How still the surface is, from 0 for the regular waves to 1 for an all but flat surface.
    let surfaceCalm: Double

    init(fillRatio: Double = 0.12, stepBoundaryCueProgress: Double = 0, surfaceCalm: Double = 0) {
        self.fillRatio = fillRatio
        self.stepBoundaryCueProgress = stepBoundaryCueProgress
        self.surfaceCalm = surfaceCalm
    }

    init(renderState: BubbleRenderState, at date: Date) {
        if let summary = renderState.summary {
            fillRatio = Self.restingFillRatio(forFocusShare: summary.focusShare)
            stepBoundaryCueProgress = 0
            surfaceCalm = 1
            return
        }

        let normalizedProgress = max(0, min(renderState.progress(at: date), 1))
        let preCompletionFillRatio = min(0.94, 0.12 + pow(normalizedProgress, 1.28) * 0.82)
        let remainingDuration = renderState.remainingDuration(at: date)
        let clampedRemainingDuration = remainingDuration.isFinite ? max(0, remainingDuration) : 0
        let finalFillWindow: TimeInterval = 2
        let finalFillProgress = max(0, min(1, 1 - clampedRemainingDuration / finalFillWindow))
        let easedFinalFillProgress = finalFillProgress * finalFillProgress * (3 - (2 * finalFillProgress))

        fillRatio = interpolate(preCompletionFillRatio, 1.08, easedFinalFillProgress)
        stepBoundaryCueProgress = renderState.stepBoundaryCueProgress(at: date)
        surfaceCalm = 0
    }

    /// A finished session's vessel holds its focus time: as full as the session's focus time
    /// came to its plan, on the curve the liquid rises along while a step runs.
    static func restingFillRatio(forFocusShare share: Double) -> Double {
        let clampedShare = share.isFinite ? min(1, max(0, share)) : 0
        return 0.12 + pow(clampedShare, 1.28) * (fullRestingFillRatio - 0.12)
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
            ),
            surfaceCalm: interpolate(source.surfaceCalm, target.surfaceCalm, progress)
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
