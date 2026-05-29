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
    let depthPoolSize: CGSize
    let depthPoolOffset: CGSize
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
            depthPoolSize: interpolate(source.depthPoolSize, target.depthPoolSize, progress),
            depthPoolOffset: interpolate(source.depthPoolOffset, target.depthPoolOffset, progress),
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
                depthPoolSize: CGSize(width: sphereSize * 0.75, height: sphereSize * 0.23),
                depthPoolOffset: CGSize(width: 0, height: sphereSize * 0.34),
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
                depthPoolSize: CGSize(width: sphereSize * 0.78, height: sphereSize * 0.24),
                depthPoolOffset: CGSize(width: -sphereSize * 0.03, height: sphereSize * 0.34),
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
                depthPoolSize: CGSize(width: sphereSize * 0.79, height: sphereSize * 0.24),
                depthPoolOffset: CGSize(width: sphereSize * 0.03, height: sphereSize * 0.34),
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

private extension SessionPhase {
    var bubbleShapeGeometry: BubbleShapeGeometry {
        switch self {
        case .focus:
            return BubbleShapeGeometry(
                start: CGPoint(x: 0.49, y: 0.01),
                segments: [
                    .init(control1: CGPoint(x: 0.68, y: -0.01), control2: CGPoint(x: 0.79, y: 0.00), end: CGPoint(x: 0.86, y: 0.08)),
                    .init(control1: CGPoint(x: 0.96, y: 0.18), control2: CGPoint(x: 1.01, y: 0.31), end: CGPoint(x: 0.99, y: 0.48)),
                    .init(control1: CGPoint(x: 0.99, y: 0.73), control2: CGPoint(x: 0.96, y: 0.87), end: CGPoint(x: 0.86, y: 0.92)),
                    .init(control1: CGPoint(x: 0.75, y: 0.99), control2: CGPoint(x: 0.61, y: 1.00), end: CGPoint(x: 0.50, y: 1.00)),
                    .init(control1: CGPoint(x: 0.38, y: 0.99), control2: CGPoint(x: 0.25, y: 0.98), end: CGPoint(x: 0.13, y: 0.92)),
                    .init(control1: CGPoint(x: 0.03, y: 0.87), control2: CGPoint(x: -0.01, y: 0.71), end: CGPoint(x: 0.01, y: 0.49)),
                    .init(control1: CGPoint(x: 0.01, y: 0.28), control2: CGPoint(x: 0.01, y: 0.15), end: CGPoint(x: 0.10, y: 0.09)),
                    .init(control1: CGPoint(x: 0.20, y: 0.00), control2: CGPoint(x: 0.33, y: -0.01), end: CGPoint(x: 0.49, y: 0.01))
                ]
            )
        case .shortBreak:
            return BubbleShapeGeometry(
                start: CGPoint(x: 0.49, y: 0.02),
                segments: [
                    .init(control1: CGPoint(x: 0.63, y: -0.01), control2: CGPoint(x: 0.75, y: 0.04), end: CGPoint(x: 0.81, y: 0.12)),
                    .init(control1: CGPoint(x: 0.88, y: 0.18), control2: CGPoint(x: 0.94, y: 0.24), end: CGPoint(x: 0.93, y: 0.34)),
                    .init(control1: CGPoint(x: 0.97, y: 0.46), control2: CGPoint(x: 1.01, y: 0.57), end: CGPoint(x: 0.99, y: 0.67)),
                    .init(control1: CGPoint(x: 0.95, y: 0.85), control2: CGPoint(x: 0.72, y: 0.94), end: CGPoint(x: 0.53, y: 1.00)),
                    .init(control1: CGPoint(x: 0.40, y: 1.01), control2: CGPoint(x: 0.25, y: 0.92), end: CGPoint(x: 0.15, y: 0.81)),
                    .init(control1: CGPoint(x: 0.05, y: 0.69), control2: CGPoint(x: -0.03, y: 0.61), end: CGPoint(x: 0.00, y: 0.52)),
                    .init(control1: CGPoint(x: 0.01, y: 0.41), control2: CGPoint(x: -0.01, y: 0.30), end: CGPoint(x: 0.05, y: 0.20)),
                    .init(control1: CGPoint(x: 0.11, y: 0.08), control2: CGPoint(x: 0.28, y: 0.02), end: CGPoint(x: 0.49, y: 0.02))
                ]
            )
        case .longBreak:
            return BubbleShapeGeometry(
                start: CGPoint(x: 0.49, y: 0.02),
                segments: [
                    .init(control1: CGPoint(x: 0.66, y: 0.00), control2: CGPoint(x: 0.78, y: 0.01), end: CGPoint(x: 0.84, y: 0.08)),
                    .init(control1: CGPoint(x: 0.90, y: 0.13), control2: CGPoint(x: 0.93, y: 0.18), end: CGPoint(x: 0.94, y: 0.28)),
                    .init(control1: CGPoint(x: 0.98, y: 0.38), control2: CGPoint(x: 1.01, y: 0.49), end: CGPoint(x: 0.99, y: 0.60)),
                    .init(control1: CGPoint(x: 0.98, y: 0.74), control2: CGPoint(x: 0.92, y: 0.81), end: CGPoint(x: 0.86, y: 0.84)),
                    .init(control1: CGPoint(x: 0.77, y: 0.91), control2: CGPoint(x: 0.64, y: 1.00), end: CGPoint(x: 0.53, y: 1.00)),
                    .init(control1: CGPoint(x: 0.39, y: 1.00), control2: CGPoint(x: 0.22, y: 0.93), end: CGPoint(x: 0.16, y: 0.86)),
                    .init(control1: CGPoint(x: 0.05, y: 0.73), control2: CGPoint(x: -0.03, y: 0.60), end: CGPoint(x: 0.00, y: 0.48)),
                    .init(control1: CGPoint(x: 0.03, y: 0.20), control2: CGPoint(x: 0.24, y: 0.02), end: CGPoint(x: 0.49, y: 0.02))
                ]
            )
        }
    }
}
