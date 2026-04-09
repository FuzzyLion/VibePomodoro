import SwiftUI

struct BubbleTimerView: View {
    let renderState: BubbleRenderState
    var showsForegroundContent: Bool = true

    @State private var accumulatedWaveTime: TimeInterval = 0
    @State private var waveAnimationStart: Date?

    var body: some View {
        let sphereSize = FocusScreenLayout.bubbleDiameter
        let waveClock = BubbleWaveClock(
            accumulatedWaveTime: accumulatedWaveTime,
            waveAnimationStart: waveAnimationStart,
            isAnimating: renderState.isAnimating
        )

        ZStack {
            BubbleGlassBackdrop(phase: renderState.phase, sphereSize: sphereSize)
            BubbleAnimatedSurfaceLayer(renderState: renderState, waveClock: waveClock)
            BubbleGlassRimOverlay(phase: renderState.phase, sphereSize: sphereSize)
            if showsForegroundContent {
                BubbleForegroundContent(renderState: renderState)
            }
        }
        .frame(width: sphereSize, height: sphereSize)
        .onAppear {
            if renderState.isAnimating && waveAnimationStart == nil {
                waveAnimationStart = .now
            }
        }
        .onChange(of: renderState.isAnimating) { _, newValue in
            let now = Date.now
            if newValue {
                waveAnimationStart = now
            } else if let waveAnimationStart {
                accumulatedWaveTime += now.timeIntervalSince(waveAnimationStart)
                self.waveAnimationStart = nil
            }
        }
        .onChange(of: renderState.phase) { _, _ in
            accumulatedWaveTime = 0
            waveAnimationStart = renderState.isAnimating ? .now : nil
        }
    }
}

private struct BubbleWaveClock {
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

private struct BubbleAnimatedSurfaceLayer: View {
    let renderState: BubbleRenderState
    let waveClock: BubbleWaveClock

    var body: some View {
        Group {
            if renderState.isAnimating {
                TimelineView(.periodic(from: .now, by: renderState.animationRefreshInterval)) { context in
                    animatedSurface(at: context.date)
                }
            } else {
                animatedSurface(at: .now)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func animatedSurface(at date: Date) -> some View {
        let wavePhase = waveClock.phase(at: date)
        let glowExpansion = 0.44 + (sin(wavePhase * 0.42) + 1) * 0.16

        ZStack {
            BubbleGlowBackdrop(phase: renderState.phase, glowExpansion: glowExpansion)

            BubbleLiquidLayer(
                phase: renderState.phase,
                progress: renderState.progress(at: date),
                isFinalDisplayedSecond: renderState.isFinalDisplayedSecond(at: date),
                wavePhase: wavePhase,
                glowExpansion: glowExpansion
            )
            .mask(BubbleGlassShape(phase: renderState.phase))
        }
    }
}

private struct BubbleForegroundContent: View {
    let renderState: BubbleRenderState

    var body: some View {
        BubbleTimerDigitsView(renderState: renderState)
            .frame(maxWidth: 208)
    }
}

private struct BubbleTimerDigitsView: View {
    @Environment(\.colorScheme) private var colorScheme

    let renderState: BubbleRenderState

    var body: some View {
        Group {
            if renderState.shouldTickSeconds {
                TimelineView(.periodic(from: .now, by: renderState.textRefreshInterval)) { context in
                    digits(for: renderState.timeText(at: context.date))
                }
            } else {
                digits(for: renderState.timeText(at: .now))
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func digits(for timeText: String) -> some View {
        let display = BubbleTimeDisplay(text: timeText)
        let textLabel = BubbleTimerTextLabel(display: display)
            .padding(.horizontal, 2)
            .padding(.vertical, 6)

        if colorScheme == .light {
            textLabel
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.47, green: 0.48, blue: 0.51),
                            Color(red: 0.36, green: 0.37, blue: 0.40),
                            Color(red: 0.24, green: 0.25, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    textLabel
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(textLabel)
                }
                .overlay {
                    textLabel
                        .foregroundStyle(Color.white.opacity(0.06))
                        .blur(radius: 0.24)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 10)
                        }
                }
        } else {
            textLabel
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98),
                            Color.white.opacity(0.88),
                            renderState.phase.glassTint.opacity(0.26)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    textLabel
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.24),
                                    Color.white.opacity(0.07),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(textLabel)
                }
                .overlay {
                    textLabel
                        .foregroundStyle(Color.white.opacity(0.08))
                        .blur(radius: 0.36)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 10)
                        }
                }
        }
    }
}

private struct BubbleTimeDisplay: Equatable {
    let minutes: String
    let seconds: String

    init(text: String) {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false)
        minutes = parts.indices.contains(0) ? String(parts[0]) : "00"
        seconds = parts.indices.contains(1) ? String(parts[1]) : "00"
    }
}

private struct BubbleTimerTextLabel: View {
    let display: BubbleTimeDisplay

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            digitGroup(display.minutes)

            Text(":")
                .font(.system(size: 43, weight: .bold, design: .default))
                .fontWidth(.expanded)
                .baselineOffset(1)
                .padding(.horizontal, 2)
                .opacity(0.96)

            digitGroup(display.seconds)
        }
        .monospacedDigit()
        .tracking(-1.1)
        .minimumScaleFactor(0.72)
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func digitGroup(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 58, weight: .heavy, design: .default))
            .fontWidth(.expanded)
    }
}

private struct BubbleGlassBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let sphereSize: CGFloat

    var body: some View {
        let isDark = colorScheme == .dark
        let bubbleShape = BubbleGlassShape(phase: phase)
        let profile = phase.bubbleShellProfile(for: sphereSize)

        ZStack {
            if isDark {
                bubbleShape
                    .fill(.thinMaterial)

                bubbleShape
                    .fill(Color.white.opacity(0.028))

                bubbleShape
                    .fill(phase.glassTint.opacity(0.11))

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.clear,
                                Color.black.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                bubbleShape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.09),
                                Color.clear
                            ],
                            center: .top,
                            startRadius: 0,
                            endRadius: sphereSize * 0.44
                        )
                    )

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.07)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                bubbleShape
                    .fill(Color(red: 0.90, green: 0.91, blue: 0.93).opacity(0.215))

                bubbleShape
                    .fill(Color.white.opacity(0.048))

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color(red: 0.92, green: 0.93, blue: 0.95).opacity(0.12),
                                phase.tintColor.opacity(0.020)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                bubbleShape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: sphereSize * 0.62
                        )
                    )

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.clear,
                                Color.black.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                bubbleShape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.88, green: 0.89, blue: 0.91).opacity(0.06),
                                phase.tintColor.opacity(0.028),
                                Color.clear
                            ],
                            center: .bottom,
                            startRadius: sphereSize * 0.10,
                            endRadius: sphereSize * 0.50
                        )
                    )
            }

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            phase.tintColor.opacity(isDark ? 0.08 : 0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: profile.lowerCausticSize.width * 0.48
                    )
                )
                .frame(width: profile.lowerCausticSize.width, height: profile.lowerCausticSize.height)
                .blur(radius: isDark ? 16 : 12)
                .offset(profile.lowerCausticOffset)
                .mask(bubbleShape)
        }
        .shadow(color: phase.shadowColor.opacity(isDark ? 0.045 : 0.01), radius: isDark ? 18 : 8, y: isDark ? 9 : 3)
        .shadow(color: Color.white.opacity(isDark ? 0.03 : 0.08), radius: isDark ? 7 : 8, y: -3)
        .allowsHitTesting(false)
    }
}

private struct BubbleGlassRimOverlay: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let sphereSize: CGFloat

    var body: some View {
        let isDark = colorScheme == .dark
        let bubbleShape = BubbleGlassShape(phase: phase)
        let profile = phase.bubbleShellProfile(for: sphereSize)

        ZStack {
            bubbleShape
                .stroke(Color.white.opacity(isDark ? 0.30 : 0.68), lineWidth: isDark ? 1.0 : 1.15)

            bubbleShape
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.26 : 0.40),
                            Color.white.opacity(isDark ? 0.06 : 0.14),
                            Color.black.opacity(isDark ? 0.12 : 0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isDark ? 1.25 : 1.35
                )
                .blur(radius: isDark ? 0.26 : 0.22)

            bubbleShape
                .stroke(Color.black.opacity(isDark ? 0.26 : 0.06), lineWidth: isDark ? 0.72 : 0.58)
                .blur(radius: isDark ? 0.24 : 0.16)
                .offset(y: isDark ? 0.9 : 0.7)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.20 : 0.28),
                            Color.white.opacity(isDark ? 0.05 : 0.10),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: profile.upperSpecularSize.width, height: profile.upperSpecularSize.height)
                .blur(radius: isDark ? 7 : 9)
                .rotationEffect(.degrees(profile.upperSpecularRotation))
                .offset(profile.upperSpecularOffset)
                .mask(bubbleShape)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.11 : 0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: profile.shoulderSpecularSize.width * 0.52
                    )
                )
                .frame(width: profile.shoulderSpecularSize.width, height: profile.shoulderSpecularSize.height)
                .blur(radius: isDark ? 6 : 8)
                .rotationEffect(.degrees(profile.shoulderSpecularRotation))
                .offset(profile.shoulderSpecularOffset)
                .mask(bubbleShape)

            bubbleShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.12 : 0.16),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask {
                    bubbleShape
                        .stroke(lineWidth: isDark ? 8 : 10)
                }

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.12 : 0.10),
                            phase.tintColor.opacity(isDark ? 0.10 : 0.06),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: profile.lowerCausticSize.width, height: profile.lowerCausticSize.height)
                .blur(radius: isDark ? 10 : 9)
                .offset(profile.lowerCausticOffset)
                .mask(bubbleShape)
        }
        .allowsHitTesting(false)
    }
}

private struct BubbleShellProfile {
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
    let waveAmplitudeBase: Double
    let waveAmplitudeRange: Double
}

private extension SessionPhase {
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
                waveAmplitudeBase: 2.55,
                waveAmplitudeRange: 1.08
            )
        }
    }
}

private struct BubbleGlassShape: Shape {
    let phase: SessionPhase

    func path(in rect: CGRect) -> Path {
        guard rect.width.isFinite,
              rect.height.isFinite,
              rect.width > 1,
              rect.height > 1 else {
            return Path()
        }

        let insetRect = rect.insetBy(dx: 0.9, dy: 0.9)

        switch phase {
        case .focus:
            return focusPath(in: insetRect)
        case .shortBreak:
            return shortBreakPath(in: insetRect)
        case .longBreak:
            return longBreakPath(in: insetRect)
        }
    }

    private func focusPath(in rect: CGRect) -> Path {
        let minX = rect.minX
        let minY = rect.minY
        let width = rect.width
        let height = rect.height

        var path = Path()
        path.move(to: CGPoint(x: minX + width * 0.49, y: minY + height * 0.01))
        path.addCurve(
            to: CGPoint(x: minX + width * 0.86, y: minY + height * 0.08),
            control1: CGPoint(x: minX + width * 0.68, y: minY - height * 0.01),
            control2: CGPoint(x: minX + width * 0.79, y: minY + height * 0.00)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.99, y: minY + height * 0.48),
            control1: CGPoint(x: minX + width * 0.96, y: minY + height * 0.18),
            control2: CGPoint(x: minX + width * 1.01, y: minY + height * 0.31)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.86, y: minY + height * 0.92),
            control1: CGPoint(x: minX + width * 0.99, y: minY + height * 0.73),
            control2: CGPoint(x: minX + width * 0.96, y: minY + height * 0.87)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.50, y: minY + height * 1.00),
            control1: CGPoint(x: minX + width * 0.75, y: minY + height * 0.99),
            control2: CGPoint(x: minX + width * 0.61, y: minY + height * 1.00)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.13, y: minY + height * 0.92),
            control1: CGPoint(x: minX + width * 0.38, y: minY + height * 0.99),
            control2: CGPoint(x: minX + width * 0.25, y: minY + height * 0.98)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.01, y: minY + height * 0.49),
            control1: CGPoint(x: minX + width * 0.03, y: minY + height * 0.87),
            control2: CGPoint(x: minX - width * 0.01, y: minY + height * 0.71)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.10, y: minY + height * 0.09),
            control1: CGPoint(x: minX + width * 0.01, y: minY + height * 0.28),
            control2: CGPoint(x: minX + width * 0.01, y: minY + height * 0.15)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.49, y: minY + height * 0.01),
            control1: CGPoint(x: minX + width * 0.20, y: minY + height * 0.00),
            control2: CGPoint(x: minX + width * 0.33, y: minY - height * 0.01)
        )
        path.closeSubpath()
        return path
    }

    private func shortBreakPath(in rect: CGRect) -> Path {
        let minX = rect.minX
        let minY = rect.minY
        let width = rect.width
        let height = rect.height

        var path = Path()
        path.move(to: CGPoint(x: minX + width * 0.49, y: minY + height * 0.02))
        path.addCurve(
            to: CGPoint(x: minX + width * 0.81, y: minY + height * 0.12),
            control1: CGPoint(x: minX + width * 0.63, y: minY - height * 0.01),
            control2: CGPoint(x: minX + width * 0.75, y: minY + height * 0.04)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.93, y: minY + height * 0.34),
            control1: CGPoint(x: minX + width * 0.88, y: minY + height * 0.18),
            control2: CGPoint(x: minX + width * 0.94, y: minY + height * 0.24)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.99, y: minY + height * 0.67),
            control1: CGPoint(x: minX + width * 0.97, y: minY + height * 0.46),
            control2: CGPoint(x: minX + width * 1.01, y: minY + height * 0.57)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.53, y: minY + height * 1.00),
            control1: CGPoint(x: minX + width * 0.95, y: minY + height * 0.85),
            control2: CGPoint(x: minX + width * 0.72, y: minY + height * 0.94)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.15, y: minY + height * 0.81),
            control1: CGPoint(x: minX + width * 0.40, y: minY + height * 1.01),
            control2: CGPoint(x: minX + width * 0.25, y: minY + height * 0.92)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.00, y: minY + height * 0.52),
            control1: CGPoint(x: minX + width * 0.05, y: minY + height * 0.69),
            control2: CGPoint(x: minX - width * 0.03, y: minY + height * 0.61)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.05, y: minY + height * 0.20),
            control1: CGPoint(x: minX + width * 0.01, y: minY + height * 0.41),
            control2: CGPoint(x: minX - width * 0.01, y: minY + height * 0.30)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.49, y: minY + height * 0.02),
            control1: CGPoint(x: minX + width * 0.11, y: minY + height * 0.08),
            control2: CGPoint(x: minX + width * 0.28, y: minY + height * 0.02)
        )
        path.closeSubpath()
        return path
    }

    private func longBreakPath(in rect: CGRect) -> Path {
        let minX = rect.minX
        let minY = rect.minY
        let width = rect.width
        let height = rect.height

        var path = Path()
        path.move(to: CGPoint(x: minX + width * 0.49, y: minY + height * 0.02))
        path.addCurve(
            to: CGPoint(x: minX + width * 0.84, y: minY + height * 0.08),
            control1: CGPoint(x: minX + width * 0.66, y: minY + height * 0.00),
            control2: CGPoint(x: minX + width * 0.78, y: minY + height * 0.01)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.94, y: minY + height * 0.28),
            control1: CGPoint(x: minX + width * 0.90, y: minY + height * 0.13),
            control2: CGPoint(x: minX + width * 0.93, y: minY + height * 0.18)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.99, y: minY + height * 0.60),
            control1: CGPoint(x: minX + width * 0.98, y: minY + height * 0.38),
            control2: CGPoint(x: minX + width * 1.01, y: minY + height * 0.49)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.86, y: minY + height * 0.84),
            control1: CGPoint(x: minX + width * 0.98, y: minY + height * 0.74),
            control2: CGPoint(x: minX + width * 0.92, y: minY + height * 0.81)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.53, y: minY + height * 1.00),
            control1: CGPoint(x: minX + width * 0.77, y: minY + height * 0.91),
            control2: CGPoint(x: minX + width * 0.64, y: minY + height * 1.00)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.16, y: minY + height * 0.86),
            control1: CGPoint(x: minX + width * 0.39, y: minY + height * 1.00),
            control2: CGPoint(x: minX + width * 0.22, y: minY + height * 0.93)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.00, y: minY + height * 0.48),
            control1: CGPoint(x: minX + width * 0.05, y: minY + height * 0.73),
            control2: CGPoint(x: minX - width * 0.03, y: minY + height * 0.60)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.49, y: minY + height * 0.02),
            control1: CGPoint(x: minX + width * 0.03, y: minY + height * 0.20),
            control2: CGPoint(x: minX + width * 0.24, y: minY + height * 0.02)
        )
        path.closeSubpath()
        return path
    }
}

private struct BubbleGlowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let glowExpansion: Double

    var body: some View {
        let glow = glowExpansion.isFinite ? max(0, glowExpansion) : 0
        let bubbleShape = BubbleGlassShape(phase: phase)
        let profile = phase.bubbleShellProfile(for: FocusScreenLayout.bubbleDiameter)

        ZStack {
            bubbleShape
                .stroke(
                    phase.shadowColor.opacity(
                        clampedOpacity(
                            colorScheme == .dark
                                ? 0.034 + glow * 0.008
                                : 0.015 + glow * 0.004
                        )
                    ),
                    lineWidth: colorScheme == .dark ? 10.5 : 8.5
                )
                .blur(radius: colorScheme == .dark ? 6.2 : 4.8)
                .scaleEffect(colorScheme == .dark ? 1.018 : 1.014)

            bubbleShape
                .stroke(
                    Color.white.opacity(
                        clampedOpacity(
                            colorScheme == .dark
                                ? 0.015 + glow * 0.002
                                : 0.015 + glow * 0.003
                        )
                    ),
                    lineWidth: colorScheme == .dark ? 3.8 : 3.0
                )
                .blur(radius: colorScheme == .dark ? 2.8 : 3.0)
                .scaleEffect(colorScheme == .dark ? 1.009 : 1.007)
                .offset(y: colorScheme == .dark ? -0.6 : -1.2)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            phase.shadowColor.opacity(
                                clampedOpacity(
                                    colorScheme == .dark
                                        ? 0.07 + glow * 0.04
                                        : 0.06 + glow * 0.03
                                )
                            ),
                            phase.shadowColor.opacity(
                                clampedOpacity(
                                    colorScheme == .dark
                                        ? 0.022 + glow * 0.014
                                        : 0.018 + glow * 0.011
                                )
                            ),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: profile.outerGlowSize.width * 0.62 + glow * 16
                    )
                )
                .frame(
                    width: profile.outerGlowSize.width + glow * 18,
                    height: profile.outerGlowSize.height + glow * 6
                )
                .blur(radius: colorScheme == .dark ? 15 + glow * 4 : 13 + glow * 3)
                .offset(profile.outerGlowOffset)

            Ellipse()
                .fill(
                    Color.white.opacity(
                        clampedOpacity(
                            colorScheme == .dark
                                ? 0.045 + glow * 0.015
                                : 0.028 + glow * 0.010
                        )
                    )
                )
                .frame(
                    width: profile.outerGlowSize.width * 0.78 + glow * 8,
                    height: profile.outerGlowSize.height * 0.44 + glow * 2
                )
                .blur(radius: colorScheme == .dark ? 8 : 7)
                .offset(x: profile.outerGlowOffset.width, y: profile.outerGlowOffset.height - 8)
        }
    }

    private func clampedOpacity(_ value: Double) -> Double {
        min(1, max(0, value.isFinite ? value : 0))
    }
}

private struct BubbleLiquidLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let progress: Double
    let isFinalDisplayedSecond: Bool
    let wavePhase: Double
    let glowExpansion: Double

    var body: some View {
        let profile = phase.bubbleShellProfile(for: FocusScreenLayout.bubbleDiameter)
        let normalizedProgress = max(0, min(progress, 1))
        let baseFillRatio = min(0.987, 0.12 + pow(normalizedProgress, 1.22) * 0.86)
        let terminalBoost = isFinalDisplayedSecond ? 0.052 : 0
        let visualFillRatio = min(1.035, baseFillRatio + terminalBoost)
        let amplitude = profile.waveAmplitudeBase + glowExpansion * profile.waveAmplitudeRange

        Canvas(rendersAsynchronously: true) { context, canvasSize in
            guard canvasSize.width.isFinite,
                  canvasSize.height.isFinite,
                  canvasSize.width > 0,
                  canvasSize.height > 0 else {
                return
            }

            let sphereRect = CGRect(origin: .zero, size: canvasSize)
            let spherePath = BubbleGlassShape(phase: phase).path(in: sphereRect)
            let waterlineY = sphereRect.maxY - sphereRect.height * CGFloat(visualFillRatio)

            guard waterlineY.isFinite else { return }

            context.clip(to: spherePath)

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
                fillRatio: min(1, visualFillRatio + 0.012),
                phase: wavePhase * 1.08 + .pi / 5,
                amplitude: amplitude * 0.55
            ).path(in: sphereRect)

            context.fill(
                secondaryLiquidPath,
                with: .linearGradient(
                    Gradient(colors: secondaryLiquidGradientColors),
                    startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 14),
                    endPoint: CGPoint(x: sphereRect.midX, y: sphereRect.maxY)
                )
            )

            var depthPoolContext = context
            depthPoolContext.clip(to: secondaryLiquidPath)
            depthPoolContext.addFilter(.blur(radius: colorScheme == .dark ? 14 : 11))
            depthPoolContext.fill(
                Path(
                    ellipseIn: CGRect(
                        x: sphereRect.midX - (profile.depthPoolSize.width / 2) + profile.depthPoolOffset.width,
                        y: sphereRect.midY - (profile.depthPoolSize.height / 2) + profile.depthPoolOffset.height,
                        width: profile.depthPoolSize.width,
                        height: profile.depthPoolSize.height
                    )
                ),
                with: .radialGradient(
                    Gradient(colors: [
                        phase.shadowColor.opacity(colorScheme == .dark ? 0.34 : 0.18),
                        phase.tintColor.opacity(colorScheme == .dark ? 0.18 : 0.10),
                        Color.clear
                    ]),
                    center: CGPoint(
                        x: sphereRect.midX + profile.depthPoolOffset.width * 0.18,
                        y: sphereRect.maxY - profile.depthPoolSize.height * 0.28
                    ),
                    startRadius: 4,
                    endRadius: profile.depthPoolSize.width * 0.46
                )
            )

            if colorScheme == .dark {
                var waterlineGlowContext = context
                waterlineGlowContext.addFilter(.blur(radius: 10))
                waterlineGlowContext.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: sphereRect.minX + sphereRect.width * 0.11,
                            y: waterlineY - 5,
                            width: sphereRect.width * 0.78,
                            height: 12
                        )
                    ),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.06),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 10),
                        endPoint: CGPoint(x: sphereRect.midX, y: waterlineY + 10)
                    )
                )
            } else {
                var waterlineGlowContext = context
                waterlineGlowContext.addFilter(.blur(radius: 8))
                waterlineGlowContext.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: sphereRect.minX + sphereRect.width * 0.12,
                            y: waterlineY - 5,
                            width: sphereRect.width * 0.76,
                            height: 11
                        )
                    ),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.12),
                            phase.tintColor.opacity(0.06),
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

        let clampedFill = max(0, min(fillRatio, 1))
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
