import SwiftUI

struct BubbleTimerView: View {
    let renderState: BubbleRenderState
    var showsForegroundContent: Bool = true
    var controlVisibility: Double = 1
    var controlIsInteractive: Bool = true
    let action: () -> Void

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
                BubbleForegroundContent(
                    renderState: renderState,
                    controlVisibility: controlVisibility,
                    controlIsInteractive: controlIsInteractive,
                    action: action
                )
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
            .mask(BubbleGlassShape())
        }
    }
}

private struct BubbleForegroundContent: View {
    let renderState: BubbleRenderState
    let controlVisibility: Double
    let controlIsInteractive: Bool
    let action: () -> Void

    var body: some View {
        BubbleTimerDigitsView(renderState: renderState)
            .frame(maxWidth: 208)
            .offset(y: -10)
            .overlay(alignment: .center) {
                BubbleControlButton(actionTitle: renderState.actionTitle, action: action)
                    .offset(y: 58)
                    .opacity(controlVisibility)
                    .allowsHitTesting(controlIsInteractive)
            }
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

private struct BubbleControlButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let actionTitle: String
    let action: () -> Void

    var body: some View {
        let symbol = Image(systemName: controlIconName)
            .font(.system(size: 13, weight: .heavy))

        Button(action: action) {
            symbol
                .foregroundStyle(iconForegroundStyle)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.05 : 0),
                    radius: colorScheme == .dark ? 4 : 0,
                    y: colorScheme == .dark ? 1.5 : 0
                )
                .frame(width: 30, height: 30)
                .background {
                    GlassCircleShell(
                        tint: Color.white.opacity(colorScheme == .dark ? 0.03 : 0.03)
                    )
                }
        }
        .buttonStyle(.plain)
        .shadow(
            color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.06),
            radius: colorScheme == .dark ? 3 : 4,
            y: -1
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.06 : 0.03),
            radius: colorScheme == .dark ? 4 : 5,
            y: colorScheme == .dark ? 1.5 : 2
        )
    }

    private var controlIconName: String {
        switch actionTitle {
        case "Pause":
            return "pause.fill"
        case "Resume", "Start", "Start Again":
            return "play.fill"
        default:
            return "play.fill"
        }
    }

    private var iconForegroundStyle: AnyShapeStyle {
        if colorScheme == .light {
            return AnyShapeStyle(Color(red: 0.36, green: 0.37, blue: 0.40))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color.white.opacity(0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct GlassCircleShell: View {
    @Environment(\.colorScheme) private var colorScheme

    let tint: Color
    var material: Material = .thinMaterial
    var darkStrokeOpacity: Double = 0.38
    var lightStrokeOpacity: Double = 0.44

    var body: some View {
        Circle()
            .fill(material)
            .overlay {
                Circle()
                    .fill(colorScheme == .dark ? tint.opacity(0.70) : tint)
            }
            .overlay {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.03),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay {
                Circle()
                    .stroke(
                        Color.white.opacity(
                            colorScheme == .dark ? darkStrokeOpacity * 0.84 : lightStrokeOpacity
                        ),
                        lineWidth: 0.85
                    )
            }
    }
}

private struct BubbleGlassShell: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let sphereSize: CGFloat

    var body: some View {
        let isDark = colorScheme == .dark

        ZStack {
            if isDark {
                BubbleGlassShape()
                    .fill(.thinMaterial)

                BubbleGlassShape()
                    .fill(Color.white.opacity(0.045))

                BubbleGlassShape()
                    .fill(phase.glassTint.opacity(0.12))

                BubbleGlassShape()
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

                BubbleGlassShape()
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

                BubbleGlassShape()
                    .stroke(Color.white.opacity(0.42), lineWidth: 1)

                BubbleGlassShape()
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

                BubbleGlassShape()
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
                        BubbleGlassShape()
                            .stroke(lineWidth: 10)
                    }

                Ellipse()
                    .fill(phase.shadowColor.opacity(0.07))
                    .frame(width: sphereSize * 0.34, height: sphereSize * 0.06)
                    .blur(radius: 10)
                    .offset(y: sphereSize * 0.38)
                    .mask(BubbleGlassShape())
            } else {
                BubbleGlassShape()
                    .fill(Color(red: 0.90, green: 0.91, blue: 0.93).opacity(0.235))

                BubbleGlassShape()
                    .fill(Color.white.opacity(0.052))

                BubbleGlassShape()
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

                BubbleGlassShape()
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
                    .mask(BubbleGlassShape())

                BubbleGlassShape()
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

                BubbleGlassShape()
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

                BubbleGlassShape()
                    .stroke(Color.white.opacity(0.72), lineWidth: 1.15)

                BubbleGlassShape()
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

                BubbleGlassShape()
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
                        BubbleGlassShape()
                            .stroke(lineWidth: 10)
                    }

                BubbleGlassShape()
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
                        BubbleGlassShape()
                            .stroke(lineWidth: 12)
                    }

                Ellipse()
                    .fill(Color.white.opacity(0.018))
                    .frame(width: sphereSize * 0.36, height: sphereSize * 0.07)
                    .blur(radius: 11)
                    .offset(y: sphereSize * 0.34)
                    .mask(BubbleGlassShape())
            }
        }
        .drawingGroup(opaque: false, colorMode: .linear)
        .shadow(color: phase.shadowColor.opacity(isDark ? 0.052 : 0.005), radius: isDark ? 18 : 8, y: isDark ? 9 : 3)
        .shadow(color: Color.white.opacity(isDark ? 0.06 : 0.10), radius: isDark ? 8 : 9, y: -3)
        .allowsHitTesting(false)
    }
}

private struct BubbleGlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        guard rect.width.isFinite,
              rect.height.isFinite,
              rect.width > 1,
              rect.height > 1 else {
            return Path()
        }

        return Path(ellipseIn: rect.insetBy(dx: 0.9, dy: 0.9))
    }
}

private struct BubbleGlowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let glowExpansion: Double

    var body: some View {
        let glow = glowExpansion.isFinite ? max(0, glowExpansion) : 0

        ZStack {
            BubbleGlassShape()
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

            BubbleGlassShape()
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
            let spherePath = BubbleGlassShape().path(in: sphereRect)
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
