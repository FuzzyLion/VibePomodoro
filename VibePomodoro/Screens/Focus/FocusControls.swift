import SwiftUI

struct PhaseStatusBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let phase: SessionPhase

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(phase.tintColor)
                .frame(width: 8, height: 8)
                .shadow(color: phase.shadowColor.opacity(0.18), radius: 4)

            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .tracking(1.48)
                .textCase(.uppercase)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(VibePalette.glassTextStrong(for: colorScheme))
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background {
            GlassCapsuleShell(
                tint: phase.glassTint.opacity(0.22),
                darkStrokeOpacity: 0.44,
                lightStrokeOpacity: 0.52
            )
        }
        .frame(minHeight: 31.5)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.022 : 0.035),
            radius: colorScheme == .dark ? 4 : 6,
            y: 1
        )
        .zIndex(4)
    }
}

enum SessionProgressNodeState: Equatable {
    case inactive
    case half
    case filled
}

struct SessionProgressPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let nodeStates: [SessionProgressNodeState]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(nodeStates.enumerated()), id: \.offset) { _, state in
                SessionProgressNode(state: state)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
        .background {
            GlassCapsuleShell(
                tint: VibePalette.warmAmberAccent.opacity(0.05),
                darkStrokeOpacity: 0.42,
                lightStrokeOpacity: 0.50
            )
        }
        .background {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            phase.shadowColor.opacity(colorScheme == .dark ? 0.07 : 0.05),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: colorScheme == .dark ? 12 : 10)
                .padding(.horizontal, -8)
                .padding(.vertical, -6)
        }
        .frame(minHeight: 31.5)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.02 : 0.03),
            radius: colorScheme == .dark ? 6 : 8,
            y: colorScheme == .dark ? 1 : 2
        )
        .zIndex(4)
    }
}

private struct SessionProgressNode: View {
    @Environment(\.colorScheme) private var colorScheme

    let state: SessionProgressNodeState

    var body: some View {
        Circle()
            .fill(VibePalette.inactiveGlassDot(for: colorScheme))
            .overlay {
                if state != .inactive {
                    Circle()
                        .fill(activeFill)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: state == .half ? 5 : 10)
                        }
                }
            }
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.30), lineWidth: 0.4)
            }
            .frame(width: 9, height: 9)
            .shadow(
                color: state == .inactive
                    ? .clear
                    : VibePalette.warmAmberAccent.opacity(colorScheme == .dark ? 0.22 : 0.12),
                radius: 2.5
            )
    }

    private var activeFill: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [VibePalette.warmAmberAccent, VibePalette.warmAmberAccentDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct SecondaryActionButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let systemImage: String
    let isEnabled: Bool
    let glassTint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassCapsuleShell(
                tint: glassTint.opacity(colorScheme == .dark ? 0.12 : 0.10),
                darkStrokeOpacity: 0.42,
                lightStrokeOpacity: 0.50
            )
            .overlay {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .medium))

                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .tracking(-0.23)
                }
                .foregroundStyle(
                    isEnabled
                        ? VibePalette.glassTextSoft(for: colorScheme)
                        : VibePalette.labelSecondary.opacity(0.68)
                )
            }
            .frame(maxWidth: .infinity, minHeight: 50.5, maxHeight: 50.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.035 : 0.03),
            radius: colorScheme == .dark ? 3 : 4,
            y: colorScheme == .dark ? 1 : 2
        )
        .opacity(isEnabled ? 1 : 0.72)
        .zIndex(4)
    }
}

private struct GlassCapsuleShell: View {
    @Environment(\.colorScheme) private var colorScheme

    let tint: Color
    var material: Material = .thinMaterial
    var darkStrokeOpacity: Double = 0.40
    var lightStrokeOpacity: Double = 0.48

    var body: some View {
        Capsule(style: .continuous)
            .fill(material)
            .overlay {
                Capsule(style: .continuous)
                    .fill(colorScheme == .dark ? tint.opacity(0.72) : tint)
            }
            .overlay {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.045 : 0.025),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(
                        Color.white.opacity(
                            colorScheme == .dark ? darkStrokeOpacity * 0.84 : lightStrokeOpacity
                        ),
                        lineWidth: 0.9
                    )
            }
    }
}

struct FocusCornerIconButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemImage: String
    let accessibilityLabel: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background {
                    FocusCircleShell(
                        tint: Color.white.opacity(colorScheme == .dark ? 0.045 : 0.075)
                    )
                }
        }
        .buttonStyle(FocusCornerButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.64)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.042 : 0.03),
            radius: colorScheme == .dark ? 5 : 7,
            y: colorScheme == .dark ? 1.5 : 2.5
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .zIndex(4)
    }

    private var iconColor: Color {
        isEnabled
            ? VibePalette.glassTextMedium(for: colorScheme)
            : VibePalette.labelSecondary.opacity(0.68)
    }
}

private struct FocusCircleShell: View {
    @Environment(\.colorScheme) private var colorScheme

    let tint: Color

    var body: some View {
        Circle()
            .fill(.thinMaterial)
            .overlay {
                Circle()
                    .fill(colorScheme == .dark ? tint.opacity(0.72) : tint)
            }
            .overlay {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.08),
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
                        Color.white.opacity(colorScheme == .dark ? 0.30 : 0.48),
                        lineWidth: 0.9
                    )
            }
    }
}

private struct FocusCornerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .brightness(configuration.isPressed ? 0.012 : 0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
