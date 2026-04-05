import SwiftUI

struct FocusStatusTitle: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let phase: SessionPhase

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(phase.tintColor)
                .frame(width: 8, height: 8)
                .shadow(color: phase.shadowColor.opacity(colorScheme == .dark ? 0.24 : 0.18), radius: 4)

            Text(displayText)
                .font(.system(size: 20, weight: .semibold, design: .default))
                .tracking(-0.35)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(titleColor)
        }
        .frame(minHeight: FocusScreenLayout.topActionButtonSize)
        .zIndex(4)
    }

    private var displayText: String {
        text.lowercased().capitalized
    }

    private var titleColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.95)
            : VibePalette.labelPrimary.opacity(0.92)
    }
}

enum SessionProgressNodeState: Equatable {
    case inactive
    case half
    case filled
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
                if state != .inactive {
                    Circle()
                        .fill(activeFill)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: state == .half ? dotDiameter / 2 : dotDiameter)
                        }
                }
            }
            .overlay {
                Circle()
                    .stroke(borderColor, lineWidth: 0.45)
            }
            .frame(width: dotDiameter, height: dotDiameter)
            .shadow(
                color: state == .inactive
                    ? .clear
                    : phase.shadowColor.opacity(colorScheme == .dark ? 0.22 : 0.13),
                radius: 2.5,
                y: 0.5
            )
    }

    private var inactiveFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.14)
            : VibePalette.labelSecondary.opacity(0.16)
    }

    private var borderColor: Color {
        Color.white.opacity(colorScheme == .dark ? 0.14 : 0.28)
    }

    private var activeFill: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [phase.tintColor, phase.shadowColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct FocusTopBarButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemImage: String
    let isEnabled: Bool
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: FocusScreenLayout.topActionButtonSize, height: FocusScreenLayout.topActionButtonSize)
        }
        .buttonStyle(.glass(topBarGlass))
        .buttonBorderShape(.circle)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .zIndex(4)
    }

    private var topBarGlass: Glass {
        .regular
            .tint(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12))
            .interactive()
    }
}

struct FocusBottomSecondaryButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemImage: String
    let isEnabled: Bool
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(
                    width: FocusScreenLayout.bottomSecondaryButtonSize,
                    height: FocusScreenLayout.bottomSecondaryButtonSize
                )
        }
        .buttonStyle(.glass(bottomButtonGlass))
        .buttonBorderShape(.circle)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .zIndex(4)
    }

    private var bottomButtonGlass: Glass {
        .regular
            .tint(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12))
            .interactive()
    }
}

struct FocusPrimaryControlButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))

                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .tracking(-0.22)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(.primary)
            .frame(
                maxWidth: .infinity,
                minHeight: FocusScreenLayout.bottomPrimaryButtonHeight,
                maxHeight: FocusScreenLayout.bottomPrimaryButtonHeight
            )
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .zIndex(4)
    }
}
