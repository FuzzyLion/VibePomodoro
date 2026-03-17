import SwiftUI

enum VibePalette {
    static let focusTint = Color(red: 0.82, green: 0.63, blue: 0.22)
    static let shortBreakTint = Color(red: 0.56, green: 0.70, blue: 0.60)
    static let longBreakTint = Color(red: 0.55, green: 0.63, blue: 0.82)
    static let warmBackground = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let darkBackground = Color(red: 0.09, green: 0.10, blue: 0.13)
}

extension SessionPhase {
    var tintColor: Color {
        switch self {
        case .focus:
            return VibePalette.focusTint
        case .shortBreak:
            return VibePalette.shortBreakTint
        case .longBreak:
            return VibePalette.longBreakTint
        }
    }
}

struct VibeBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .top) {
            Circle()
                .fill(VibePalette.focusTint.opacity(colorScheme == .dark ? 0.12 : 0.10))
                .blur(radius: 90)
                .frame(width: 280, height: 280)
                .offset(y: -120)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.02 : 0.28))
                .blur(radius: 100)
                .frame(width: 260, height: 260)
                .offset(x: 70, y: 100)
        }
        .ignoresSafeArea()
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                VibePalette.darkBackground,
                Color(red: 0.13, green: 0.14, blue: 0.17),
                Color(red: 0.10, green: 0.11, blue: 0.14)
            ]
        }

        return [
            VibePalette.warmBackground,
            Color.white,
            Color(red: 0.95, green: 0.94, blue: 0.92)
        ]
    }
}

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 28, y: 12)
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 188, height: 64)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.86), Color.white.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 16)
        }
        .shadow(color: Color.black.opacity(0.10), radius: 22, y: 10)
    }

    private func iconName(for tab: AppTab) -> String {
        switch tab {
        case .focus:
            return "timer"
        case .productivity:
            return "chart.bar"
        case .settings:
            return "gearshape"
        }
    }

    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selection == tab

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 0) {
                Image(systemName: iconName(for: tab))
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(isSelected ? VibePalette.focusTint : Color.primary.opacity(0.38))
                    .frame(width: 52, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isSelected ? selectedTabBackground : AnyShapeStyle(Color.clear))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(isSelected ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                            }
                    )

                Circle()
                    .fill(isSelected ? VibePalette.focusTint : Color.clear)
                    .frame(width: 4, height: 4)
                    .offset(y: 4)
            }
            .frame(width: 56, height: 48)
        }
        .buttonStyle(.plain)
    }

    private var selectedTabBackground: AnyShapeStyle {
        AnyShapeStyle(
            RadialGradient(
                colors: [
                    VibePalette.focusTint.opacity(0.24),
                    VibePalette.focusTint.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 4,
                endRadius: 36
            )
        )
    }
}

struct PhaseStatusBadge: View {
    let text: String
    let phase: SessionPhase

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(phase.tintColor)
                .frame(width: 8, height: 8)
                .shadow(color: phase.tintColor.opacity(0.48), radius: 6)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .textCase(.uppercase)
        }
        .foregroundStyle(Color.primary.opacity(0.48))
        .padding(.horizontal, 20)
        .frame(height: 32)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.36), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
    }
}

struct SessionProgressPill: View {
    let title: String
    let currentRound: Int
    let totalRounds: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(1)

            Spacer(minLength: 10)

            HStack(spacing: 6) {
                ForEach(0..<max(1, totalRounds), id: \.self) { index in
                    Circle()
                        .fill(index < currentRound ? activeDotFill : AnyShapeStyle(Color.primary.opacity(0.10)))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .foregroundStyle(Color.primary.opacity(0.40))
        .padding(.horizontal, 22)
        .frame(height: 40)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 18, y: 8)
    }

    private var activeDotFill: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [VibePalette.focusTint, Color(red: 0.77, green: 0.60, blue: 0.29)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct SecondaryActionButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
                .foregroundStyle(isEnabled ? Color.primary.opacity(0.46) : Color.primary.opacity(0.22))
                .frame(maxWidth: .infinity)
                .frame(height: 50.5)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }
}

struct BubbleTimerView: View {
    let phase: SessionPhase
    let timeText: String
    let progress: Double
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        ZStack {
            BubbleGlassShape()
                .fill(.ultraThinMaterial)
                .overlay(
                    BubbleGlassShape()
                        .stroke(Color.white.opacity(0.42), lineWidth: 1)
                )
                .shadow(color: phase.tintColor.opacity(0.10), radius: 42, y: 24)
                .shadow(color: Color.white.opacity(0.18), radius: 26, y: -8)

            BubbleGlassShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            phase.tintColor.opacity(0.06),
                            phase.tintColor.opacity(0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 14)
                .padding(8)

            GeometryReader { proxy in
                let size = proxy.size
                let clampedProgress = max(0, min(progress, 1))
                let fillHeight = size.height * (0.16 + clampedProgress * 0.42)
                let innerWidth = size.width * 0.78

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: size.width * 0.25, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    phase.tintColor.opacity(0.24),
                                    phase.tintColor.opacity(0.12),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: innerWidth, height: fillHeight)
                        .blur(radius: 2)
                        .overlay(alignment: .top) {
                            Ellipse()
                                .fill(Color.white.opacity(0.24))
                                .blur(radius: 10)
                                .frame(width: innerWidth * 0.94, height: 18)
                                .offset(y: -8)
                        }
                        .overlay(alignment: .bottom) {
                            Ellipse()
                                .fill(Color.black.opacity(0.08))
                                .blur(radius: 12)
                                .frame(width: innerWidth * 0.82, height: 18)
                                .offset(y: 10)
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .clipShape(BubbleGlassShape())
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
            }

            VStack(spacing: 8) {
                Text(timeText)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.96))
                    .monospacedDigit()
                    .minimumScaleFactor(0.72)
                    .shadow(color: Color.white.opacity(0.18), radius: 8, y: 0)

                Button(action: action) {
                    Image(systemName: actionTitle == "Pause" ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Color.white.opacity(0.96))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.18))
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .shadow(color: Color.white.opacity(0.10), radius: 6, y: 0)
            }
        }
        .frame(width: 280, height: 280)
    }
}

private struct BubbleGlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()

        path.move(to: CGPoint(x: width * 0.5, y: height * 0.045))
        path.addCurve(
            to: CGPoint(x: width * 0.88, y: height * 0.43),
            control1: CGPoint(x: width * 0.76, y: height * 0.055),
            control2: CGPoint(x: width * 0.92, y: height * 0.22)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.80, y: height * 0.90),
            control1: CGPoint(x: width * 0.89, y: height * 0.66),
            control2: CGPoint(x: width * 0.89, y: height * 0.84)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.20, y: height * 0.90),
            control1: CGPoint(x: width * 0.66, y: height * 0.98),
            control2: CGPoint(x: width * 0.34, y: height * 0.98)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.12, y: height * 0.43),
            control1: CGPoint(x: width * 0.11, y: height * 0.84),
            control2: CGPoint(x: width * 0.11, y: height * 0.66)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.045),
            control1: CGPoint(x: width * 0.08, y: height * 0.22),
            control2: CGPoint(x: width * 0.24, y: height * 0.055)
        )

        path.closeSubpath()
        return path
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(VibePalette.focusTint)
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(VibePalette.focusTint.opacity(0.10))
                    )

                Spacer(minLength: 12)

                Text(title.uppercased())
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.72)

                Text(subtitle)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
        }
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingStepperRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let valueText: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            settingIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 30, height: 30)
                }

                Text(valueText)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .monospacedDigit()

                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 30, height: 30)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.18))
            )
        }
    }

    private var settingIcon: some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 42, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.14))
            )
    }
}

struct SettingToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isOn ? VibePalette.focusTint : .secondary)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill((isOn ? VibePalette.focusTint : .white).opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(VibePalette.focusTint)
        }
    }
}

struct SettingPickerRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var selection: SoundOption

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker(title, selection: $selection) {
                ForEach(SoundOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(VibePalette.focusTint)
        }
    }
}
