import SwiftUI

struct BubbleGlassBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    let phaseMorph: BubblePhaseMorph
    let sphereSize: CGFloat

    var body: some View {
        let isDark = colorScheme == .dark
        let phase = phaseMorph.visualPhase
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

struct BubbleGlassRimOverlay: View {
    @Environment(\.colorScheme) private var colorScheme

    let phaseMorph: BubblePhaseMorph
    let sphereSize: CGFloat

    var body: some View {
        let isDark = colorScheme == .dark
        let phase = phaseMorph.visualPhase
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
