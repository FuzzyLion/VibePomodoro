import SwiftUI

enum FocusControlColors {
    static func statusTitleColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.92)
            : VibePalette.labelPrimary.opacity(0.84)
    }

    /// Icons on the round glass controls: warm white in dark mode, restrained dark gray in light mode.
    static func controlIconColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.86)
            : VibePalette.labelPrimary.opacity(0.78)
    }

    /// Secondary text on the page, such as a finished session's breakdown. At least 4.5:1 on
    /// the page in both appearances.
    static func captionColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.64)
            : VibePalette.labelPrimary.opacity(0.80)
    }

    /// Label color on tinted capsule buttons in light mode, dark enough for 4.5:1 on the tint.
    static var lightProminentButtonForeground: Color {
        VibePalette.labelPrimary.opacity(0.92)
    }
}

struct FocusStatusTitle: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let phase: SessionPhase

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(phase.tintColor)
                .frame(width: 6.5, height: 6.5)
                .shadow(color: phase.shadowColor.opacity(colorScheme == .dark ? 0.20 : 0.14), radius: 3)

            Text(text)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .tracking(-0.2)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
                .foregroundStyle(FocusControlColors.statusTitleColor(for: colorScheme))
        }
        .frame(minHeight: FocusScreenLayout.topActionButtonVisualSize)
        .zIndex(4)
    }
}

enum SessionProgressNodeState: Equatable {
    case inactive
    /// The focus block that is running now.
    case half
    /// A focus block that reached its full planned duration.
    case filled
    /// A focus block that was skipped or ended before its full duration.
    case skipped
}

struct SessionProgressDots: View {
    let phase: SessionPhase
    let nodeStates: [SessionProgressNodeState]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(nodeStates.enumerated()), id: \.offset) { _, state in
                SessionProgressNode(phase: phase, state: state)
            }
        }
        .frame(minHeight: 12)
        .zIndex(4)
    }
}

private struct SessionProgressNode: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let state: SessionProgressNodeState

    private let dotDiameter: CGFloat = 8.5

    var body: some View {
        Circle()
            .fill(inactiveFill)
            .overlay {
                if state == .half || state == .filled {
                    Circle()
                        .fill(activeFill)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: state == .half ? dotDiameter / 2 : dotDiameter)
                        }
                }
            }
            .overlay {
                if state == .skipped {
                    Circle()
                        .strokeBorder(phase.shadowColor.opacity(colorScheme == .dark ? 0.85 : 0.75), lineWidth: 1.2)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.28), lineWidth: 0.45)
                }
            }
            .frame(width: dotDiameter, height: dotDiameter)
            .shadow(
                color: state == .half || state == .filled
                    ? phase.shadowColor.opacity(colorScheme == .dark ? 0.22 : 0.13)
                    : .clear,
                radius: 2.5,
                y: 0.5
            )
    }

    private var inactiveFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.14)
            : VibePalette.labelSecondary.opacity(0.16)
    }

    private var activeFill: LinearGradient {
        LinearGradient(
            colors: [phase.tintColor, phase.shadowColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// A round glass control with a single SF Symbol, used in the top row and beside the primary button.
struct FocusIconButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemImage: String
    let diameter: CGFloat
    let symbolSize: CGFloat
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(FocusControlColors.controlIconColor(for: colorScheme))
                .frame(width: diameter, height: diameter)
        }
        .buttonStyle(.glass(.regular.tint(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12))))
        .buttonBorderShape(.circle)
        .accessibilityLabel(accessibilityLabel)
        .zIndex(4)
    }
}

struct FocusPrimaryControlButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let action: FocusPrimaryAction
    let phase: SessionPhase
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 9) {
                // When the label changes inside an animation, as Pause becomes Done at a session's
                // end, the symbol and the title change over together.
                Image(systemName: action.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))

                Text(action.title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .tracking(-0.18)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .contentTransition(.opacity)
            }
            .foregroundStyle(colorScheme == .light ? FocusControlColors.lightProminentButtonForeground : .primary)
            .frame(
                minWidth: FocusScreenLayout.bottomPrimaryButtonMinWidth,
                maxWidth: .infinity,
                minHeight: FocusScreenLayout.bottomPrimaryButtonHeight,
                maxHeight: FocusScreenLayout.bottomPrimaryButtonHeight
            )
        }
        .buttonStyle(.glassProminent)
        .tint(tint)
        .buttonBorderShape(.capsule)
        .accessibilityLabel(action.title)
        .zIndex(4)
    }

    /// Pause stays neutral so the bubble remains the strongest color while a step runs.
    /// Start, Resume, and Done carry a light wash of the current phase color.
    private var tint: Color {
        if action == .pause {
            return Color.white.opacity(colorScheme == .dark ? 0.10 : 0.70)
        }

        return phase.tintColor.opacity(colorScheme == .dark ? 0.34 : 0.42)
    }
}
