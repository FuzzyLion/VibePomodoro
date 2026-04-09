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
            BubbleGlassShell(phase: renderState.phase, sphereSize: sphereSize)
            BubbleAnimatedSurfaceLayer(renderState: renderState, waveClock: waveClock)
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

        return (accumulatedWaveTime + animatedDuration) * 1.15 * .pi
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
        let glowExpansion = 0.52 + (sin(wavePhase * 0.75) + 1) * 0.24

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
                            Color(red: 0.56, green: 0.57, blue: 0.60),
                            Color(red: 0.46, green: 0.47, blue: 0.50),
                            Color(red: 0.31, green: 0.32, blue: 0.35)
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
                                    Color.white.opacity(0.30),
                                    Color.white.opacity(0.09),
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
                        .foregroundStyle(Color.white.opacity(0.10))
                        .blur(radius: 0.32)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 14)
                        }
                }
                .drawingGroup(opaque: false, colorMode: .linear)
        } else {
            textLabel
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98),
                            Color.white.opacity(0.84),
                            renderState.phase.glassTint.opacity(0.38)
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
                                    Color.white.opacity(0.34),
                                    Color.white.opacity(0.10),
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
                        .foregroundStyle(Color.white.opacity(0.12))
                        .blur(radius: 0.45)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 14)
                        }
                }
                .drawingGroup(opaque: false, colorMode: .linear)
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

private struct BubbleGlassShell: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let sphereSize: CGFloat

    var body: some View {
        let isDark = colorScheme == .dark
        let bubbleShape = BubbleGlassShape(phase: phase)

        ZStack {
            if isDark {
                bubbleShape
                    .fill(.thinMaterial)

                bubbleShape
                    .fill(Color.white.opacity(0.045))

                bubbleShape
                    .fill(phase.glassTint.opacity(0.12))

                bubbleShape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.21),
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
                                Color.clear,
                                Color.white.opacity(0.018),
                                Color.black.opacity(0.024)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                bubbleShape
                    .stroke(Color.white.opacity(0.42), lineWidth: 1)

                bubbleShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.34),
                                Color.white.opacity(0.06),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.15
                    )
                    .blur(radius: 0.35)

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask {
                        bubbleShape
                            .stroke(lineWidth: 10)
                    }

                Ellipse()
                    .fill(phase.shadowColor.opacity(0.07))
                    .frame(width: sphereSize * 0.34, height: sphereSize * 0.06)
                    .blur(radius: 10)
                    .offset(y: sphereSize * 0.38)
                    .mask(bubbleShape)
            } else {
                bubbleShape
                    .fill(Color(red: 0.90, green: 0.91, blue: 0.93).opacity(0.235))

                bubbleShape
                    .fill(Color.white.opacity(0.052))

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color(red: 0.92, green: 0.93, blue: 0.95).opacity(0.17),
                                phase.tintColor.opacity(0.016)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                bubbleShape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.23),
                                Color.white.opacity(0.085),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: sphereSize * 0.76
                        )
                    )

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.085),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: sphereSize * 0.24
                        )
                    )
                    .frame(width: sphereSize * 0.40, height: sphereSize * 0.20)
                    .blur(radius: 14)
                    .offset(x: -sphereSize * 0.16, y: -sphereSize * 0.30)
                    .mask(bubbleShape)

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.90, green: 0.91, blue: 0.93).opacity(0.105),
                                Color.white.opacity(0.030),
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                bubbleShape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.88, green: 0.89, blue: 0.91).opacity(0.09),
                                phase.tintColor.opacity(0.020),
                                Color.clear
                            ],
                            center: .bottom,
                            startRadius: sphereSize * 0.10,
                            endRadius: sphereSize * 0.54
                        )
                    )

                bubbleShape
                    .stroke(Color.white.opacity(0.72), lineWidth: 1.15)

                bubbleShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.54),
                                Color(red: 0.84, green: 0.86, blue: 0.90).opacity(0.20),
                                Color.black.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
                    .blur(radius: 0.25)

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask {
                        bubbleShape
                            .stroke(lineWidth: 10)
                    }

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.022)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask {
                        bubbleShape
                            .stroke(lineWidth: 12)
                    }

                Ellipse()
                    .fill(Color.white.opacity(0.018))
                    .frame(width: sphereSize * 0.36, height: sphereSize * 0.07)
                    .blur(radius: 11)
                    .offset(y: sphereSize * 0.34)
                    .mask(bubbleShape)
            }
        }
        .drawingGroup(opaque: false, colorMode: .linear)
        .shadow(color: phase.shadowColor.opacity(isDark ? 0.052 : 0.005), radius: isDark ? 18 : 8, y: isDark ? 9 : 3)
        .shadow(color: Color.white.opacity(isDark ? 0.06 : 0.10), radius: isDark ? 8 : 9, y: -3)
        .allowsHitTesting(false)
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
            to: CGPoint(x: minX + width * 0.50, y: minY + height * 0.99),
            control1: CGPoint(x: minX + width * 0.75, y: minY + height * 0.98),
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
            to: CGPoint(x: minX + width * 0.53, y: minY + height * 0.98),
            control1: CGPoint(x: minX + width * 0.95, y: minY + height * 0.83),
            control2: CGPoint(x: minX + width * 0.72, y: minY + height * 0.90)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.15, y: minY + height * 0.77),
            control1: CGPoint(x: minX + width * 0.41, y: minY + height * 1.00),
            control2: CGPoint(x: minX + width * 0.26, y: minY + height * 0.88)
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
            to: CGPoint(x: minX + width * 0.53, y: minY + height * 0.98),
            control1: CGPoint(x: minX + width * 0.77, y: minY + height * 0.89),
            control2: CGPoint(x: minX + width * 0.64, y: minY + height * 0.98)
        )
        path.addCurve(
            to: CGPoint(x: minX + width * 0.16, y: minY + height * 0.82),
            control1: CGPoint(x: minX + width * 0.39, y: minY + height * 0.99),
            control2: CGPoint(x: minX + width * 0.22, y: minY + height * 0.91)
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

        ZStack {
            bubbleShape
                .stroke(
                    phase.shadowColor.opacity(
                        clampedOpacity(
                            colorScheme == .dark
                                ? 0.045 + glow * 0.009
                                : 0.018 + glow * 0.005
                        )
                    ),
                    lineWidth: colorScheme == .dark ? 13 : 11
                )
                .blur(radius: colorScheme == .dark ? 7.5 : 5.5)
                .scaleEffect(colorScheme == .dark ? 1.026 : 1.02)

            bubbleShape
                .stroke(
                    Color.white.opacity(
                        clampedOpacity(
                            colorScheme == .dark
                                ? 0.020 + glow * 0.003
                                : 0.020 + glow * 0.004
                        )
                    ),
                    lineWidth: colorScheme == .dark ? 4.5 : 3.5
                )
                .blur(radius: colorScheme == .dark ? 3.2 : 3.5)
                .scaleEffect(colorScheme == .dark ? 1.012 : 1.01)
                .offset(y: colorScheme == .dark ? -1 : -2)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            phase.shadowColor.opacity(
                                clampedOpacity(
                                    colorScheme == .dark
                                        ? 0.08 + glow * 0.05
                                        : 0.08 + glow * 0.04
                                )
                            ),
                            phase.shadowColor.opacity(
                                clampedOpacity(
                                    colorScheme == .dark
                                        ? 0.024 + glow * 0.018
                                        : 0.024 + glow * 0.015
                                )
                            ),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 100 + glow * 24
                    )
                )
                .frame(width: 168 + glow * 28, height: 38 + glow * 7)
                .blur(radius: colorScheme == .dark ? 16 + glow * 5 : 16 + glow * 4)
                .offset(y: 126)

            Ellipse()
                .fill(
                    Color.white.opacity(
                        clampedOpacity(
                            colorScheme == .dark
                                ? 0.06 + glow * 0.02
                                : 0.04 + glow * 0.015
                        )
                    )
                )
                .frame(width: 138 + glow * 10, height: 18 + glow * 3)
                .blur(radius: colorScheme == .dark ? 9 : 8)
                .offset(y: 118)
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
        let normalizedProgress = max(0, min(progress, 1))
        let baseFillRatio = min(0.985, 0.10 + pow(normalizedProgress, 1.18) * 0.88)
        let terminalBoost = isFinalDisplayedSecond ? 0.048 : 0
        let visualFillRatio = min(1.035, baseFillRatio + terminalBoost)
        let amplitude = 4.2 + glowExpansion * 2.4

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

            if colorScheme == .dark {
                var waterlineGlowContext = context
                waterlineGlowContext.addFilter(.blur(radius: 12))
                waterlineGlowContext.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: sphereRect.minX + sphereRect.width * 0.10,
                            y: waterlineY - 6,
                            width: sphereRect.width * 0.80,
                            height: 14
                        )
                    ),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.16),
                            Color.white.opacity(0.08),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 10),
                        endPoint: CGPoint(x: sphereRect.midX, y: waterlineY + 10)
                    )
                )
            } else {
                var waterlineGlowContext = context
                waterlineGlowContext.addFilter(.blur(radius: 9))
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
                Color.white.opacity(0.12),
                Color.white.opacity(0.05),
                Color.clear
            ]
        }

        return [
            Color.white.opacity(0.16),
            phase.tintColor.opacity(0.16),
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
            let primaryAngle = Double(relativeX) * Double.pi * 2.1 + phase
            let secondaryAngle = Double(relativeX) * Double.pi * 4.3 + phase * 0.72
            let wave = CGFloat(sin(primaryAngle)) * mainAmplitude
            let secondaryWave = CGFloat(sin(secondaryAngle)) * mainAmplitude * 0.34
            let y = baseY + wave + secondaryWave
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: endX, y: rect.height))
        path.closeSubpath()
        return path
    }
}
