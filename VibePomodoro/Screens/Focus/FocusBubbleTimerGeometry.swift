import SwiftUI

struct BubbleShellProfile {
    let upperSpecularSize: CGSize
    let upperSpecularOffset: CGSize
    let upperSpecularRotation: Double
    let shoulderSpecularSize: CGSize
    let shoulderSpecularOffset: CGSize
    let shoulderSpecularRotation: Double
    let lowerCausticSize: CGSize
    let lowerCausticOffset: CGSize
    let outerGlowSize: CGSize
    let outerGlowOffset: CGSize
    let innerLensSize: CGSize
    let innerLensOffset: CGSize
    let innerLensRotation: Double
    let sideRefractionSize: CGSize
    let sideRefractionOffset: CGSize
    let sideRefractionRotation: Double
    let waveAmplitudeBase: Double
    let waveAmplitudeRange: Double
}

extension BubbleShellProfile {
    static func interpolated(
        from source: BubbleShellProfile,
        to target: BubbleShellProfile,
        progress: CGFloat
    ) -> BubbleShellProfile {
        BubbleShellProfile(
            upperSpecularSize: interpolate(source.upperSpecularSize, target.upperSpecularSize, progress),
            upperSpecularOffset: interpolate(source.upperSpecularOffset, target.upperSpecularOffset, progress),
            upperSpecularRotation: interpolate(source.upperSpecularRotation, target.upperSpecularRotation, progress),
            shoulderSpecularSize: interpolate(source.shoulderSpecularSize, target.shoulderSpecularSize, progress),
            shoulderSpecularOffset: interpolate(source.shoulderSpecularOffset, target.shoulderSpecularOffset, progress),
            shoulderSpecularRotation: interpolate(source.shoulderSpecularRotation, target.shoulderSpecularRotation, progress),
            lowerCausticSize: interpolate(source.lowerCausticSize, target.lowerCausticSize, progress),
            lowerCausticOffset: interpolate(source.lowerCausticOffset, target.lowerCausticOffset, progress),
            outerGlowSize: interpolate(source.outerGlowSize, target.outerGlowSize, progress),
            outerGlowOffset: interpolate(source.outerGlowOffset, target.outerGlowOffset, progress),
            innerLensSize: interpolate(source.innerLensSize, target.innerLensSize, progress),
            innerLensOffset: interpolate(source.innerLensOffset, target.innerLensOffset, progress),
            innerLensRotation: interpolate(source.innerLensRotation, target.innerLensRotation, progress),
            sideRefractionSize: interpolate(source.sideRefractionSize, target.sideRefractionSize, progress),
            sideRefractionOffset: interpolate(source.sideRefractionOffset, target.sideRefractionOffset, progress),
            sideRefractionRotation: interpolate(source.sideRefractionRotation, target.sideRefractionRotation, progress),
            waveAmplitudeBase: interpolate(source.waveAmplitudeBase, target.waveAmplitudeBase, progress),
            waveAmplitudeRange: interpolate(source.waveAmplitudeRange, target.waveAmplitudeRange, progress)
        )
    }
}

func interpolate(_ source: CGSize, _ target: CGSize, _ progress: CGFloat) -> CGSize {
    CGSize(
        width: interpolate(source.width, target.width, progress),
        height: interpolate(source.height, target.height, progress)
    )
}

func interpolate(_ source: CGPoint, _ target: CGPoint, _ progress: CGFloat) -> CGPoint {
    CGPoint(
        x: interpolate(source.x, target.x, progress),
        y: interpolate(source.y, target.y, progress)
    )
}

func interpolate(_ source: CGFloat, _ target: CGFloat, _ progress: CGFloat) -> CGFloat {
    source + ((target - source) * progress)
}

func interpolate(_ source: Double, _ target: Double, _ progress: CGFloat) -> Double {
    source + ((target - source) * Double(progress))
}

extension BubbleShellProfile {
    /// The highlights and glows were placed for outlines that fill the frame. This moves and
    /// scales them onto an outline that fills `frame`, given in units of the frame, so they stay
    /// on the glass wherever the vessel stands.
    func fitted(to frame: CGRect, sphereSize: CGFloat) -> BubbleShellProfile {
        let scale = CGSize(
            width: frame.width / BubbleVessel.outlineExtent,
            height: frame.height / BubbleVessel.outlineExtent
        )
        let center = CGSize(
            width: (frame.midX - 0.5) * sphereSize,
            height: (frame.midY - 0.5) * sphereSize
        )
        func size(_ size: CGSize) -> CGSize {
            CGSize(width: size.width * scale.width, height: size.height * scale.height)
        }
        func offset(_ offset: CGSize) -> CGSize {
            CGSize(
                width: center.width + offset.width * scale.width,
                height: center.height + offset.height * scale.height
            )
        }

        return BubbleShellProfile(
            upperSpecularSize: size(upperSpecularSize),
            upperSpecularOffset: offset(upperSpecularOffset),
            upperSpecularRotation: upperSpecularRotation,
            shoulderSpecularSize: size(shoulderSpecularSize),
            shoulderSpecularOffset: offset(shoulderSpecularOffset),
            shoulderSpecularRotation: shoulderSpecularRotation,
            lowerCausticSize: size(lowerCausticSize),
            lowerCausticOffset: offset(lowerCausticOffset),
            outerGlowSize: size(outerGlowSize),
            outerGlowOffset: offset(outerGlowOffset),
            innerLensSize: size(innerLensSize),
            innerLensOffset: offset(innerLensOffset),
            innerLensRotation: innerLensRotation,
            sideRefractionSize: size(sideRefractionSize),
            sideRefractionOffset: offset(sideRefractionOffset),
            sideRefractionRotation: sideRefractionRotation,
            waveAmplitudeBase: waveAmplitudeBase,
            waveAmplitudeRange: waveAmplitudeRange
        )
    }
}

extension SessionPhase {
    func bubbleShellProfile(for sphereSize: CGFloat) -> BubbleShellProfile {
        baseShellProfile(for: sphereSize).fitted(to: bubbleOutline.frame, sphereSize: sphereSize)
    }

    private func baseShellProfile(for sphereSize: CGFloat) -> BubbleShellProfile {
        switch self {
        case .focus:
            return BubbleShellProfile(
                upperSpecularSize: CGSize(width: sphereSize * 0.40, height: sphereSize * 0.24),
                upperSpecularOffset: CGSize(width: -sphereSize * 0.10, height: -sphereSize * 0.30),
                upperSpecularRotation: -18,
                shoulderSpecularSize: CGSize(width: sphereSize * 0.22, height: sphereSize * 0.18),
                shoulderSpecularOffset: CGSize(width: -sphereSize * 0.29, height: -sphereSize * 0.13),
                shoulderSpecularRotation: -24,
                lowerCausticSize: CGSize(width: sphereSize * 0.40, height: sphereSize * 0.13),
                lowerCausticOffset: CGSize(width: 0, height: sphereSize * 0.33),
                outerGlowSize: CGSize(width: sphereSize * 0.61, height: sphereSize * 0.15),
                outerGlowOffset: CGSize(width: 0, height: sphereSize * 0.45),
                innerLensSize: CGSize(width: sphereSize * 0.40, height: sphereSize * 0.22),
                innerLensOffset: CGSize(width: sphereSize * 0.02, height: -sphereSize * 0.18),
                innerLensRotation: 10,
                sideRefractionSize: CGSize(width: sphereSize * 0.20, height: sphereSize * 0.42),
                sideRefractionOffset: CGSize(width: sphereSize * 0.22, height: -sphereSize * 0.12),
                sideRefractionRotation: 14,
                waveAmplitudeBase: 2.8,
                waveAmplitudeRange: 1.15
            )
        case .shortBreak:
            return BubbleShellProfile(
                upperSpecularSize: CGSize(width: sphereSize * 0.38, height: sphereSize * 0.22),
                upperSpecularOffset: CGSize(width: -sphereSize * 0.14, height: -sphereSize * 0.27),
                upperSpecularRotation: -28,
                shoulderSpecularSize: CGSize(width: sphereSize * 0.21, height: sphereSize * 0.17),
                shoulderSpecularOffset: CGSize(width: -sphereSize * 0.33, height: -sphereSize * 0.06),
                shoulderSpecularRotation: -32,
                lowerCausticSize: CGSize(width: sphereSize * 0.44, height: sphereSize * 0.14),
                lowerCausticOffset: CGSize(width: -sphereSize * 0.02, height: sphereSize * 0.34),
                outerGlowSize: CGSize(width: sphereSize * 0.66, height: sphereSize * 0.16),
                outerGlowOffset: CGSize(width: -sphereSize * 0.02, height: sphereSize * 0.44),
                innerLensSize: CGSize(width: sphereSize * 0.42, height: sphereSize * 0.22),
                innerLensOffset: CGSize(width: -sphereSize * 0.01, height: -sphereSize * 0.19),
                innerLensRotation: -8,
                sideRefractionSize: CGSize(width: sphereSize * 0.24, height: sphereSize * 0.40),
                sideRefractionOffset: CGSize(width: sphereSize * 0.24, height: -sphereSize * 0.10),
                sideRefractionRotation: 24,
                waveAmplitudeBase: 2.5,
                waveAmplitudeRange: 1.05
            )
        case .longBreak:
            return BubbleShellProfile(
                upperSpecularSize: CGSize(width: sphereSize * 0.42, height: sphereSize * 0.23),
                upperSpecularOffset: CGSize(width: -sphereSize * 0.08, height: -sphereSize * 0.28),
                upperSpecularRotation: -14,
                shoulderSpecularSize: CGSize(width: sphereSize * 0.22, height: sphereSize * 0.17),
                shoulderSpecularOffset: CGSize(width: -sphereSize * 0.25, height: -sphereSize * 0.08),
                shoulderSpecularRotation: -18,
                lowerCausticSize: CGSize(width: sphereSize * 0.43, height: sphereSize * 0.14),
                lowerCausticOffset: CGSize(width: sphereSize * 0.03, height: sphereSize * 0.35),
                outerGlowSize: CGSize(width: sphereSize * 0.67, height: sphereSize * 0.16),
                outerGlowOffset: CGSize(width: sphereSize * 0.03, height: sphereSize * 0.44),
                innerLensSize: CGSize(width: sphereSize * 0.44, height: sphereSize * 0.23),
                innerLensOffset: CGSize(width: sphereSize * 0.04, height: -sphereSize * 0.18),
                innerLensRotation: 6,
                sideRefractionSize: CGSize(width: sphereSize * 0.22, height: sphereSize * 0.41),
                sideRefractionOffset: CGSize(width: sphereSize * 0.18, height: -sphereSize * 0.10),
                sideRefractionRotation: 8,
                waveAmplitudeBase: 2.55,
                waveAmplitudeRange: 1.08
            )
        }
    }
}

struct BubbleGlassShape: Shape {
    let sourcePhase: SessionPhase
    let targetPhase: SessionPhase
    var progress: CGFloat = 1

    init(phase: SessionPhase) {
        sourcePhase = phase
        targetPhase = phase
        progress = 1
    }

    init(sourcePhase: SessionPhase, targetPhase: SessionPhase, progress: CGFloat) {
        self.sourcePhase = sourcePhase
        self.targetPhase = targetPhase
        self.progress = progress
    }

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard rect.width.isFinite,
              rect.height.isFinite,
              rect.width > 1,
              rect.height > 1 else {
            return Path()
        }

        let insetRect = rect.insetBy(dx: 0.9, dy: 0.9)
        let geometry = BubbleShapeGeometry.interpolated(
            from: sourcePhase.bubbleShapeGeometry,
            to: targetPhase.bubbleShapeGeometry,
            progress: max(0, min(progress, 1))
        )

        return geometry.path(in: insetRect)
    }
}

private struct BubbleShapeGeometry {
    let start: CGPoint
    let segments: [BubbleShapeCurveSegment]

    func path(in rect: CGRect) -> Path {
        guard !segments.isEmpty else { return Path() }

        var path = Path()
        path.move(to: scaled(start, in: rect))

        for segment in segments {
            path.addCurve(
                to: scaled(segment.end, in: rect),
                control1: scaled(segment.control1, in: rect),
                control2: scaled(segment.control2, in: rect)
            )
        }

        path.closeSubpath()
        return path
    }

    static func interpolated(
        from source: BubbleShapeGeometry,
        to target: BubbleShapeGeometry,
        progress: CGFloat
    ) -> BubbleShapeGeometry {
        BubbleShapeGeometry(
            start: interpolate(source.start, target.start, progress),
            segments: zip(source.segments, target.segments).map { sourceSegment, targetSegment in
                BubbleShapeCurveSegment(
                    control1: interpolate(sourceSegment.control1, targetSegment.control1, progress),
                    control2: interpolate(sourceSegment.control2, targetSegment.control2, progress),
                    end: interpolate(sourceSegment.end, targetSegment.end, progress)
                )
            }
        )
    }

    private func scaled(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + (rect.width * point.x),
            y: rect.minY + (rect.height * point.y)
        )
    }
}

private struct BubbleShapeCurveSegment {
    let control1: CGPoint
    let control2: CGPoint
    let end: CGPoint
}

/// A phase's outline: a smooth closed curve that turns gently all the way round, so the light on
/// the glass glides along it instead of catching on corners. It is an ellipse that widens toward
/// its bottom (or, with a negative `taper`, toward its top), with a faint three-lobed swell,
/// turned by `tilt` degrees. Every outline stands on the same ground line, centered across the
/// frame, and its longer side spans the same share of it.
private struct BubbleOutline {
    let taper: Double
    let width: Double
    let height: Double
    let tilt: Double
    var lobes: Double = 0
    var lobePhase: Double = 0

    /// Where every outline meets the page, as a share of the frame's height.
    static let ground: CGFloat = 0.985
    /// Cubic segments around the outline; each follows its stretch of the curve within a small
    /// fraction of a point.
    static let segmentCount = 12

    struct Fitted {
        let geometry: BubbleShapeGeometry
        /// The outline's bounds, in units of the frame.
        let frame: CGRect
    }

    private func point(at t: Double) -> CGPoint {
        let swell = 1 + lobes * cos(3 * (t - lobePhase))
        let x = cos(t) * (1 + taper * sin(t)) * width * swell
        let y = sin(t) * height * swell
        let angle = tilt * .pi / 180
        return CGPoint(x: x * cos(angle) - y * sin(angle), y: x * sin(angle) + y * cos(angle))
    }

    var fitted: Fitted {
        let samples = (0..<720).map { point(at: Double($0) * 2 * .pi / 720) }
        let minX = samples.map(\.x).min() ?? -1
        let maxX = samples.map(\.x).max() ?? 1
        let minY = samples.map(\.y).min() ?? -1
        let maxY = samples.map(\.y).max() ?? 1
        let scale = BubbleVessel.outlineExtent / max(maxX - minX, maxY - minY)
        let shift = CGPoint(x: 0.5 - (minX + maxX) / 2 * scale, y: Self.ground - maxY * scale)
        func place(_ point: CGPoint) -> CGPoint {
            CGPoint(x: shift.x + point.x * scale, y: shift.y + point.y * scale)
        }

        // Each segment is the cubic that meets the curve at both of its ends heading the same way
        // as the curve, so neighboring segments join without a kink.
        let step = 2 * Double.pi / Double(Self.segmentCount)
        let delta = 1e-4
        func handle(at t: Double) -> CGPoint {
            let before = point(at: t - delta)
            let after = point(at: t + delta)
            let length = scale * step / 3 / (2 * delta)
            return CGPoint(x: (after.x - before.x) * length, y: (after.y - before.y) * length)
        }
        let segments = (0..<Self.segmentCount).map { index in
            let start = Double(index) * step
            let end = start + step
            let from = place(point(at: start))
            let to = place(point(at: end))
            let leaving = handle(at: start)
            let arriving = handle(at: end)
            return BubbleShapeCurveSegment(
                control1: CGPoint(x: from.x + leaving.x, y: from.y + leaving.y),
                control2: CGPoint(x: to.x - arriving.x, y: to.y - arriving.y),
                end: to
            )
        }

        return Fitted(
            geometry: BubbleShapeGeometry(start: place(point(at: 0)), segments: segments),
            frame: CGRect(
                x: shift.x + minX * scale,
                y: shift.y + minY * scale,
                width: (maxX - minX) * scale,
                height: (maxY - minY) * scale
            )
        )
    }
}

/// Each phase's outline has a gesture of its own, computed once.
private enum BubbleOutlines {
    /// Focus: an upright drop, full and steady low down and gathered toward the top. It stands
    /// taller than it is wide, so it never reads as the long break's broad shape.
    static let focus = BubbleOutline(taper: 0.19, width: 0.95, height: 1.0, tilt: -3).fitted
    /// Short break: a bubble on its way up, wider high up and leaning.
    static let shortBreak = BubbleOutline(taper: -0.12, width: 0.90, height: 1.0, tilt: 9).fitted
    /// Long break: broad and low, at rest.
    static let longBreak = BubbleOutline(
        taper: 0.05, width: 1.0, height: 0.86, tilt: -5, lobes: 0.012, lobePhase: 0.4
    ).fitted
}

private extension SessionPhase {
    var bubbleOutline: BubbleOutline.Fitted {
        switch self {
        case .focus: BubbleOutlines.focus
        case .shortBreak: BubbleOutlines.shortBreak
        case .longBreak: BubbleOutlines.longBreak
        }
    }

    var bubbleShapeGeometry: BubbleShapeGeometry {
        bubbleOutline.geometry
    }
}

/// The water line. The wave that ripples it, the surface, and the digit split are computed per
/// pixel by `bubbleLiquid` in FocusBubbleLiquid.metal. The liquid rises from the bottom of `rect`,
/// the vessel's bounds, to its top.
enum BubbleWave {
    static func waterlineY(fillRatio: Double, in rect: CGRect) -> CGFloat {
        rect.maxY - rect.height * CGFloat(max(0, min(fillRatio, 1.08)))
    }
}

/// The bubble as a glass vessel: a wall of glass around the liquid, and a liquid surface
/// seen slightly from above. Light comes from the top left.
enum BubbleVessel {
    /// The longer side of every outline, as a share of the frame.
    static let outlineExtent: CGFloat = 0.97
    /// The inside of the glass as a scale of the outer silhouette, about 6 pt of wall.
    static let innerScale: CGFloat = 0.955

    /// The inside of the glass: the outer silhouette scaled about its own middle, so the wall is
    /// as thick at the top as at the bottom wherever the vessel stands in the frame.
    static func innerPath(of outer: Path, in rect: CGRect) -> Path {
        let bounds = outer.boundingRect
        let center = bounds.isEmpty
            ? CGPoint(x: rect.midX, y: rect.midY)
            : CGPoint(x: bounds.midX, y: bounds.midY)
        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .scaledBy(x: innerScale, y: innerScale)
            .translatedBy(x: -center.x, y: -center.y)
        return outer.applying(transform)
    }

    /// The path's outline as straight segments, for cheap horizontal cross-sections.
    static func polygon(of path: Path, curveSteps: Int = 10) -> [CGPoint] {
        var points: [CGPoint] = []
        var current = CGPoint.zero

        path.forEach { element in
            switch element {
            case let .move(to: point), let .line(to: point):
                points.append(point)
                current = point
            case let .quadCurve(to: point, control: control):
                for step in 1...curveSteps {
                    let t = CGFloat(step) / CGFloat(curveSteps)
                    let u = 1 - t
                    points.append(CGPoint(
                        x: u * u * current.x + 2 * u * t * control.x + t * t * point.x,
                        y: u * u * current.y + 2 * u * t * control.y + t * t * point.y
                    ))
                }
                current = point
            case let .curve(to: point, control1: control1, control2: control2):
                for step in 1...curveSteps {
                    let t = CGFloat(step) / CGFloat(curveSteps)
                    let u = 1 - t
                    points.append(CGPoint(
                        x: u * u * u * current.x + 3 * u * u * t * control1.x + 3 * u * t * t * control2.x + t * t * t * point.x,
                        y: u * u * u * current.y + 3 * u * u * t * control1.y + 3 * u * t * t * control2.y + t * t * t * point.y
                    ))
                }
                current = point
            case .closeSubpath:
                break
            }
        }

        return points
    }

    /// Where a closed outline crosses a horizontal line, from its left to its right edge.
    static func horizontalExtent(of polygon: [CGPoint], atY y: CGFloat) -> ClosedRange<CGFloat>? {
        guard polygon.count > 2 else { return nil }

        var lower = CGFloat.infinity
        var upper = -CGFloat.infinity
        for index in polygon.indices {
            let start = polygon[index]
            let end = polygon[(index + 1) % polygon.count]
            guard (start.y <= y && end.y > y) || (end.y <= y && start.y > y) else { continue }

            let x = start.x + (y - start.y) / (end.y - start.y) * (end.x - start.x)
            lower = min(lower, x)
            upper = max(upper, x)
        }

        return lower < upper ? lower...upper : nil
    }

    /// The liquid's top surface seen slightly from above: an ellipse spanning the inside of the
    /// vessel at the water line. The shader draws it and ripples its two edges.
    struct Surface: Equatable {
        let waterlineY: CGFloat
        let centerX: CGFloat
        let radius: CGFloat
        /// Half the ellipse's height, its near and far edges' distance from the water line.
        let depth: CGFloat
    }

    /// `reach` is how far the waves move the edges of the surface up and down.
    static func surface(
        in rect: CGRect,
        innerOutline: [CGPoint],
        fillRatio: Double,
        reach: CGFloat = 0
    ) -> Surface? {
        let waterlineY = BubbleWave.waterlineY(fillRatio: fillRatio, in: rect)
        guard waterlineY > rect.minY + 4,
              waterlineY < rect.maxY - 4,
              let extent = horizontalExtent(of: innerOutline, atY: waterlineY) else {
            return nil
        }

        let depth = min(12, (extent.upperBound - extent.lowerBound) / 2 * 0.09)
        // The surface's far and near edges and its waves meet the glass a little above and below
        // the water line. Where the glass is wider there, the surface spans to it and the glass
        // cuts it off, so no gap of air opens between the surface and the glass.
        var lower = extent.lowerBound
        var upper = extent.upperBound
        for y in [waterlineY - depth - reach, waterlineY + depth + reach] {
            guard let other = horizontalExtent(of: innerOutline, atY: y) else { continue }
            lower = min(lower, other.lowerBound)
            upper = max(upper, other.upperBound)
        }

        return Surface(
            waterlineY: waterlineY,
            centerX: (lower + upper) / 2,
            radius: (upper - lower) / 2 + 1,
            depth: depth
        )
    }

    /// The inside of the glass as the shader sees it. `values` holds `count` (left, right) pairs
    /// on rows spread evenly from the top to the bottom of the inside, then `count` (top, bottom)
    /// pairs on columns spread evenly across it; `bounds` is where they start and end. Rows alone
    /// lose the bottom and the top, where the glass runs nearly level, so the shader takes the
    /// distance to the glass from both.
    struct CrossSections: Equatable {
        let bounds: CGRect
        let values: [Float]
    }

    static func crossSections(of innerOutline: [CGPoint], count: Int) -> CrossSections {
        guard count > 1,
              let minX = innerOutline.map(\.x).min(),
              let maxX = innerOutline.map(\.x).max(),
              let minY = innerOutline.map(\.y).min(),
              let maxY = innerOutline.map(\.y).max() else {
            return CrossSections(bounds: .zero, values: [])
        }

        let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        // The outermost rows and columns sit just inside the bounds, where they still cross the
        // outline.
        let inset: CGFloat = 0.25
        var values: [Float] = []
        values.reserveCapacity(count * 4)

        for index in 0..<count {
            let y = interpolate(minY + inset, maxY - inset, CGFloat(index) / CGFloat(count - 1))
            let extent = horizontalExtent(of: innerOutline, atY: y) ?? bounds.midX...bounds.midX
            values.append(Float(extent.lowerBound))
            values.append(Float(extent.upperBound))
        }
        // Columns are rows of the outline with its axes swapped.
        let transposed = innerOutline.map { CGPoint(x: $0.y, y: $0.x) }
        for index in 0..<count {
            let x = interpolate(minX + inset, maxX - inset, CGFloat(index) / CGFloat(count - 1))
            let extent = horizontalExtent(of: transposed, atY: x) ?? bounds.midY...bounds.midY
            values.append(Float(extent.lowerBound))
            values.append(Float(extent.upperBound))
        }

        return CrossSections(bounds: bounds, values: values)
    }
}

/// The inside of the glass, which holds the liquid.
struct BubbleInnerShape: Shape {
    let phaseMorph: BubblePhaseMorph

    func path(in rect: CGRect) -> Path {
        BubbleVessel.innerPath(of: phaseMorph.shape.path(in: rect), in: rect)
    }
}

/// The glass wall: the band between the outer silhouette and the inside of the vessel.
struct BubbleWallShape: Shape {
    let phaseMorph: BubblePhaseMorph

    func path(in rect: CGRect) -> Path {
        let outer = phaseMorph.shape.path(in: rect)
        var path = outer
        path.addPath(BubbleVessel.innerPath(of: outer, in: rect))
        return path
    }
}
