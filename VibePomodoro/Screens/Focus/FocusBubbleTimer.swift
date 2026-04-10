import SwiftUI

struct BubbleTimerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let renderState: BubbleRenderState
    var showsForegroundContent: Bool = true

    @State private var accumulatedWaveTime: TimeInterval = 0
    @State private var waveAnimationStart: Date?
    @State private var morphSourcePhase: SessionPhase = .focus
    @State private var morphTargetPhase: SessionPhase = .focus
    @State private var morphProgress: CGFloat = 1

    var body: some View {
        let sphereSize = FocusScreenLayout.bubbleDiameter
        let phaseMorph = BubblePhaseMorph(
            sourcePhase: morphSourcePhase,
            targetPhase: morphTargetPhase,
            progress: morphProgress
        )
        let waveClock = BubbleWaveClock(
            accumulatedWaveTime: accumulatedWaveTime,
            waveAnimationStart: waveAnimationStart,
            isAnimating: renderState.isAnimating
        )

        ZStack {
            BubbleGlassBackdrop(phaseMorph: phaseMorph, sphereSize: sphereSize)
            BubbleAnimatedSurfaceLayer(
                renderState: renderState,
                waveClock: waveClock,
                phaseMorph: phaseMorph
            )
            BubbleGlassRimOverlay(phaseMorph: phaseMorph, sphereSize: sphereSize)
            if showsForegroundContent {
                BubbleForegroundContent(renderState: renderState)
            }
        }
        .frame(width: sphereSize, height: sphereSize)
        .onAppear {
            morphSourcePhase = renderState.phase
            morphTargetPhase = renderState.phase
            morphProgress = 1
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
        .onChange(of: renderState.phase) { oldValue, newValue in
            accumulatedWaveTime = 0
            waveAnimationStart = renderState.isAnimating ? .now : nil

            guard oldValue != newValue else { return }

            if reduceMotion {
                morphSourcePhase = newValue
                morphTargetPhase = newValue
                morphProgress = 1
                return
            }

            morphSourcePhase = morphTargetPhase
            morphTargetPhase = newValue
            morphProgress = 0

            withAnimation(FocusScreenLayout.phaseMorphAnimation) {
                morphProgress = 1
            }
        }
    }
}

private struct BubblePhaseMorph: Equatable {
    let sourcePhase: SessionPhase
    let targetPhase: SessionPhase
    let progress: CGFloat

    var clampedProgress: CGFloat {
        max(0, min(progress, 1))
    }

    var shape: BubbleGlassShape {
        BubbleGlassShape(
            sourcePhase: sourcePhase,
            targetPhase: targetPhase,
            progress: clampedProgress
        )
    }

    func shellProfile(for sphereSize: CGFloat) -> BubbleShellProfile {
        BubbleShellProfile.interpolated(
            from: sourcePhase.bubbleShellProfile(for: sphereSize),
            to: targetPhase.bubbleShellProfile(for: sphereSize),
            progress: clampedProgress
        )
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
    let phaseMorph: BubblePhaseMorph

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
        let stepBoundaryCueProgress = renderState.stepBoundaryCueProgress(at: date)

        ZStack {
            BubbleGlowBackdrop(
                phaseMorph: phaseMorph,
                glowExpansion: glowExpansion,
                stepBoundaryCueProgress: stepBoundaryCueProgress
            )

            BubbleLiquidLayer(
                phaseMorph: phaseMorph,
                progress: renderState.progress(at: date),
                isFinalDisplayedSecond: renderState.isFinalDisplayedSecond(at: date),
                wavePhase: wavePhase,
                glowExpansion: glowExpansion,
                stepBoundaryCueProgress: stepBoundaryCueProgress
            )
            .mask(phaseMorph.shape)
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
                    digits(
                        for: renderState.timeText(at: context.date),
                        stepBoundaryCueProgress: renderState.stepBoundaryCueProgress(at: context.date)
                    )
                }
            } else {
                digits(
                    for: renderState.timeText(at: .now),
                    stepBoundaryCueProgress: renderState.stepBoundaryCueProgress(at: .now)
                )
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func digits(for timeText: String, stepBoundaryCueProgress: Double) -> some View {
        let display = BubbleTimeDisplay(text: timeText)
        let textLabel = BubbleTimerTextLabel(display: display)
            .padding(.horizontal, 2)
            .padding(.vertical, 6)
        let cue = max(0, min(stepBoundaryCueProgress, 1))
        let topHighlightOpacity = colorScheme == .light ? 0.18 - cue * 0.08 : 0.24 - cue * 0.10
        let topBlurOpacity = colorScheme == .light ? 0.06 - cue * 0.024 : 0.08 - cue * 0.03

        if colorScheme == .light {
            textLabel
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.47 - cue * 0.03, green: 0.48 - cue * 0.03, blue: 0.51 - cue * 0.01),
                            Color(red: 0.36 - cue * 0.03, green: 0.37 - cue * 0.03, blue: 0.40 - cue * 0.01),
                            Color(red: 0.24 - cue * 0.01, green: 0.25 - cue * 0.01, blue: 0.28 + cue * 0.01)
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
                                    Color.white.opacity(max(0, topHighlightOpacity)),
                                    Color.white.opacity(max(0, topHighlightOpacity * 0.34)),
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
                        .foregroundStyle(Color.white.opacity(max(0, topBlurOpacity)))
                        .blur(radius: 0.24)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 10)
                        }
                }
                .shadow(color: Color.black.opacity(0.05 + cue * 0.015), radius: 7, y: 4)
        } else {
            textLabel
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98 - cue * 0.03),
                            Color.white.opacity(0.88 - cue * 0.05),
                            renderState.phase.glassTint.opacity(0.26 - cue * 0.09)
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
                                    Color.white.opacity(max(0, topHighlightOpacity)),
                                    Color.white.opacity(max(0, topHighlightOpacity * 0.30)),
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
                        .foregroundStyle(Color.white.opacity(max(0, topBlurOpacity)))
                        .blur(radius: 0.36)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 10)
                        }
                }
                .shadow(color: Color.black.opacity(0.08 + cue * 0.02), radius: 10, y: 5)
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

    let phaseMorph: BubblePhaseMorph
    let sphereSize: CGFloat

    var body: some View {
        let isDark = colorScheme == .dark
        let phase = phaseMorph.targetPhase
        let bubbleShape = phaseMorph.shape
        let profile = phaseMorph.shellProfile(for: sphereSize)

        ZStack {
            if isDark {
                bubbleShape
                    .fill(.thinMaterial)

                bubbleShape
                    .fill(Color.white.opacity(0.016))
                    .mask {
                        bubbleShape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.26),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                bubbleShape
                    .fill(phase.glassTint.opacity(0.095))

                bubbleShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.clear,
                                Color.black.opacity(0.09)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .mask {
                        bubbleShape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.42),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                bubbleShape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.045),
                                Color.clear
                            ],
                            center: .top,
                            startRadius: 0,
                            endRadius: sphereSize * 0.30
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

            if !isDark {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: profile.innerLensSize.width, height: profile.innerLensSize.height)
                    .blur(radius: 14)
                    .rotationEffect(.degrees(profile.innerLensRotation))
                    .offset(profile.innerLensOffset)
                    .mask {
                        bubbleShape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.70),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.07),
                                phase.tintColor.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: profile.sideRefractionSize.width, height: profile.sideRefractionSize.height)
                    .blur(radius: 11)
                    .rotationEffect(.degrees(profile.sideRefractionRotation))
                    .offset(profile.sideRefractionOffset)
                    .mask {
                        bubbleShape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.82),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
            }
        }
        .shadow(color: phase.shadowColor.opacity(isDark ? 0.045 : 0.01), radius: isDark ? 18 : 8, y: isDark ? 9 : 3)
        .shadow(color: Color.white.opacity(isDark ? 0.03 : 0.08), radius: isDark ? 7 : 8, y: -3)
        .allowsHitTesting(false)
    }
}

private struct BubbleGlassRimOverlay: View {
    @Environment(\.colorScheme) private var colorScheme

    let phaseMorph: BubblePhaseMorph
    let sphereSize: CGFloat

    var body: some View {
        let isDark = colorScheme == .dark
        let phase = phaseMorph.targetPhase
        let bubbleShape = phaseMorph.shape
        let profile = phaseMorph.shellProfile(for: sphereSize)

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
    let innerLensSize: CGSize
    let innerLensOffset: CGSize
    let innerLensRotation: Double
    let sideRefractionSize: CGSize
    let sideRefractionOffset: CGSize
    let sideRefractionRotation: Double
    let waveAmplitudeBase: Double
    let waveAmplitudeRange: Double
}

private extension BubbleShellProfile {
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

private func interpolate(_ source: CGSize, _ target: CGSize, _ progress: CGFloat) -> CGSize {
    CGSize(
        width: interpolate(source.width, target.width, progress),
        height: interpolate(source.height, target.height, progress)
    )
}

private func interpolate(_ source: CGPoint, _ target: CGPoint, _ progress: CGFloat) -> CGPoint {
    CGPoint(
        x: interpolate(source.x, target.x, progress),
        y: interpolate(source.y, target.y, progress)
    )
}

private func interpolate(_ source: CGFloat, _ target: CGFloat, _ progress: CGFloat) -> CGFloat {
    source + ((target - source) * progress)
}

private func interpolate(_ source: Double, _ target: Double, _ progress: CGFloat) -> Double {
    source + ((target - source) * Double(progress))
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

private struct BubbleGlassShape: Shape {
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

private struct BubbleGlowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    let phaseMorph: BubblePhaseMorph
    let glowExpansion: Double
    let stepBoundaryCueProgress: Double

    var body: some View {
        let glow = glowExpansion.isFinite ? max(0, glowExpansion) : 0
        let cue = stepBoundaryCueProgress.isFinite ? max(0, min(stepBoundaryCueProgress, 1)) : 0
        let phase = phaseMorph.targetPhase
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
    let progress: Double
    let isFinalDisplayedSecond: Bool
    let wavePhase: Double
    let glowExpansion: Double
    let stepBoundaryCueProgress: Double

    private var phase: SessionPhase {
        phaseMorph.targetPhase
    }

    var body: some View {
        let phase = phaseMorph.targetPhase
        let profile = phaseMorph.shellProfile(for: FocusScreenLayout.bubbleDiameter)
        let normalizedProgress = max(0, min(progress, 1))
        let boundaryCue = max(0, min(stepBoundaryCueProgress, 1))
        let baseFillRatio = min(0.987, 0.12 + pow(normalizedProgress, 1.22) * 0.86)
        let terminalBoost = isFinalDisplayedSecond ? 0.052 : 0
        let visualFillRatio = min(1.035, baseFillRatio + terminalBoost)
        let amplitude = (profile.waveAmplitudeBase + glowExpansion * profile.waveAmplitudeRange) * (1 - boundaryCue * 0.24)
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
            let spherePath = phaseMorph.shape.path(in: sphereRect)
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
                amplitude: amplitude * (0.55 - boundaryCue * 0.10)
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
            depthPoolContext.addFilter(.blur(radius: colorScheme == .dark ? 14 - boundaryCue * 2 : 11 - boundaryCue * 1.4))
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
