import SwiftUI

struct BubbleAnimatedSurfaceLayer: View {
    let driver: BubbleLiquidDriver

    var body: some View {
        BubbleLiquidTimeline(driver: driver) { frame in
            BubbleLiquidLayer(
                phaseMorph: driver.phaseMorph,
                frame: frame,
                renderingPolicy: driver.renderingPolicy
            )
        }
        // The liquid stays inside the glass wall instead of reaching the outer edge.
        .mask { driver.phaseMorph.shape.scale(BubbleVessel.innerScale) }
        .allowsHitTesting(false)
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
                                // In light mode this soft ring is what separates the glass from the page.
                                : 0.085 + glow * 0.010 + cue * 0.006
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
    let frame: BubbleLiquidFrame
    let renderingPolicy: BubbleRenderingPolicy

    private var phase: SessionPhase {
        phaseMorph.visualPhase
    }

    var body: some View {
        let phase = phaseMorph.visualPhase
        let profile = phaseMorph.shellProfile(for: FocusScreenLayout.bubbleDiameter)
        let boundaryCue = frame.boundaryCue
        let visualFillRatio = frame.fillRatio
        let amplitude = frame.amplitude
        let wavePhase = frame.wavePhase
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

            drawSurface(in: &context, rect: sphereRect, fillRatio: visualFillRatio, amplitude: amplitude, wavePhase: wavePhase, boundaryCue: boundaryCue)
        }
    }

    /// The liquid's top surface. Its far edge catches the light; its near edge is the water line.
    private func drawSurface(
        in context: inout GraphicsContext,
        rect: CGRect,
        fillRatio: Double,
        amplitude: Double,
        wavePhase: Double,
        boundaryCue: Double
    ) {
        let innerOutline = BubbleVessel.polygon(of: BubbleVessel.innerPath(of: phaseMorph.shape.path(in: rect), in: rect))
        guard let surface = BubbleVessel.surface(
            in: rect,
            innerOutline: innerOutline,
            fillRatio: fillRatio,
            amplitude: amplitude,
            phase: wavePhase
        ) else {
            return
        }

        let isDark = colorScheme == .dark
        let bounds = surface.shape.boundingRect
        let edgeFade = 1 - boundaryCue * 0.2

        context.fill(
            surface.shape,
            with: .linearGradient(
                Gradient(colors: isDark
                    ? [Color.white.opacity(0.16), phase.tintColor.opacity(0.24), phase.tintColor.opacity(0.32)]
                    : [Color.white.opacity(0.80), phase.tintColor.opacity(0.24), phase.tintColor.opacity(0.34)]),
                startPoint: CGPoint(x: bounds.minX, y: bounds.minY),
                endPoint: CGPoint(x: bounds.maxX, y: bounds.maxY)
            )
        )

        var farEdgeGlow = context
        farEdgeGlow.addFilter(.blur(radius: 1.2))
        farEdgeGlow.stroke(
            surface.farEdge,
            with: .color(Color.white.opacity((isDark ? 0.50 : 0.95) * edgeFade)),
            lineWidth: 1.8
        )
        context.stroke(
            surface.farEdge,
            with: .color(isDark ? Color.white.opacity(0.32 * edgeFade) : phase.shadowColor.opacity(0.32 * edgeFade)),
            lineWidth: 0.7
        )
        context.stroke(
            surface.nearEdge,
            with: .color(isDark ? phase.tintColor.opacity(0.60 * edgeFade) : phase.shadowColor.opacity(0.42 * edgeFade)),
            lineWidth: 1.0
        )
    }

    private var secondaryLiquidGradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color.white.opacity(0.09),
                Color.white.opacity(0.03),
                Color.clear
            ]
        }

        // A tinted second layer, so both wave layers stay readable against white glass.
        return [
            phase.tintColor.opacity(0.20),
            phase.tintColor.opacity(0.08),
            Color.clear
        ]
    }

    /// In light mode the liquid is tinted from the surface down, like the dark liquid,
    /// so the fill level reads at a glance instead of fading in from white.
    private var liquidGradientColors: [Color] {
        guard colorScheme == .light else { return phase.liquidGradientColors }

        switch phase {
        case .focus:
            return [
                VibePalette.amberGold.opacity(0.17),
                VibePalette.amberGold.opacity(0.21),
                VibePalette.amberGoldDeep.opacity(0.27)
            ]
        case .shortBreak:
            return [
                VibePalette.softMist.opacity(0.30),
                VibePalette.softMist.opacity(0.34),
                VibePalette.softMistDeep.opacity(0.32)
            ]
        case .longBreak:
            return [
                VibePalette.softJade.opacity(0.28),
                VibePalette.softJade.opacity(0.32),
                VibePalette.softJadeDeep.opacity(0.32)
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

        let baseY = BubbleWave.waterlineY(fillRatio: fillRatio, in: rect)
        let step = max(CGFloat(5.5), rect.width / 34)
        let startX = -step
        let endX = rect.width + step

        var path = Path()
        path.move(to: CGPoint(x: startX, y: rect.height))
        path.addLine(to: CGPoint(x: startX, y: baseY))

        var x = startX
        while x <= endX {
            let wave = BubbleWave.offset(atX: x, width: rect.width, height: rect.height, amplitude: amplitude, phase: phase)
            path.addLine(to: CGPoint(x: x, y: baseY + wave))
            x += step
        }

        path.addLine(to: CGPoint(x: endX, y: rect.height))
        path.closeSubpath()
        return path
    }
}

/// What the vessel casts on the page: a soft shadow, a contact shadow where the glass meets
/// the surface, and a caustic, the light the liquid focuses, which brightens as it fills.
struct BubbleGroundLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    let driver: BubbleLiquidDriver

    var body: some View {
        let isDark = colorScheme == .dark
        let size = FocusScreenLayout.bubbleDiameter
        let bounds = driver.phaseMorph.shape.path(in: CGRect(x: 0, y: 0, width: size, height: size)).boundingRect

        ZStack {
            Ellipse()
                .fill(Color.black.opacity(isDark ? 0.50 : 0.12))
                .frame(width: bounds.width * 0.86, height: 22)
                .blur(radius: isDark ? 11 : 9)
                .position(x: bounds.midX + size * 0.06, y: bounds.maxY + 2)

            Ellipse()
                .fill(Color.black.opacity(isDark ? 0.65 : 0.22))
                .frame(width: bounds.width * 0.52, height: 8)
                .blur(radius: 3.5)
                .position(x: bounds.midX + size * 0.02, y: bounds.maxY - 1)

            if driver.renderingPolicy.rendersCaustic {
                BubbleLiquidTimeline(driver: driver) { frame in
                    BubbleCaustic(phase: driver.phaseMorph.visualPhase, bounds: bounds, frame: frame, isDark: isDark)
                }
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct BubbleCaustic: View {
    let phase: SessionPhase
    let bounds: CGRect
    let frame: BubbleLiquidFrame
    let isDark: Bool

    var body: some View {
        let size = FocusScreenLayout.bubbleDiameter
        let liquid = CGFloat(max(0.2, min(frame.fillRatio, 1)))
        // The focused light drifts and breathes with the surface above it.
        let drift = CGFloat(sin(frame.wavePhase * 0.9))
        let breath = 0.86 + 0.14 * CGFloat(sin(frame.wavePhase * 1.3 + 0.8))

        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            phase.tintColor.opacity((isDark ? 0.75 : 0.70) * liquid),
                            phase.tintColor.opacity((isDark ? 0.25 : 0.30) * liquid),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: bounds.width * 0.22
                    )
                )
                .frame(width: bounds.width * 0.46, height: 10)
                .blur(radius: 3)
                .position(x: bounds.midX + size * 0.11 + drift * 2, y: bounds.maxY + 4)
                .blendMode(isDark ? .plusLighter : .normal)

            Capsule()
                .fill(isDark ? Color.white.opacity(0.55 * liquid) : phase.tintColor.opacity(0.85 * liquid))
                .frame(width: bounds.width * 0.20, height: 2.2)
                .blur(radius: 1.2)
                .opacity(breath)
                .position(x: bounds.midX + size * 0.12 + drift * 4, y: bounds.maxY + 4)
                .blendMode(isDark ? .plusLighter : .normal)
        }
    }
}
