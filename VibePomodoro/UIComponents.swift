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
        HStack(spacing: 16) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: iconName(for: tab))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(selection == tab ? VibePalette.focusTint : .secondary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(selection == tab ? VibePalette.focusTint.opacity(0.16) : Color.clear)
                            )

                        Circle()
                            .fill(selection == tab ? VibePalette.focusTint : Color.clear)
                            .frame(width: 6, height: 6)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            Capsule(style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
        .padding(.horizontal, 28)
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
}

struct PhaseStatusBadge: View {
    let text: String
    let phase: SessionPhase

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(phase.tintColor)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .tracking(2.6)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
        )
    }
}

struct SessionProgressPill: View {
    let title: String
    let currentRound: Int
    let totalRounds: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(title.uppercased())
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .tracking(2)

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                ForEach(0..<max(1, totalRounds), id: \.self) { index in
                    Circle()
                        .fill(index < currentRound ? VibePalette.focusTint : Color.secondary.opacity(0.18))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Capsule(style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
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
            Label(title, systemImage: systemImage)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(isEnabled ? .secondary : .tertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .shadow(color: Color.black.opacity(0.05), radius: 18, y: 10)
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
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.34), lineWidth: 1.2)
                )

            Circle()
                .stroke(phase.tintColor.opacity(0.16), lineWidth: 20)
                .blur(radius: 10)
                .padding(12)

            GeometryReader { proxy in
                let size = proxy.size
                let fillHeight = size.height * max(0.1, min(progress, 1))

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: size.width * 0.25, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    phase.tintColor.opacity(0.55),
                                    phase.tintColor.opacity(0.14)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: fillHeight)
                        .overlay(alignment: .top) {
                            Ellipse()
                                .fill(Color.white.opacity(0.28))
                                .blur(radius: 8)
                                .frame(width: size.width * 0.72, height: 16)
                                .offset(y: -6)
                        }
                }
                .clipShape(Circle())
                .padding(22)
            }

            VStack(spacing: 18) {
                Text(timeText)
                    .font(.system(size: 62, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.65)

                Button(action: action) {
                    Image(systemName: actionTitle == "Pause" ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 64, height: 64)
                        .background(
                            Circle()
                                .fill(.regularMaterial)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .shadow(color: Color.black.opacity(0.08), radius: 16, y: 8)
            }
        }
        .frame(maxWidth: 360)
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 10)
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

