import SwiftUI

struct FocusCompletionBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let revealProgress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .glassEffect(.regular.tint(badgeGlassTint), in: Circle())
                .overlay {
                    Circle()
                        .fill(badgeGradient)
                        .allowsHitTesting(false)
                }
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.24 : 0.42), lineWidth: 0.9)
                }
                .frame(width: 88, height: 88)

            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            VibePalette.softMistDeep,
                            VibePalette.softJadeDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .opacity(Double(revealProgress))
        .scaleEffect(0.98 + (0.02 * revealProgress))
        .offset(y: (1 - revealProgress) * 4)
        .shadow(
            color: VibePalette.softJadeDeep.opacity((colorScheme == .dark ? 0.18 : 0.10) * revealProgress),
            radius: colorScheme == .dark ? 20 : 14,
            y: colorScheme == .dark ? 8 : 6
        )
        .accessibilityHidden(true)
    }

    private var badgeGlassTint: Color {
        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.14)
    }

    private var badgeGradient: LinearGradient {
        LinearGradient(
            colors: [
                VibePalette.softMist.opacity(colorScheme == .dark ? 0.28 : 0.22),
                VibePalette.softJade.opacity(colorScheme == .dark ? 0.22 : 0.18),
                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CompletionBackdropVeil: View {
    @Environment(\.colorScheme) private var colorScheme

    let progress: CGFloat

    var body: some View {
        let clampedProgress = min(max(progress, 0), 1)
        let topOpacity = (colorScheme == .dark ? 0.010 : 0.004) * clampedProgress
        let midOpacity = (colorScheme == .dark ? 0.040 : 0.016) * clampedProgress
        let bottomOpacity = (colorScheme == .dark ? 0.105 : 0.042) * clampedProgress
        let vignetteOpacity = (colorScheme == .dark ? 0.090 : 0.036) * clampedProgress

        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(topOpacity),
                    Color.black.opacity(midOpacity),
                    Color.black.opacity(bottomOpacity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(vignetteOpacity * 0.45),
                    Color.black.opacity(vignetteOpacity)
                ],
                center: .center,
                startRadius: 72,
                endRadius: 540
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct CompletionVerticalRevealMask: View {
    let progress: CGFloat

    var body: some View {
        let clampedProgress = min(max(progress, 0), 1)

        Group {
            if clampedProgress <= 0 {
                Color.clear
            } else if clampedProgress >= 1 {
                Color.white
            } else {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: max(0, clampedProgress - 0.22)),
                        .init(color: Color.white.opacity(0.82), location: max(0, clampedProgress - 0.08)),
                        .init(color: .clear, location: min(1, clampedProgress + 0.04)),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

struct FocusCompletionDoneButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Done")
                .font(.system(size: 19, weight: .semibold))
                .tracking(-0.18)
                .minimumScaleFactor(0.92)
                .foregroundStyle(doneForegroundColor)
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.glassProminent)
        .tint(doneTint)
        .buttonBorderShape(.capsule)
    }

    private var doneForegroundColor: Color {
        colorScheme == .light
            ? FocusControlColors.lightProminentButtonForeground
            : .primary
    }

    private var doneTint: Color {
        colorScheme == .dark
            ? VibePalette.amberGold.opacity(0.52)
            : VibePalette.warmAmberAccent.opacity(0.54)
    }
}
