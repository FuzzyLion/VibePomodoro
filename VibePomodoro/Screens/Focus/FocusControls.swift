import SwiftUI

enum FocusControlColors {
    static func statusTitleColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.92)
            : VibePalette.labelPrimary.opacity(0.84)
    }

    static var lightProminentButtonForeground: Color {
        VibePalette.labelPrimary.opacity(0.68)
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

            Text(displayText)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .tracking(-0.2)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
                .foregroundStyle(titleColor)
        }
        .frame(minHeight: FocusScreenLayout.topActionButtonVisualSize)
        .zIndex(4)
    }

    private var displayText: String {
        text.lowercased().capitalized
    }

    private var titleColor: Color {
        FocusControlColors.statusTitleColor(for: colorScheme)
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
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(toolbarSymbolColor)
                .frame(
                    width: FocusScreenLayout.topActionButtonVisualSize,
                    height: FocusScreenLayout.topActionButtonVisualSize
                )
        }
        .buttonStyle(.glass(topBarGlass))
        .buttonBorderShape(.circle)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.34)
        .animation(nil, value: isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .zIndex(4)
    }

    private var toolbarSymbolColor: Color {
        colorScheme == .dark
            ? VibePalette.amberGold.opacity(0.86)
            : VibePalette.warmAmberAccentDeep.opacity(0.88)
    }

    private var topBarGlass: Glass {
        .regular
            .tint(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12))
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
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(secondaryIconColor.opacity(isEnabled ? 1 : 0.38))
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

    private var secondaryIconColor: Color {
        colorScheme == .dark
            ? VibePalette.amberGold.opacity(0.84)
            : VibePalette.warmAmberAccentDeep.opacity(0.88)
    }

    private var bottomButtonGlass: Glass {
        .regular
            .tint(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12))
    }
}

struct FocusPrimaryControlButton: View {
    @Environment(\.colorScheme) private var colorScheme

    private static let elevatedContrastTitles: Set<String> = ["Pause", "Resume", "Start", "Start Again"]

    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))

                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .tracking(-0.18)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
            }
            .foregroundStyle(primaryForegroundColor)
            .frame(
                minWidth: FocusScreenLayout.bottomPrimaryButtonMinWidth,
                maxWidth: .infinity,
                minHeight: FocusScreenLayout.bottomPrimaryButtonHeight,
                maxHeight: FocusScreenLayout.bottomPrimaryButtonHeight
            )
        }
        .buttonStyle(.glassProminent)
        .tint(primaryTint)
        .buttonBorderShape(.capsule)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .zIndex(4)
    }

    private var primaryForegroundColor: Color {
        if colorScheme == .light, Self.elevatedContrastTitles.contains(title) {
            return FocusControlColors.lightProminentButtonForeground
        }

        return .primary
    }

    private var primaryTint: Color {
        switch title {
        case "Pause":
            return colorScheme == .dark
                ? VibePalette.amberGold.opacity(0.58)
                : VibePalette.warmAmberAccent.opacity(0.60)
        case "Resume", "Start", "Start Again":
            return colorScheme == .dark
                ? VibePalette.softJade.opacity(0.22)
                : VibePalette.softMistDeep.opacity(0.24)
        default:
            return colorScheme == .dark
                ? VibePalette.amberGold.opacity(0.52)
                : VibePalette.warmAmberAccent.opacity(0.54)
        }
    }
}
