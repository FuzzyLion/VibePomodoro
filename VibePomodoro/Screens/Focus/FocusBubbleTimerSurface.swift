import SwiftUI

struct BubbleAnimatedSurfaceLayer: View {
    let renderState: BubbleRenderState
    let waveClock: BubbleWaveClock
    let phaseMorph: BubblePhaseMorph
    let liquidSourceVisuals: BubbleLiquidVisualState
    let renderingPolicy: BubbleRenderingPolicy

    var body: some View {
        Group {
            if renderingPolicy.animatesSurface {
                TimelineView(.periodic(from: .now, by: renderState.animationRefreshInterval)) { context in
                    animatedSurface(at: context.date)
                }
            } else {
                animatedSurface(at: .now)
            }
        }
        .mask(phaseMorph.shape)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func animatedSurface(at date: Date) -> some View {
        let wavePhase = waveClock.phase(at: date)
        let glowExpansion = 0.44 + (sin(wavePhase * 0.42) + 1) * 0.16
        let targetLiquidVisuals = BubbleLiquidVisualState(renderState: renderState, at: date)
        let liquidVisuals = BubbleLiquidVisualState.interpolated(
            from: liquidSourceVisuals,
            to: targetLiquidVisuals,
            progress: phaseMorph.clampedProgress
        )

        BubbleLiquidLayer(
            phaseMorph: phaseMorph,
            visuals: liquidVisuals,
            wavePhase: wavePhase,
            glowExpansion: glowExpansion,
            renderingPolicy: renderingPolicy
        )
    }
}

struct BubbleGlowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    let phaseMorph: BubblePhaseMorph
    let glowExpansion: Double
    let stepBoundaryCueProgress: Double

    var body: some View {
        let glow = glowExpansion.isFinite ? max(0, glowExpansion) : 0
        let cue = stepBoundaryCueProgress.isFinite ? max(0, min(stepBoundaryCueProgress, 1)) : 0
        let phase = phaseMorph.visualPhase
        let bubbleShape = phaseMorph.shape
        let profile = phaseMorph.shellProfile(for: FocusScreenLayout.bubbleDiameter)
        let gatheredGlowWidth = profile.outerGlowSize.width * (1 - cue * 0.16)
        let gatheredGlowHeight = profile.outerGlowSize.height * (1 - cue * 0.10)
        let gatheredGlowOffset = CGSize(
            width: profile.outerGlowOffset.width * (1 - cue * 0.24),
            height: profile.outerGlowOffset.height - CGFloat(cue * 4.5)
        )

        ZStack {
            bubbleShape
                .stroke(
                    phase.shadowColor.opacity(
                        clampedOpacity(
                            colorScheme == .dark
                                ? 0.034 + glow * 0.008 + cue * 0.008
                                : 0.015 + glow * 0.004 + cue * 0.004
                        )
                    ),
                    lineWidth: colorScheme == .dark ? 10.5 : 8.5
                )
                .blur(radius: colorScheme == .dark ? 6.2 - cue * 0.8 : 4.8 - cue * 0.5)
                .scaleEffect(colorScheme == .dark ? 1.018 : 1.014)

            bubbleShape
                .stroke(
                    Color.white.opacity(
                        clampedOpacity(
                            colorScheme == .dark
                                ? 0.015 + glow * 0.002 - cue * 0.002
                                : 0.015 + glow * 0.003 - cue * 0.002
                        )
                    ),
                    lineWidth: colorScheme == .dark ? 3.8 : 3.0
                )
                .blur(radius: colorScheme == .dark ? 2.8 - cue * 0.4 : 3.0 - cue * 0.4)
                .scaleEffect(colorScheme == .dark ? 1.009 : 1.007)
                .offset(y: colorScheme == .dark ? -0.6 : -1.2)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            phase.shadowColor.opacity(
                                clampedOpacity(
                                    colorScheme == .dark
                                        ? 0.07 + glow * 0.04 + cue * 0.035
                                        : 0.06 + glow * 0.03 + cue * 0.020
                                )
                            ),
                            phase.shadowColor.opacity(
                                clampedOpacity(
                                    colorScheme == .dark
                                        ? 0.022 + glow * 0.014 + cue * 0.012
                                        : 0.018 + glow * 0.011 + cue * 0.008
                                )
                            ),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: gatheredGlowWidth * 0.62 + glow * (16 - cue * 3)
                    )
                )
                .frame(
                    width: gatheredGlowWidth + glow * (18 - cue * 4),
                    height: gatheredGlowHeight + glow * (6 - cue * 1.2)
                )
                .blur(radius: colorScheme == .dark ? 15 + glow * 4 - cue * 2 : 13 + glow * 3 - cue * 1.5)
                .offset(gatheredGlowOffset)

            Ellipse()
                .fill(
                    Color.white.opacity(
                        clampedOpacity(
                            colorScheme == .dark
                                ? 0.045 + glow * 0.015 + cue * 0.010
                                : 0.028 + glow * 0.010 + cue * 0.007
                        )
                    )
                )
                .frame(
                    width: gatheredGlowWidth * 0.74 + glow * (8 - cue * 2),
                    height: gatheredGlowHeight * 0.42 + glow * (2 - cue * 0.5)
                )
                .blur(radius: colorScheme == .dark ? 8 - cue * 1.2 : 7 - cue)
                .offset(x: gatheredGlowOffset.width, y: gatheredGlowOffset.height - 8 + cue * 1.5)
        }
    }

    private func clampedOpacity(_ value: Double) -> Double {
        min(1, max(0, value.isFinite ? value : 0))
    }
}

private struct BubbleLiquidLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    let phaseMorph: BubblePhaseMorph
    let visuals: BubbleLiquidVisualState
    let wavePhase: Double
    let glowExpansion: Double
    let renderingPolicy: BubbleRenderingPolicy

    private var phase: SessionPhase {
        phaseMorph.visualPhase
    }

    var body: some View {
        let phase = phaseMorph.visualPhase
        let profile = phaseMorph.shellProfile(for: FocusScreenLayout.bubbleDiameter)
        let boundaryCue = max(0, min(visuals.stepBoundaryCueProgress, 1))
        let visualFillRatio = max(0, min(visuals.fillRatio, 1.08))
        let amplitude = (profile.waveAmplitudeBase + glowExpansion * profile.waveAmplitudeRange) * (1 - boundaryCue * 0.08)
        let gatheredDepthPoolSize = CGSize(
            width: profile.depthPoolSize.width * (1 - boundaryCue * 0.12),
            height: profile.depthPoolSize.height * (1 - boundaryCue * 0.18)
        )
        let gatheredDepthPoolOffset = CGSize(
            width: profile.depthPoolOffset.width * (1 - boundaryCue * 0.22),
            height: profile.depthPoolOffset.height + FocusScreenLayout.bubbleDiameter * boundaryCue * 0.014
        )

        Canvas(rendersAsynchronously: true) { context, canvasSize in
            guard canvasSize.width.isFinite,
                  canvasSize.height.isFinite,
                  canvasSize.width > 0,
                  canvasSize.height > 0 else {
                return
            }

            let sphereRect = CGRect(origin: .zero, size: canvasSize)
            let waterlineY = sphereRect.maxY - sphereRect.height * CGFloat(visualFillRatio)

            guard waterlineY.isFinite else { return }

            let liquidPath = WaveLiquidShape(
                fillRatio: visualFillRatio,
                phase: wavePhase,
                amplitude: amplitude
            ).path(in: sphereRect)

            context.fill(
                liquidPath,
                with: .linearGradient(
                    Gradient(colors: liquidGradientColors),
                    startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 18),
                    endPoint: CGPoint(x: sphereRect.midX, y: sphereRect.maxY)
                )
            )

            context.fill(
                liquidPath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.clear,
                        phase.shadowColor.opacity(colorScheme == .dark ? 0.18 : 0.10)
                    ]),
                    startPoint: CGPoint(x: sphereRect.midX, y: waterlineY + 8),
                    endPoint: CGPoint(x: sphereRect.midX, y: sphereRect.maxY)
                )
            )

            let secondaryLiquidPath = WaveLiquidShape(
                fillRatio: min(1.08, visualFillRatio + 0.012),
                phase: wavePhase * 1.08 + .pi / 5,
                amplitude: amplitude * (0.55 - boundaryCue * 0.04)
            ).path(in: sphereRect)

            context.fill(
                secondaryLiquidPath,
                with: .linearGradient(
                    Gradient(colors: secondaryLiquidGradientColors),
                    startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 14),
                    endPoint: CGPoint(x: sphereRect.midX, y: sphereRect.maxY)
                )
            )

            if renderingPolicy.rendersDepthPool {
                var depthPoolContext = context
                depthPoolContext.clip(to: secondaryLiquidPath)
                depthPoolContext.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: sphereRect.midX - (gatheredDepthPoolSize.width / 2) + gatheredDepthPoolOffset.width,
                            y: sphereRect.midY - (gatheredDepthPoolSize.height / 2) + gatheredDepthPoolOffset.height,
                            width: gatheredDepthPoolSize.width,
                            height: gatheredDepthPoolSize.height
                        )
                    ),
                    with: .radialGradient(
                        Gradient(colors: [
                            phase.shadowColor.opacity(colorScheme == .dark ? 0.34 + boundaryCue * 0.08 : 0.18 + boundaryCue * 0.05),
                            phase.tintColor.opacity(colorScheme == .dark ? 0.18 + boundaryCue * 0.03 : 0.10 + boundaryCue * 0.02),
                            Color.clear
                        ]),
                        center: CGPoint(
                            x: sphereRect.midX + gatheredDepthPoolOffset.width * 0.08,
                            y: sphereRect.maxY - gatheredDepthPoolSize.height * (0.28 - boundaryCue * 0.05)
                        ),
                        startRadius: 4,
                        endRadius: gatheredDepthPoolSize.width * (0.46 - boundaryCue * 0.06)
                    )
                )
            }

            if colorScheme == .dark {
                var waterlineGlowContext = context
                waterlineGlowContext.addFilter(.blur(radius: 10 - boundaryCue * 1.8))
                waterlineGlowContext.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: sphereRect.minX + sphereRect.width * (0.11 + boundaryCue * 0.03),
                            y: waterlineY - 5 + boundaryCue * 1.4,
                            width: sphereRect.width * (0.78 - boundaryCue * 0.07),
                            height: 12 - boundaryCue * 1.8
                        )
                    ),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.14 - boundaryCue * 0.04),
                            phase.glassTint.opacity(0.05 + boundaryCue * 0.02),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 10),
                        endPoint: CGPoint(x: sphereRect.midX, y: waterlineY + 10)
                    )
                )
            } else {
                var waterlineGlowContext = context
                waterlineGlowContext.addFilter(.blur(radius: 8 - boundaryCue * 1.4))
                waterlineGlowContext.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: sphereRect.minX + sphereRect.width * (0.12 + boundaryCue * 0.03),
                            y: waterlineY - 5 + boundaryCue,
                            width: sphereRect.width * (0.76 - boundaryCue * 0.06),
                            height: 11 - boundaryCue * 1.4
                        )
                    ),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.12 - boundaryCue * 0.035),
                            phase.tintColor.opacity(0.06 - boundaryCue * 0.02),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 9),
                        endPoint: CGPoint(x: sphereRect.midX, y: waterlineY + 9)
                    )
                )
            }
        }
    }

    private var secondaryLiquidGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color.white.opacity(0.09),
                Color.white.opacity(0.03),
                Color.clear
            ]
        }

        return [
            Color.white.opacity(0.14),
            phase.tintColor.opacity(0.12),
            Color.clear
        ]
    }

    private var liquidGradientColors: [Color] {
        guard colorScheme == .light else { return phase.liquidGradientColors }

        switch phase {
        case .focus:
            return [
                Color.white.opacity(0.092),
                Color(red: 0.96, green: 0.92, blue: 0.80).opacity(0.185),
                Color(red: 0.86, green: 0.74, blue: 0.48).opacity(0.265)
            ]
        case .shortBreak:
            return [
                Color.white.opacity(0.086),
                VibePalette.softMist.opacity(0.178),
                VibePalette.softMistDeep.opacity(0.258)
            ]
        case .longBreak:
            return [
                Color.white.opacity(0.096),
                Color(red: 0.84, green: 0.91, blue: 0.89).opacity(0.198),
                Color(red: 0.69, green: 0.82, blue: 0.79).opacity(0.268)
            ]
        }
    }
}

private struct WaveLiquidShape: Shape {
    let fillRatio: Double
    let phase: Double
    let amplitude: Double

    func path(in rect: CGRect) -> Path {
        guard rect.width.isFinite,
              rect.height.isFinite,
              rect.width > 0,
              rect.height > 0,
              fillRatio.isFinite,
              phase.isFinite,
              amplitude.isFinite else {
            return Path()
        }

        let clampedFill = max(0, min(fillRatio, 1.08))
        let baseY = rect.height * (1 - clampedFill)
        let mainAmplitude = min(rect.height * 0.06, amplitude)
        let width = rect.width
        let step = max(CGFloat(5.5), width / 34)
        let startX = -step
        let endX = width + step

        var path = Path()
        path.move(to: CGPoint(x: startX, y: rect.height))
        path.addLine(to: CGPoint(x: startX, y: baseY))

        var x = startX
        while x <= endX {
            let relativeX = x / width
            let primaryAngle = Double(relativeX) * Double.pi * 1.72 + phase
            let secondaryAngle = Double(relativeX) * Double.pi * 3.34 + phase * 0.68
            let wave = CGFloat(sin(primaryAngle)) * mainAmplitude
            let secondaryWave = CGFloat(sin(secondaryAngle)) * mainAmplitude * 0.24
            let y = baseY + wave + secondaryWave
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: endX, y: rect.height))
        path.closeSubpath()
        return path
    }
}
