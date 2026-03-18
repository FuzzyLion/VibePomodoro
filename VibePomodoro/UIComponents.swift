import SwiftUI

enum VibePalette {
    static let amberGold = Color(red: 0.85, green: 0.70, blue: 0.40)
    static let amberGoldDeep = Color(red: 0.76, green: 0.58, blue: 0.25)
    static let warmAmberAccent = Color(red: 0.70, green: 0.55, blue: 0.31)
    static let warmAmberAccentDeep = Color(red: 0.58, green: 0.44, blue: 0.24)
    static let softMist = Color(red: 0.71, green: 0.82, blue: 0.90)
    static let softMistDeep = Color(red: 0.52, green: 0.65, blue: 0.75)
    static let softJade = Color(red: 0.66, green: 0.80, blue: 0.74)
    static let softJadeDeep = Color(red: 0.48, green: 0.66, blue: 0.60)

    static let warmBackground = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let mistBackground = Color(red: 0.93, green: 0.93, blue: 0.95)
    static let darkBackground = Color(red: 0.08, green: 0.09, blue: 0.11)
    static let darkSurface = Color(red: 0.13, green: 0.14, blue: 0.17)

    static let focusTint = amberGold
    static let labelPrimary = Color(red: 0.24, green: 0.24, blue: 0.27)
    static let labelSecondary = Color(red: 0.46, green: 0.46, blue: 0.50)

    static func glassTextStrong(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? warmBackground.opacity(0.96) : Color.black.opacity(0.50)
    }

    static func glassTextMedium(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? warmBackground.opacity(0.92) : Color.black.opacity(0.45)
    }

    static func glassTextSoft(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? warmBackground.opacity(0.88) : Color.black.opacity(0.40)
    }

    static func inactiveGlassDot(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? warmBackground.opacity(0.22) : Color.black.opacity(0.10)
    }
}

extension SessionPhase {
    var tintColor: Color {
        switch self {
        case .focus:
            return VibePalette.amberGold
        case .shortBreak:
            return VibePalette.softMist
        case .longBreak:
            return VibePalette.softJade
        }
    }

    var glassTint: Color {
        switch self {
        case .focus:
            return VibePalette.amberGold.opacity(0.14)
        case .shortBreak:
            return VibePalette.softMist.opacity(0.16)
        case .longBreak:
            return VibePalette.softJade.opacity(0.14)
        }
    }

    var shadowColor: Color {
        switch self {
        case .focus:
            return VibePalette.amberGoldDeep
        case .shortBreak:
            return VibePalette.softMistDeep
        case .longBreak:
            return VibePalette.softJadeDeep
        }
    }

    var liquidGradientColors: [Color] {
        switch self {
        case .focus:
            return [
                VibePalette.amberGold.opacity(0.14),
                VibePalette.amberGold.opacity(0.20),
                VibePalette.amberGoldDeep.opacity(0.28)
            ]
        case .shortBreak:
            return [
                VibePalette.softMist.opacity(0.16),
                VibePalette.softMist.opacity(0.24),
                VibePalette.softMistDeep.opacity(0.30)
            ]
        case .longBreak:
            return [
                VibePalette.softJade.opacity(0.12),
                VibePalette.softJade.opacity(0.18),
                VibePalette.softJadeDeep.opacity(0.24)
            ]
        }
    }
}

struct VibeBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    VibePalette.amberGold.opacity(colorScheme == .dark ? 0.12 : 0.09),
                    Color.clear
                ],
                center: .top,
                startRadius: 16,
                endRadius: colorScheme == .dark ? 260 : 320
            )
            .offset(y: -120)

            RadialGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.72),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 360
            )

            RadialGradient(
                colors: [
                    VibePalette.softJade.opacity(colorScheme == .dark ? 0.06 : 0.035),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 280
            )
            .offset(x: 80, y: 80)
        }
        .ignoresSafeArea()
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                VibePalette.darkBackground,
                VibePalette.darkSurface,
                Color(red: 0.10, green: 0.11, blue: 0.14)
            ]
        }

        return [
            VibePalette.warmBackground,
            Color(red: 0.97, green: 0.97, blue: 0.98),
            VibePalette.mistBackground
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
            .liquidGlassSurface(
                .regular.tint(Color.white.opacity(0.08)),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous),
                stroke: Color.white.opacity(0.38)
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
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let phase: SessionPhase

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.055 : 0.070),
                                    Color.white.opacity(colorScheme == .dark ? 0.012 : 0.020)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    Capsule(style: .continuous)
                        .fill(phase.glassTint.opacity(0.22))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.44 : 0.52), lineWidth: 0.9)
                }
                .overlay(alignment: .top) {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(colorScheme == .dark ? 0.24 : 0.34), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 0.8)
                        .padding(.horizontal, 20)
                        .blur(radius: 0.4)
                }
                .overlay(alignment: .bottom) {
                    Capsule(style: .continuous)
                        .stroke(Color.black.opacity(0.018), lineWidth: 0.8)
                        .blur(radius: 1.2)
                        .offset(y: 1)
                        .mask {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, Color.black],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                }

            HStack(spacing: 8) {
                Circle()
                    .fill(phase.tintColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: phase.shadowColor.opacity(0.30), radius: 8)

                Text(text)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .tracking(1.48)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(VibePalette.glassTextStrong(for: colorScheme))
            .padding(.horizontal, 20)
        }
        .frame(height: 31.5)
        .shadow(color: Color.black.opacity(0.05), radius: 12, y: 2)
        .zIndex(4)
    }
}

enum SessionProgressNodeState {
    case inactive
    case half
    case filled
}

struct SessionProgressPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let nodeStates: [SessionProgressNodeState]

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.050 : 0.064),
                                    Color.white.opacity(colorScheme == .dark ? 0.012 : 0.018)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    Capsule(style: .continuous)
                        .fill(VibePalette.warmAmberAccent.opacity(0.05))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.42 : 0.50), lineWidth: 0.9)
                }
                .overlay(alignment: .top) {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(colorScheme == .dark ? 0.22 : 0.32), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 0.8)
                        .padding(.horizontal, 22)
                        .blur(radius: 0.4)
                }
                .overlay(alignment: .bottom) {
                    Capsule(style: .continuous)
                        .stroke(Color.black.opacity(0.018), lineWidth: 0.8)
                        .blur(radius: 1.2)
                        .offset(y: 1)
                        .mask {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, Color.black],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                }

            HStack(spacing: 10) {
                ForEach(Array(nodeStates.enumerated()), id: \.offset) { _, state in
                    SessionProgressNode(state: state)
                }
            }
            .padding(.horizontal, 34)
        }
        .background {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            phase.shadowColor.opacity(colorScheme == .dark ? 0.16 : 0.07),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: colorScheme == .dark ? 26 : 20)
                .padding(.horizontal, -8)
                .padding(.vertical, -6)
        }
        .frame(height: 31.5)
        .shadow(color: Color.black.opacity(0.04), radius: 20, y: 4)
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
                color: state == .inactive ? .clear : VibePalette.warmAmberAccent.opacity(colorScheme == .dark ? 0.22 : 0.12),
                radius: 4
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
            ZStack {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.050 : 0.062),
                                        Color.white.opacity(colorScheme == .dark ? 0.012 : 0.018)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        Capsule(style: .continuous)
                            .fill(glassTint.opacity(colorScheme == .dark ? 0.12 : 0.10))
                    }
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.42 : 0.50), lineWidth: 0.9)
                    }
                    .overlay(alignment: .top) {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(colorScheme == .dark ? 0.22 : 0.30), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 0.8)
                            .padding(.horizontal, 22)
                            .blur(radius: 0.4)
                    }
                    .overlay(alignment: .bottom) {
                        Capsule(style: .continuous)
                            .stroke(Color.black.opacity(0.018), lineWidth: 0.8)
                            .blur(radius: 1.2)
                            .offset(y: 1)
                            .mask {
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.clear, Color.black],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                    }

                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .medium))
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .tracking(-0.23)
                }
                .foregroundStyle(isEnabled ? VibePalette.glassTextSoft(for: colorScheme) : VibePalette.labelSecondary.opacity(0.68))
            }
            .frame(maxWidth: .infinity, minHeight: 50.5, maxHeight: 50.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.09 : 0.04), radius: 8, y: 3)
        .opacity(isEnabled ? 1 : 0.72)
        .zIndex(4)
    }
}

struct TertiaryActionButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundStyle(isEnabled ? VibePalette.glassTextMedium(for: colorScheme) : VibePalette.labelSecondary.opacity(0.68))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .padding(.top, 2)
        .opacity(isEnabled ? 1 : 0.64)
        .zIndex(4)
    }
}

struct BubbleTimerView: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let timer: FocusTimerSnapshot
    let action: () -> Void

    @State private var accumulatedWaveTime: TimeInterval = 0
    @State private var waveAnimationStart: Date?

    var body: some View {
        let sphereSize: CGFloat = 280

        ZStack {
            TimelineView(.periodic(from: .now, by: timer.animationRefreshInterval)) { context in
                let wavePhase = currentWavePhase(now: context.date)
                let glowExpansion = 0.52 + (sin(wavePhase * 0.75) + 1) * 0.24

                ZStack {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    phase.shadowColor.opacity(0.12 + glowExpansion * 0.10),
                                    phase.shadowColor.opacity(0.04 + glowExpansion * 0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 108 + glowExpansion * 28
                            )
                        )
                        .frame(width: 176 + glowExpansion * 34, height: 42 + glowExpansion * 8)
                        .blur(radius: 24 + glowExpansion * 8)
                        .offset(y: 128)
                        .zIndex(0)

                    Ellipse()
                        .fill(Color.white.opacity(0.16 + glowExpansion * 0.04))
                        .frame(width: 146 + glowExpansion * 14, height: 22 + glowExpansion * 4)
                        .blur(radius: 18)
                        .offset(y: 118)
                        .zIndex(0)

                    BubbleSphereBase(phase: phase)
                        .equatable()
                        .zIndex(1)

                    BubbleLiquidLayer(
                        phase: phase,
                        progress: timer.progress(at: context.date),
                        isFinalDisplayedSecond: timer.formattedTime(at: context.date) == "00:01",
                        wavePhase: wavePhase,
                        glowExpansion: glowExpansion
                    )
                    .mask(BubbleGlassShape())
                    .zIndex(2)

                    BubbleLiquidStaticHighlights(phase: phase, sphereSize: sphereSize)
                        .equatable()
                        .zIndex(3)

                    BubbleSphereChrome(phase: phase, sphereSize: sphereSize)
                        .equatable()
                        .zIndex(4)
                }
                .drawingGroup(opaque: false)
            }

            ZStack {
                BubbleTimerDigitsView(phase: phase, timer: timer)
                .offset(y: -10)
                .zIndex(5)

                Button(action: action) {
                    Image(systemName: controlIconName)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.98),
                                    Color.white.opacity(colorScheme == .dark ? 0.82 : 0.90)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: Color.black.opacity(colorScheme == .dark ? 0.08 : 0.03),
                            radius: colorScheme == .dark ? 5 : 2,
                            y: colorScheme == .dark ? 2 : 1
                        )
                        .frame(width: 30, height: 30)
                        .background {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(colorScheme == .dark ? 0.10 : 0.08),
                                                    Color.white.opacity(colorScheme == .dark ? 0.02 : 0.01)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                .overlay {
                                    Circle()
                                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.40 : 0.46), lineWidth: 0.85)
                                }
                                .overlay(alignment: .top) {
                                    Circle()
                                        .trim(from: 0.12, to: 0.48)
                                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.22 : 0.24), lineWidth: 0.7)
                                        .blur(radius: 0.25)
                                }
                        }
                }
                .buttonStyle(.plain)
                .shadow(color: Color.white.opacity(colorScheme == .dark ? 0.08 : 0.06), radius: 5, y: -1)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.10 : 0.03), radius: 6, y: 2)
                .offset(y: 58)
                .zIndex(5)
            }
            .zIndex(5)
        }
        .frame(width: sphereSize, height: sphereSize)
        .onAppear {
            if timer.isAnimating && waveAnimationStart == nil {
                waveAnimationStart = .now
            }
        }
        .onChange(of: timer.isAnimating) { _, newValue in
            let now = Date.now
            if newValue {
                waveAnimationStart = now
            } else if let waveAnimationStart {
                accumulatedWaveTime += now.timeIntervalSince(waveAnimationStart)
                self.waveAnimationStart = nil
            }
        }
    }

    private var controlIconName: String {
        switch timer.actionTitle {
        case "Pause":
            return "pause.fill"
        case "Resume", "Start", "Start Again":
            return "play.fill"
        default:
            return "play.fill"
        }
    }

    private func currentWavePhase(now: Date) -> Double {
        let animatedDuration: TimeInterval
        if timer.isAnimating, let waveAnimationStart {
            animatedDuration = now.timeIntervalSince(waveAnimationStart)
        } else {
            animatedDuration = 0
        }

        return (accumulatedWaveTime + animatedDuration) * 1.15 * .pi
    }
}

private struct BubbleTimerDigitsView: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let timer: FocusTimerSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: timer.textRefreshInterval)) { context in
            let display = BubbleTimeDisplay(duration: timer.remainingDuration(at: context.date))

            ZStack {
                BubbleTimerTextLabel(display: display)
                    .foregroundStyle(Color.black.opacity(colorScheme == .dark ? 0.16 : 0.08))
                    .opacity(colorScheme == .dark ? 0.26 : 0.34)
                    .blur(radius: colorScheme == .dark ? 14 : 12)
                    .offset(y: colorScheme == .dark ? 7 : 5)

                BubbleTimerTextLabel(display: display)
                    .foregroundStyle(Color.black.opacity(colorScheme == .dark ? 0.12 : 0.035))
                    .opacity(colorScheme == .dark ? 0.78 : 0.56)
                    .blur(radius: colorScheme == .dark ? 12 : 7)
                    .offset(y: colorScheme == .dark ? 8 : 3)

                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(BubbleTimerTextLabel(display: display))
                    .opacity(colorScheme == .dark ? 0.93 : 0.88)

                BubbleTimerTextLabel(display: display)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.98 : 0.99),
                                Color.white.opacity(colorScheme == .dark ? 0.84 : 0.92),
                                phase.glassTint.opacity(colorScheme == .dark ? 0.38 : 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        BubbleTimerTextLabel(display: display)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.34 : 0.22),
                                        Color.white.opacity(colorScheme == .dark ? 0.10 : 0.04),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .mask(BubbleTimerTextLabel(display: display))
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.050 : 0.025),
                        radius: colorScheme == .dark ? 14 : 8,
                        y: colorScheme == .dark ? 6 : 3
                    )
                    .shadow(color: Color.white.opacity(colorScheme == .dark ? 0.08 : 0.10), radius: 5, y: -1)

                BubbleTimerTextLabel(display: display)
                    .foregroundStyle(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.10))
                    .blur(radius: 0.45)
                    .mask(alignment: .top) {
                        Rectangle()
                            .frame(height: 14)
                    }
            }
            .compositingGroup()
            .animation(.easeInOut(duration: 0.22), value: display.text)
        }
        .allowsHitTesting(false)
    }
}

private struct BubbleTimeDisplay: Equatable {
    let minutes: String
    let seconds: String

    init(duration: TimeInterval) {
        let totalSeconds = max(0, Int(duration.rounded()))
        let minuteValue = totalSeconds / 60
        let secondValue = totalSeconds % 60

        minutes = String(format: "%02d", minuteValue)
        seconds = String(format: "%02d", secondValue)
    }

    var text: String {
        "\(minutes):\(seconds)"
    }
}

private struct BubbleTimerTextLabel: View {
    let display: BubbleTimeDisplay

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            digitGroup(display.minutes)

            Text(":")
                .font(.system(size: 43, weight: .bold, design: .rounded))
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
            .font(.system(size: 58, weight: .heavy, design: .rounded))
            .fontWidth(.expanded)
    }
}

private struct BubbleSphereBase: View, Equatable {
    let phase: SessionPhase

    var body: some View {
        BubbleGlassShape()
            .fill(.ultraThinMaterial)
            .overlay {
                BubbleGlassShape()
                    .fill(phase.glassTint.opacity(0.24))
            }
    }
}

private struct BubbleLiquidStaticHighlights: View, Equatable {
    let phase: SessionPhase
    let sphereSize: CGFloat

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.34),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: sphereSize * 0.24
                    )
                )
                .frame(width: sphereSize * 0.44, height: sphereSize * 0.24)
                .blur(radius: 18)
                .offset(x: -sphereSize * 0.18, y: -sphereSize * 0.32)

            Ellipse()
                .fill(phase.shadowColor.opacity(0.18))
                .frame(width: sphereSize * 0.36, height: sphereSize * 0.08)
                .blur(radius: 16)
                .offset(y: sphereSize * 0.42)
        }
        .mask(BubbleGlassShape())
        .allowsHitTesting(false)
    }
}

private struct BubbleSphereChrome: View, Equatable {
    let phase: SessionPhase
    let sphereSize: CGFloat

    var body: some View {
        ZStack {
            BubbleGlassShape()
                .stroke(Color.white.opacity(0.62), lineWidth: 1)

            BubbleGlassShape()
                .stroke(Color.black.opacity(0.06), lineWidth: 18)
                .blur(radius: 18)
                .mask {
                    BubbleGlassShape()
                        .fill(
                            RadialGradient(
                                colors: [Color.black, Color.clear],
                                center: .top,
                                startRadius: 20,
                                endRadius: sphereSize * 0.62
                            )
                        )
                }

            BubbleGlassShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .blur(radius: 0.4)

            BubbleGlassShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.24),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask {
                    BubbleGlassShape()
                        .stroke(lineWidth: 12)
                }

            BubbleGlassShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.26),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 16)
                .padding(12)
                .offset(x: -20, y: -20)
        }
        .shadow(color: phase.shadowColor.opacity(0.08), radius: 28, y: 14)
        .shadow(color: Color.white.opacity(0.16), radius: 14, y: -8)
        .allowsHitTesting(false)
    }
}

private struct BubbleGlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect.insetBy(dx: 0.9, dy: 0.9))
    }
}

private struct BubbleLiquidLayer: View {
    let phase: SessionPhase
    let progress: Double
    let isFinalDisplayedSecond: Bool
    let wavePhase: Double
    let glowExpansion: Double

    var body: some View {
        GeometryReader { proxy in
            let normalizedProgress = max(0, min(progress, 1))
            let baseFillRatio = min(0.985, 0.10 + pow(normalizedProgress, 1.18) * 0.88)
            let terminalBoost = isFinalDisplayedSecond ? 0.048 : 0
            let visualFillRatio = min(1.035, baseFillRatio + terminalBoost)
            let amplitude = 4.2 + glowExpansion * 2.4

            Canvas(rendersAsynchronously: true) { context, canvasSize in
                let sphereRect = CGRect(origin: .zero, size: canvasSize)
                let spherePath = BubbleGlassShape().path(in: sphereRect)
                let waterlineY = sphereRect.maxY - sphereRect.height * CGFloat(visualFillRatio)

                context.clip(to: spherePath)

                context.fill(
                    spherePath,
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color.white.opacity(0.54), location: 0),
                            .init(color: Color.white.opacity(0.20), location: 0.34),
                            .init(color: Color(red: 0.93, green: 0.91, blue: 0.87).opacity(0.12), location: 0.74),
                            .init(color: Color(red: 0.84, green: 0.80, blue: 0.73).opacity(0.14), location: 1)
                        ]),
                        center: CGPoint(
                            x: sphereRect.minX + sphereRect.width * 0.32,
                            y: sphereRect.minY + sphereRect.height * 0.26
                        ),
                        startRadius: 0,
                        endRadius: sphereRect.width * 0.78
                    )
                )

                context.fill(
                    spherePath,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Color.white.opacity(0.08), location: 0),
                            .init(color: phase.glassTint.opacity(0.08), location: 0.48),
                            .init(color: Color.black.opacity(0.03), location: 1)
                        ]),
                        startPoint: CGPoint(x: sphereRect.midX, y: sphereRect.minY),
                        endPoint: CGPoint(x: sphereRect.midX, y: sphereRect.maxY)
                    )
                )

                let liquidPath = WaveLiquidShape(
                    fillRatio: visualFillRatio,
                    phase: wavePhase,
                    amplitude: amplitude
                ).path(in: sphereRect)

                context.fill(
                    liquidPath,
                    with: .linearGradient(
                        Gradient(colors: phase.liquidGradientColors),
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
                        Gradient(colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.04)
                        ]),
                        startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 8),
                        endPoint: CGPoint(x: sphereRect.midX, y: sphereRect.maxY)
                    )
                )

                var waterlineGlowContext = context
                waterlineGlowContext.addFilter(.blur(radius: 10))
                waterlineGlowContext.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: sphereRect.minX + sphereRect.width * 0.20 + CGFloat(sin(wavePhase)) * 14,
                            y: waterlineY - 8,
                            width: sphereRect.width * 0.42,
                            height: 16
                        )
                    ),
                    with: .color(Color.white.opacity(0.24))
                )

            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

private struct WaveLiquidShape: Shape {
    let fillRatio: Double
    let phase: Double
    let amplitude: Double

    func path(in rect: CGRect) -> Path {
        let clampedFill = max(0, min(fillRatio, 1))
        let baseY = rect.height * (1 - clampedFill)
        let mainAmplitude = min(rect.height * 0.06, amplitude)
        let width = rect.width
        let step = max(CGFloat(5.5), width / 34)

        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: baseY))

        var x: CGFloat = 0
        while x <= width {
            let relativeX = x / width
            let primaryAngle = Double(relativeX) * Double.pi * 2.1 + phase
            let secondaryAngle = Double(relativeX) * Double.pi * 4.3 + phase * 0.72
            let wave = CGFloat(sin(primaryAngle)) * mainAmplitude
            let secondaryWave = CGFloat(sin(secondaryAngle)) * mainAmplitude * 0.34
            let y = baseY + wave + secondaryWave
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private extension View {
    func liquidGlassSurface<S: Shape>(
        _ glass: Glass = .regular,
        in shape: S,
        stroke: Color = Color.white.opacity(0.36)
    ) -> some View {
        background {
            Color.clear
                .glassEffect(glass, in: shape)
        }
        .overlay {
            shape
                .stroke(stroke, lineWidth: 1)
        }
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
