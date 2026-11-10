import SwiftUI

struct BubbleGlowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    let phaseMorph: BubblePhaseMorph
    let glowExpansion: Double
    let stepBoundaryCueProgress: Double

    var body: some View {
        let glow = glowExpansion.isFinite ? max(0, glowExpansion) : 0
        let cue = stepBoundaryCueProgress.isFinite ? max(0, min(stepBoundaryCueProgress, 1)) : 0
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
                    phaseMorph.shadow.opacity(
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
                            phaseMorph.shadow.opacity(
                                clampedOpacity(
                                    colorScheme == .dark
                                        ? 0.07 + glow * 0.04 + cue * 0.035
                                        : 0.06 + glow * 0.03 + cue * 0.020
                                )
                            ),
                            phaseMorph.shadow.opacity(
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

/// The arguments for `bubbleLiquid` in FocusBubbleLiquid.metal, which shades the liquid per pixel
/// over the layer that holds the countdown. The tint deepens with the light's path through the
/// liquid, the digits below the surface are refracted, the surface mirrors the light and glints
/// with the waves, and faint caustic threads drift low on the side away from the light.
enum BubbleLiquidShader {
    /// How far from a pixel the shader samples the digits when it refracts them.
    static let maxSampleOffset = CGSize(width: 16, height: 8)

    /// Rows and columns across the inside of the glass, about 2.5 pt apart.
    private static let crossSectionCount = 96
    /// The glass behind the liquid, measured from the rendered bubble. The glass is not part of the
    /// shaded layer, so the shader uses these to tint it.
    private static let darkBackdrop = Color(red: 0.150, green: 0.155, blue: 0.168)
    private static let lightBackdrop = Color(red: 0.964, green: 0.968, blue: 0.976)

    static func shader(
        phaseMorph: BubblePhaseMorph,
        frame: BubbleLiquidFrame,
        renderingPolicy: BubbleRenderingPolicy,
        isDark: Bool
    ) -> Shader {
        let size = FocusScreenLayout.bubbleDiameter
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let innerOutline = BubbleVessel.polygon(
            of: BubbleVessel.innerPath(of: phaseMorph.shape.path(in: rect), in: rect),
            curveSteps: 16
        )
        let surface = BubbleVessel.surface(
            in: rect,
            innerOutline: innerOutline,
            fillRatio: frame.fillRatio,
            reach: frame.amplitude
        )
        let sections = BubbleVessel.crossSections(of: innerOutline, count: crossSectionCount)
        let glow = isDark ? phaseMorph.tint.mix(with: .white, by: 0.45) : Color.white
        // The paler break colors absorb little light, so they need a denser liquid than amber to
        // read as color rather than gray.
        let density = phaseMorph.blendedValue { $0 == .focus ? 1 : (isDark ? 1.8 : 1.45) }

        return ShaderLibrary.bubbleLiquid(
            .float2(Float(size), Float(size)),
            .float4(
                Float(BubbleWave.waterlineY(fillRatio: frame.fillRatio, in: rect)),
                Float(surface?.centerX ?? rect.midX),
                Float(surface?.radius ?? 0),
                Float(surface?.depth ?? 0)
            ),
            .float4(
                Float(frame.amplitude),
                Float(frame.wavePhase),
                Float(frame.wavePhase * 1.08 + .pi / 5),
                Float(frame.wavePhase)
            ),
            .color(phaseMorph.tint),
            .color(phaseMorph.shadow),
            .color(glow),
            .color(isDark ? darkBackdrop : lightBackdrop),
            .float4(
                isDark ? 1 : 0,
                Float(density),
                Float(frame.fillRatio),
                renderingPolicy.rendersCaustic ? 1 : 0
            ),
            .float(Float(frame.boundaryCue)),
            .float4(
                Float(sections.bounds.minY),
                Float(sections.bounds.maxY),
                Float(sections.bounds.minX),
                Float(sections.bounds.maxX)
            ),
            .floatArray(sections.values)
        )
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
                    BubbleCaustic(tint: driver.phaseMorph.tint, bounds: bounds, frame: frame, isDark: isDark)
                }
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The light the liquid gathers onto the page, inside the shadow to the lower right. It takes
/// the liquid's tint and has no hard core, so on a dark page it reads as warm light in the
/// shadow rather than a highlight. It brightens as the vessel fills.
private struct BubbleCaustic: View {
    let tint: Color
    let bounds: CGRect
    let frame: BubbleLiquidFrame
    let isDark: Bool

    var body: some View {
        let size = FocusScreenLayout.bubbleDiameter
        let liquid = max(0.2, min(frame.fillRatio, 1))
        // The gathered light drifts and breathes with the surface above it.
        let drift = CGFloat(sin(frame.wavePhase * 0.9))
        let breath = 0.88 + 0.12 * sin(frame.wavePhase * 1.3 + 0.8)
        let center = CGPoint(x: bounds.midX + size * 0.10 + drift * 2.5, y: bounds.maxY + 5)

        ZStack {
            Ellipse()
                .fill(tint.opacity((isDark ? 0.30 : 0.34) * liquid))
                .frame(width: bounds.width * 0.50, height: 16)
                .blur(radius: 9)
                .position(center)

            Ellipse()
                .fill(tint.opacity((isDark ? 0.26 : 0.30) * liquid * breath))
                .frame(width: bounds.width * 0.26, height: 6)
                .blur(radius: 4)
                .position(x: center.x + drift * 2, y: center.y - 1)
        }
    }
}
