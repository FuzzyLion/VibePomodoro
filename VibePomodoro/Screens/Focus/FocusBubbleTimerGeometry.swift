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

extension SessionPhase {
    func bubbleShellProfile(for sphereSize: CGFloat) -> BubbleShellProfile {
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

    static func smoothClosedLoop(
        points: [CGPoint],
        controlScale: CGFloat = 0.12
    ) -> BubbleShapeGeometry {
        guard points.count > 2 else {
            return BubbleShapeGeometry(start: points.first ?? .zero, segments: [])
        }

        let count = points.count
        let segments = points.indices.map { index in
            let previous = points[(index + count - 1) % count]
            let current = points[index]
            let next = points[(index + 1) % count]
            let afterNext = points[(index + 2) % count]

            return BubbleShapeCurveSegment(
                control1: CGPoint(
                    x: current.x + ((next.x - previous.x) * controlScale),
                    y: current.y + ((next.y - previous.y) * controlScale)
                ),
                control2: CGPoint(
                    x: next.x - ((afterNext.x - current.x) * controlScale),
                    y: next.y - ((afterNext.y - current.y) * controlScale)
                ),
                end: next
            )
        }

        return BubbleShapeGeometry(start: points[0], segments: segments)
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

private extension SessionPhase {
    var bubbleShapeGeometry: BubbleShapeGeometry {
        switch self {
        case .focus:
            return BubbleShapeGeometry.smoothClosedLoop(points: [
                CGPoint(x: 0.440, y: 0.020),
                CGPoint(x: 0.735, y: 0.048),
                CGPoint(x: 0.995, y: 0.300),
                CGPoint(x: 0.905, y: 0.825),
                CGPoint(x: 0.635, y: 0.988),
                CGPoint(x: 0.205, y: 0.915),
                CGPoint(x: 0.015, y: 0.585),
                CGPoint(x: 0.130, y: 0.180)
            ])
        case .shortBreak:
            return BubbleShapeGeometry.smoothClosedLoop(points: [
                CGPoint(x: 0.490, y: 0.026),
                CGPoint(x: 0.805, y: 0.125),
                CGPoint(x: 0.935, y: 0.360),
                CGPoint(x: 0.965, y: 0.665),
                CGPoint(x: 0.540, y: 0.982),
                CGPoint(x: 0.165, y: 0.815),
                CGPoint(x: 0.035, y: 0.525),
                CGPoint(x: 0.075, y: 0.215)
            ])
        case .longBreak:
            return BubbleShapeGeometry.smoothClosedLoop(points: [
                CGPoint(x: 0.490, y: 0.024),
                CGPoint(x: 0.835, y: 0.085),
                CGPoint(x: 0.930, y: 0.300),
                CGPoint(x: 0.965, y: 0.595),
                CGPoint(x: 0.845, y: 0.835),
                CGPoint(x: 0.535, y: 0.982),
                CGPoint(x: 0.175, y: 0.855),
                CGPoint(x: 0.070, y: 0.290)
            ])
        }
    }
}

/// The water line. The wave that ripples it, the surface, and the digit split are computed per
/// pixel by `bubbleLiquid` in FocusBubbleLiquid.metal.
enum BubbleWave {
    static func waterlineY(fillRatio: Double, in rect: CGRect) -> CGFloat {
        rect.height * (1 - CGFloat(max(0, min(fillRatio, 1.08))))
    }
}

/// The bubble as a glass vessel: a wall of glass around the liquid, and a liquid surface
/// seen slightly from above. Light comes from the top left.
enum BubbleVessel {
    /// The inside of the glass as a scale of the outer silhouette, about 6 pt of wall.
    static let innerScale: CGFloat = 0.955

    static func innerPath(of outer: Path, in rect: CGRect) -> Path {
        let transform = CGAffineTransform(translationX: rect.midX, y: rect.midY)
            .scaledBy(x: innerScale, y: innerScale)
            .translatedBy(x: -rect.midX, y: -rect.midY)
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

    static func surface(in rect: CGRect, innerOutline: [CGPoint], fillRatio: Double) -> Surface? {
        let waterlineY = BubbleWave.waterlineY(fillRatio: fillRatio, in: rect)
        guard waterlineY > rect.minY + 4,
              waterlineY < rect.maxY - 4,
              let extent = horizontalExtent(of: innerOutline, atY: waterlineY) else {
            return nil
        }

        let radius = (extent.upperBound - extent.lowerBound) / 2
        return Surface(
            waterlineY: waterlineY,
            centerX: (extent.lowerBound + extent.upperBound) / 2,
            radius: radius,
            depth: min(12, radius * 0.09)
        )
    }

    /// The inside of the glass as `count` (left, right) pairs on rows spread evenly down `rect`,
    /// for the shader's sense of how far a point is from the glass. Rows outside the vessel
    /// collapse to the middle.
    static func crossSections(of innerOutline: [CGPoint], in rect: CGRect, count: Int) -> [Float] {
        var values: [Float] = []
        values.reserveCapacity(count * 2)
        for row in 0..<count {
            let y = rect.minY + rect.height * CGFloat(row) / CGFloat(max(count - 1, 1))
            let extent = horizontalExtent(of: innerOutline, atY: y) ?? rect.midX...rect.midX
            values.append(Float(extent.lowerBound))
            values.append(Float(extent.upperBound))
        }
        return values
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
