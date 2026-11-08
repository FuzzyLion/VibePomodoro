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

/// Colors and strengths of the liquid for the current appearance, blended through the phase morph.
private struct BubbleLiquidLook {
    let isDark: Bool
    let tint: Color
    let deep: Color
    /// The light the liquid catches just under its surface and in its caustic threads.
    let glow: Color
    /// The paler break colors need more opacity than amber to read on light glass.
    let density: Double

    init(phaseMorph: BubblePhaseMorph, isDark: Bool) {
        self.isDark = isDark
        tint = phaseMorph.tint
        deep = phaseMorph.shadow
        glow = isDark ? phaseMorph.tint.mix(with: .white, by: 0.45) : .white
        density = isDark ? 1 : phaseMorph.blendedValue { $0 == .focus ? 1 : 1.45 }
    }

    /// Color by depth below the surface, from the light caught under the surface to the deepest
    /// tone. The gradient runs over a fixed depth, so a shallow liquid stays light and only a
    /// full vessel reaches the deepest tone at the bottom.
    var depthStops: [Gradient.Stop] {
        if isDark {
            return [
                .init(color: glow.opacity(0.40), location: 0),
                .init(color: tint.opacity(0.30), location: 0.05),
                .init(color: tint.opacity(0.21), location: 0.18),
                .init(color: deep.opacity(0.34), location: 0.55),
                .init(color: deep.mix(with: .black, by: 0.40).opacity(0.58), location: 1)
            ]
        }
        return [
            .init(color: Color.white.mix(with: tint, by: 0.5).opacity(0.34 * density), location: 0),
            .init(color: tint.opacity(0.27 * density), location: 0.07),
            .init(color: tint.opacity(0.31 * density), location: 0.30),
            .init(color: deep.opacity(0.48 * min(density, 1.2)), location: 1)
        ]
    }

    /// Light refracted through the curved glass, along the wall on the side away from the light.
    var rimLight: Color {
        isDark ? glow.opacity(0.42) : Color.white.opacity(0.75)
    }

    /// The side facing the light and the side away from it.
    var litSide: Color { Color.white.opacity(isDark ? 0.035 : 0.10) }
    var shadedSide: Color { isDark ? Color.black.opacity(0.12) : deep.opacity(0.07) }

    var causticColor: Color { isDark ? glow : .white }
    var causticOpacity: Double { isDark ? 0.17 : 0.32 }
    var causticBlend: GraphicsContext.BlendMode { isDark ? .plusLighter : .normal }

    /// The surface seen from slightly above: its far part mirrors the light, its near part
    /// looks into the liquid.
    var surfaceColors: [Color] {
        isDark
            ? [glow.opacity(0.24), tint.opacity(0.20), tint.opacity(0.26)]
            : [Color.white.opacity(0.78), tint.opacity(0.22 * density), tint.opacity(0.32 * density)]
    }
}

/// The liquid inside the glass wall. It is lighter just under the surface, where the light
/// enters, and deepens with depth; it thins toward the glass and carries faint caustic threads
/// low on the side away from the light. Its surface is a soft ellipse whose edges fade out
/// toward the walls instead of being outlined.
private struct BubbleLiquidLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    let phaseMorph: BubblePhaseMorph
    let frame: BubbleLiquidFrame
    let renderingPolicy: BubbleRenderingPolicy

    var body: some View {
        let look = BubbleLiquidLook(phaseMorph: phaseMorph, isDark: colorScheme == .dark)

        Canvas(rendersAsynchronously: true) { context, canvasSize in
            guard canvasSize.width.isFinite,
                  canvasSize.height.isFinite,
                  canvasSize.width > 0,
                  canvasSize.height > 0 else {
                return
            }

            let rect = CGRect(origin: .zero, size: canvasSize)
            let waterlineY = BubbleWave.waterlineY(fillRatio: frame.fillRatio, in: rect)
            let liquid = WaveLiquidShape(
                fillRatio: frame.fillRatio,
                phase: frame.wavePhase,
                amplitude: frame.amplitude
            ).path(in: rect)
            let innerWall = BubbleVessel.innerPath(of: phaseMorph.shape.path(in: rect), in: rect)

            drawBody(in: &context, rect: rect, liquid: liquid, innerWall: innerWall, waterlineY: waterlineY, look: look)
            if renderingPolicy.rendersCaustic {
                drawCaustics(in: &context, rect: rect, liquid: liquid, waterlineY: waterlineY, look: look)
            }
            drawSurface(in: &context, rect: rect, innerWall: innerWall, look: look)
        }
    }

    private func drawBody(
        in context: inout GraphicsContext,
        rect: CGRect,
        liquid: Path,
        innerWall: Path,
        waterlineY: CGFloat,
        look: BubbleLiquidLook
    ) {
        context.fill(
            liquid,
            with: .linearGradient(
                Gradient(stops: look.depthStops),
                startPoint: CGPoint(x: rect.midX, y: waterlineY - 2),
                endPoint: CGPoint(x: rect.midX, y: waterlineY + rect.height * 0.84)
            )
        )

        context.fill(
            liquid,
            with: .linearGradient(
                Gradient(colors: [look.litSide, .clear, look.shadedSide]),
                startPoint: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2),
                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
            )
        )

        // Light bent by the curved glass gathers along the wall away from the light.
        var rim = context
        rim.clip(to: liquid)
        rim.addFilter(.blur(radius: 2.6))
        rim.stroke(
            innerWall,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.45),
                    .init(color: look.rimLight, location: 0.85),
                    .init(color: look.rimLight.opacity(0.6), location: 1)
                ]),
                startPoint: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.25),
                endPoint: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.maxY - rect.height * 0.02)
            ),
            lineWidth: 7
        )
    }

    /// Threads of light focused by the moving surface, gathered low and on the side away from
    /// the light. Two drifting copies of one pattern cross, so the threads shift slowly instead
    /// of sliding past as one sheet.
    private func drawCaustics(
        in context: inout GraphicsContext,
        rect: CGRect,
        liquid: Path,
        waterlineY: CGFloat,
        look: BubbleLiquidLook
    ) {
        // The light needs some depth of liquid to gather in.
        let depth = max(0, min(1, (frame.fillRatio - 0.06) / 0.45))
        guard depth > 0 else { return }

        let drift = frame.wavePhase
        let pattern = BubbleCausticPattern.image

        var caustics = context
        caustics.clip(to: liquid)
        caustics.opacity = look.causticOpacity * depth * (1 - frame.boundaryCue * 0.3)
        caustics.blendMode = look.causticBlend
        caustics.drawLayer { layer in
            layer.addFilter(.blur(radius: 1.0))
            layer.addFilter(.colorMultiply(look.causticColor))
            layer.fill(
                Path(rect),
                with: .tiledImage(pattern, origin: CGPoint(x: drift * 2.0, y: drift * 0.7), scale: 1.0)
            )
            layer.blendMode = .plusLighter
            layer.opacity = 0.7
            layer.fill(
                Path(rect),
                with: .tiledImage(pattern, origin: CGPoint(x: 61 - drift * 1.4, y: 83 + drift * 1.1), scale: 0.76)
            )

            // Gathered low and on the side away from the light, and kept clear of the surface.
            layer.blendMode = .destinationIn
            layer.opacity = 1
            layer.fill(
                Path(rect),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white.opacity(0.35), location: 0.45),
                        .init(color: .clear, location: 1)
                    ]),
                    center: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.maxY - rect.height * 0.04),
                    startRadius: 0,
                    endRadius: rect.width * 0.46
                )
            )
            layer.fill(
                Path(rect),
                with: .linearGradient(
                    Gradient(colors: [.clear, .white]),
                    startPoint: CGPoint(x: rect.midX, y: waterlineY + 6),
                    endPoint: CGPoint(x: rect.midX, y: waterlineY + 44)
                )
            )
        }
    }

    /// The liquid's top surface. Its far edge catches the light; its near edge is the water line.
    private func drawSurface(in context: inout GraphicsContext, rect: CGRect, innerWall: Path, look: BubbleLiquidLook) {
        let innerOutline = BubbleVessel.polygon(of: innerWall)
        guard let surface = BubbleVessel.surface(
            in: rect,
            innerOutline: innerOutline,
            fillRatio: frame.fillRatio,
            amplitude: frame.amplitude,
            phase: frame.wavePhase
        ) else {
            return
        }

        let bounds = surface.shape.boundingRect
        let fade = 1 - frame.boundaryCue * 0.2

        context.fill(
            surface.shape,
            with: .linearGradient(
                Gradient(colors: look.surfaceColors),
                startPoint: CGPoint(x: bounds.midX, y: bounds.minY),
                endPoint: CGPoint(x: bounds.midX, y: bounds.maxY)
            )
        )

        // A soft sheen where the light from the top left is mirrored.
        var sheen = context
        sheen.clip(to: surface.shape)
        sheen.translateBy(x: bounds.minX + bounds.width * 0.30, y: bounds.minY + bounds.height * 0.35)
        sheen.scaleBy(x: 1, y: 0.22)
        sheen.fill(
            Path(ellipseIn: CGRect(x: -bounds.width * 0.3, y: -bounds.width * 0.3, width: bounds.width * 0.6, height: bounds.width * 0.6)),
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(look.isDark ? 0.22 : 0.40), .clear]),
                center: .zero,
                startRadius: 0,
                endRadius: bounds.width * 0.3
            )
        )

        // The edges fade out toward the walls, so they read as light on the surface rather
        // than as outlines drawn around it.
        var farGlow = context
        farGlow.addFilter(.blur(radius: 1.4))
        farGlow.stroke(
            surface.farEdge,
            with: edgeShading(Color.white, peak: (look.isDark ? 0.34 : 0.85) * fade, falloff: 0.35, in: bounds),
            lineWidth: 2.2
        )
        context.stroke(
            surface.farEdge,
            with: edgeShading(
                look.isDark ? Color.white : look.deep,
                peak: (look.isDark ? 0.46 : 0.30) * fade,
                falloff: 0.40,
                in: bounds
            ),
            lineWidth: 0.7
        )

        var nearGlow = context
        nearGlow.addFilter(.blur(radius: 2.4))
        nearGlow.stroke(
            surface.nearEdge,
            with: edgeShading(look.glow, peak: (look.isDark ? 0.22 : 0.30) * fade, falloff: 0.6, in: bounds),
            lineWidth: 3
        )
        context.stroke(
            surface.nearEdge,
            with: edgeShading(
                look.isDark ? look.glow : look.deep,
                peak: (look.isDark ? 0.52 : 0.42) * fade,
                falloff: 0.65,
                in: bounds
            ),
            lineWidth: 0.9
        )
    }

    /// A color along a surface edge: brightest toward the light on the left, `falloff` of that
    /// on the right, and gone at both walls.
    private func edgeShading(_ color: Color, peak: Double, falloff: Double, in bounds: CGRect) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(stops: [
                .init(color: color.opacity(0), location: 0),
                .init(color: color.opacity(peak), location: 0.16),
                .init(color: color.opacity(peak * (0.55 + falloff * 0.45)), location: 0.55),
                .init(color: color.opacity(peak * falloff), location: 0.86),
                .init(color: color.opacity(0), location: 1)
            ]),
            startPoint: CGPoint(x: bounds.minX, y: bounds.midY),
            endPoint: CGPoint(x: bounds.maxX, y: bounds.midY)
        )
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

/// A tileable pattern of caustic threads: bright lines where neighbouring cells meet, the way a
/// rippled surface gathers light onto the bottom of a glass. White with the pattern in its
/// alpha, so the liquid can tint it. Generated once, the first time the liquid is drawn.
enum BubbleCausticPattern {
    static let image = Image(decorative: makeImage(pixels: 256, cells: 5), scale: 1)

    static func makeImage(pixels: Int, cells: Int) -> CGImage {
        var random = SeededRandom(seed: 0x5EED_CA05)
        let jitter = (0..<(cells * cells)).map { _ in
            SIMD2(0.15 + 0.7 * random.nextUnit(), 0.15 + 0.7 * random.nextUnit())
        }
        let cellsPerPixel = Double(cells) / Double(pixels)
        // One period of the warp spans the tile, so the pattern still wraps seamlessly.
        let warpFrequency = 2 * Double.pi * 2 / Double(cells)
        var bytes = [UInt8](repeating: 0, count: pixels * pixels * 4)

        for row in 0..<pixels {
            for column in 0..<pixels {
                var point = SIMD2((Double(column) + 0.5) * cellsPerPixel, (Double(row) + 0.5) * cellsPerPixel)
                // Bend the straight cell borders into curved threads.
                point += 0.32 * SIMD2(sin(point.y * warpFrequency + 1.3), sin(point.x * warpFrequency + 0.4))

                let cellX = point.x.rounded(.down)
                let cellY = point.y.rounded(.down)
                var nearest = Double.infinity
                var second = Double.infinity

                for offsetY in -1...1 {
                    for offsetX in -1...1 {
                        let neighborX = cellX + Double(offsetX)
                        let neighborY = cellY + Double(offsetY)
                        let wrappedX = ((Int(neighborX) % cells) + cells) % cells
                        let wrappedY = ((Int(neighborY) % cells) + cells) % cells
                        let center = SIMD2(neighborX, neighborY) + jitter[wrappedY * cells + wrappedX]
                        let delta = center - point
                        let distance = (delta * delta).sum().squareRoot()
                        if distance < nearest {
                            second = nearest
                            nearest = distance
                        } else if distance < second {
                            second = distance
                        }
                    }
                }

                // Brightest on the border between two cells, falling off quickly to either side,
                // and fading in and out along its length so the threads never close into a net.
                let border = min(1, max(0, (second - nearest) / 0.11))
                let eased = border * border * (3 - 2 * border)
                let presence = 0.5 + 0.5 * sin(point.x * warpFrequency * 0.5 + 0.7) * sin(point.y * warpFrequency * 0.5 + 2.1)
                let strength = pow(1 - eased, 3) * (0.15 + 0.85 * presence * presence)
                let value = UInt8(min(255, max(0, strength * 255)))
                let index = (row * pixels + column) * 4
                bytes[index] = value
                bytes[index + 1] = value
                bytes[index + 2] = value
                bytes[index + 3] = value
            }
        }

        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(
            width: pixels,
            height: pixels,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: pixels * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )!
    }
}

/// SplitMix64, so the caustic pattern is the same on every launch.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func nextUnit() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        value ^= value >> 31
        return Double(value >> 11) / Double(UInt64(1) << 53)
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
