import SwiftUI

struct BubbleRenderState: Equatable {
    let phase: SessionPhase
    let actionTitle: String
    let targetEndDate: Date?
    let remainingDuration: TimeInterval
    let progress: Double
    let plannedDuration: TimeInterval
    let isAnimating: Bool
    let shouldTickSeconds: Bool

    var animationRefreshInterval: TimeInterval {
        isAnimating ? 1.0 / 12.0 : 60.0
    }

    var textRefreshInterval: TimeInterval {
        shouldTickSeconds ? 1.0 : 60.0
    }

    func remainingDuration(at now: Date) -> TimeInterval {
        guard shouldTickSeconds, let targetEndDate else { return remainingDuration }
        return max(0, targetEndDate.timeIntervalSince(now))
    }

    func progress(at now: Date) -> Double {
        guard shouldTickSeconds, plannedDuration > 0 else { return progress }
        let dynamicRemainingDuration = remainingDuration(at: now)
        return min(1, max(0, 1 - (dynamicRemainingDuration / plannedDuration)))
    }

    func timeText(at now: Date) -> String {
        Self.formattedTime(remainingDuration(at: now))
    }

    func isFinalDisplayedSecond(at now: Date) -> Bool {
        timeText(at: now) == "00:01"
    }

    private static func formattedTime(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct FocusRenderState: Equatable {
    let phase: SessionPhase
    let statusText: String
    let canSkip: Bool
    let canReset: Bool
    let canGoBack: Bool
    let shouldShowBackAction: Bool
    let nodeStates: [SessionProgressNodeState]
    let bubble: BubbleRenderState

    @MainActor
    static func build(store: PomodoroStore, scenePhase: ScenePhase) -> FocusRenderState {
        let session = store.activeSession
        let phase = session?.currentPhase ?? .focus
        let hasElapsedTime = session.map(Self.hasElapsedTime) ?? false
        let canGoBack = session.map { $0.currentStepIndex > 0 || hasElapsedTime } ?? false
        let shouldShowBackAction = session.map { session in
            switch session.runState {
            case .idle:
                return hasElapsedTime
            case .running, .paused, .completed:
                return true
            }
        } ?? false
        let canReset = session.map(Self.canResetCurrentStep) ?? false
        let runState = session?.runState ?? .idle
        let isFocusVisible = scenePhase == .active && store.selectedTab == .focus
        let isAnimating = isFocusVisible && runState == .running
        let shouldTickSeconds = isFocusVisible && runState == .running
        let plannedDuration = session?.currentStep?.plannedDuration ?? store.settings.focusDuration

        return FocusRenderState(
            phase: phase,
            statusText: statusText(for: session, phase: phase),
            canSkip: session?.currentStep != nil,
            canReset: canReset,
            canGoBack: canGoBack,
            shouldShowBackAction: shouldShowBackAction,
            nodeStates: nodeStates(for: session, fallbackRounds: store.settings.targetRounds),
            bubble: BubbleRenderState(
                phase: phase,
                actionTitle: primaryActionTitle(for: runState, hasSession: session != nil),
                targetEndDate: session?.targetEndDate,
                remainingDuration: store.remainingDuration(),
                progress: store.elapsedRatio(),
                plannedDuration: plannedDuration,
                isAnimating: isAnimating,
                shouldTickSeconds: shouldTickSeconds
            )
        )
    }

    @MainActor
    private static func primaryActionTitle(for runState: SessionRunState, hasSession: Bool) -> String {
        guard hasSession else { return "Start" }

        switch runState {
        case .idle:
            return "Start"
        case .running:
            return "Pause"
        case .paused:
            return "Resume"
        case .completed:
            return "Start Again"
        }
    }

    @MainActor
    private static func statusText(for session: SessionSnapshot?, phase: SessionPhase) -> String {
        guard let session else { return "READY" }
        guard session.runState != .completed else { return "COMPLETE" }

        switch phase {
        case .focus:
            return "FOCUS"
        case .shortBreak:
            return "SHORT BREAK"
        case .longBreak:
            return "LONG BREAK"
        }
    }

    @MainActor
    private static func canResetCurrentStep(for session: SessionSnapshot) -> Bool {
        guard session.runState != .completed,
              let step = session.currentStep else { return false }

        return session.runState == .running
            || session.runState == .paused
            || session.accumulatedDuration(for: step) > 0
    }

    @MainActor
    private static func hasElapsedTime(for session: SessionSnapshot) -> Bool {
        if !session.segments.isEmpty {
            return true
        }

        guard session.runState == .running,
              let currentSegmentStartDate = session.currentSegmentStartDate else {
            return false
        }

        return Date.now > currentSegmentStartDate
    }

    @MainActor
    private static func nodeStates(
        for session: SessionSnapshot?,
        fallbackRounds: Int
    ) -> [SessionProgressNodeState] {
        let totalRounds = max(1, session?.targetRounds ?? fallbackRounds)

        guard let session else {
            return (1...totalRounds).map { $0 == 1 ? .half : .inactive }
        }

        if session.runState == .completed {
            return Array(repeating: .filled, count: totalRounds)
        }

        let currentRound = session.currentStep?.roundNumber ?? 1
        let currentPhase = session.currentPhase ?? .focus

        return (1...totalRounds).map { round in
            if round < currentRound {
                return .filled
            }

            if round == currentRound {
                return currentPhase == .focus ? .half : .filled
            }

            return .inactive
        }
    }
}

struct FocusScreen: View {
    @EnvironmentObject private var store: PomodoroStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let compactLayout = size.height < 760
            let topSpacing = compactLayout ? max(56, size.height * 0.13) : max(74, size.height * 0.16)
            let renderState = FocusRenderState.build(store: store, scenePhase: scenePhase)

            VStack(spacing: compactLayout ? 18 : 24) {
                Spacer(minLength: topSpacing)

                PhaseStatusBadge(text: renderState.statusText, phase: renderState.phase)
                    .fixedSize(horizontal: true, vertical: false)

                BubbleTimerView(
                    renderState: renderState.bubble,
                    action: store.togglePrimaryAction
                )
                .frame(width: 280, height: 280)
                .padding(.top, compactLayout ? 10 : 18)

                SessionProgressPill(
                    phase: renderState.phase,
                    nodeStates: renderState.nodeStates
                )
                .fixedSize(horizontal: true, vertical: false)
                .padding(.top, compactLayout ? 0 : 6)

                HStack(spacing: 16) {
                    SecondaryActionButton(
                        title: "Skip",
                        systemImage: "forward.end",
                        isEnabled: renderState.canSkip,
                        glassTint: renderState.phase.glassTint,
                        action: store.skipCurrentStep
                    )
                    .frame(maxWidth: .infinity)

                    SecondaryActionButton(
                        title: "Reset",
                        systemImage: "arrow.counterclockwise",
                        isEnabled: renderState.canReset,
                        glassTint: renderState.phase.glassTint,
                        action: store.resetCurrentStep
                    )
                    .frame(maxWidth: .infinity)
                }
                .frame(width: 261.29)
                .padding(.top, compactLayout ? 6 : 12)

                if renderState.shouldShowBackAction {
                    TertiaryActionButton(
                        title: "Back to last step",
                        systemImage: "chevron.left",
                        isEnabled: renderState.canGoBack,
                        action: store.goBackOneStep
                    )
                    .padding(.top, compactLayout ? -2 : 0)
                }

                Spacer(minLength: max(72, size.height * 0.18))
            }
            .padding(.horizontal, 24)
            .frame(width: size.width, height: size.height, alignment: .top)
        }
    }
}

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
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.022 : 0.035), radius: colorScheme == .dark ? 4 : 6, y: 1)
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
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.02 : 0.03), radius: colorScheme == .dark ? 6 : 8, y: colorScheme == .dark ? 1 : 2)
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
                .foregroundStyle(isEnabled ? VibePalette.glassTextSoft(for: colorScheme) : VibePalette.labelSecondary.opacity(0.68))
            }
            .frame(maxWidth: .infinity, minHeight: 50.5, maxHeight: 50.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.035 : 0.03), radius: colorScheme == .dark ? 3 : 4, y: colorScheme == .dark ? 1 : 2)
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
                        Color.white.opacity(colorScheme == .dark ? darkStrokeOpacity * 0.84 : lightStrokeOpacity),
                        lineWidth: 0.9
                    )
            }
    }
}

private struct GlassCircleShell: View {
    @Environment(\.colorScheme) private var colorScheme

    let tint: Color
    var material: Material = .thinMaterial
    var darkStrokeOpacity: Double = 0.38
    var lightStrokeOpacity: Double = 0.44

    var body: some View {
        Circle()
            .fill(material)
            .overlay {
                Circle()
                    .fill(colorScheme == .dark ? tint.opacity(0.70) : tint)
            }
            .overlay {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.03),
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
                        Color.white.opacity(colorScheme == .dark ? darkStrokeOpacity * 0.84 : lightStrokeOpacity),
                        lineWidth: 0.85
                    )
            }
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
    let renderState: BubbleRenderState
    let action: () -> Void

    @State private var accumulatedWaveTime: TimeInterval = 0
    @State private var waveAnimationStart: Date?

    var body: some View {
        let sphereSize: CGFloat = 280
        let waveClock = BubbleWaveClock(
            accumulatedWaveTime: accumulatedWaveTime,
            waveAnimationStart: waveAnimationStart,
            isAnimating: renderState.isAnimating
        )

        ZStack {
            BubbleGlassShell(phase: renderState.phase, sphereSize: sphereSize)
            BubbleAnimatedSurfaceLayer(renderState: renderState, waveClock: waveClock)
            BubbleForegroundContent(renderState: renderState, action: action)
        }
        .frame(width: sphereSize, height: sphereSize)
        .onAppear {
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

        return (accumulatedWaveTime + animatedDuration) * 1.15 * .pi
    }
}

private struct BubbleAnimatedSurfaceLayer: View {
    let renderState: BubbleRenderState
    let waveClock: BubbleWaveClock

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
        let glowExpansion = 0.52 + (sin(wavePhase * 0.75) + 1) * 0.24

        ZStack {
            BubbleGlowBackdrop(phase: renderState.phase, glowExpansion: glowExpansion)

            BubbleLiquidLayer(
                phase: renderState.phase,
                progress: renderState.progress(at: date),
                isFinalDisplayedSecond: renderState.isFinalDisplayedSecond(at: date),
                wavePhase: wavePhase,
                glowExpansion: glowExpansion
            )
            .mask(BubbleGlassShape())
        }
    }
}

private struct BubbleForegroundContent: View {
    let renderState: BubbleRenderState
    let action: () -> Void

    var body: some View {
        BubbleTimerDigitsView(renderState: renderState)
            .frame(maxWidth: 208)
            .offset(y: -10)
            .overlay(alignment: .center) {
                BubbleControlButton(actionTitle: renderState.actionTitle, action: action)
                    .offset(y: 58)
            }
    }
}

private struct BubbleTimerDigitsView: View {
    @Environment(\.colorScheme) private var colorScheme

    let renderState: BubbleRenderState

    var body: some View {
        Group {
            if renderState.shouldTickSeconds {
                TimelineView(.periodic(from: .now, by: renderState.textRefreshInterval)) { context in
                    digits(for: renderState.timeText(at: context.date))
                }
            } else {
                digits(for: renderState.timeText(at: .now))
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func digits(for timeText: String) -> some View {
        let display = BubbleTimeDisplay(text: timeText)
        let textLabel = BubbleTimerTextLabel(display: display)
            .padding(.horizontal, 2)
            .padding(.vertical, 6)

        if colorScheme == .light {
            textLabel
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.56, green: 0.57, blue: 0.60),
                            Color(red: 0.46, green: 0.47, blue: 0.50),
                            Color(red: 0.31, green: 0.32, blue: 0.35)
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
                                    Color.white.opacity(0.30),
                                    Color.white.opacity(0.09),
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
                        .foregroundStyle(Color.white.opacity(0.10))
                        .blur(radius: 0.32)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 14)
                        }
                }
                .drawingGroup(opaque: false, colorMode: .linear)
        } else {
            textLabel
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98),
                            Color.white.opacity(0.84),
                            renderState.phase.glassTint.opacity(0.38)
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
                                    Color.white.opacity(0.34),
                                    Color.white.opacity(0.10),
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
                        .foregroundStyle(Color.white.opacity(0.12))
                        .blur(radius: 0.45)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 14)
                        }
                }
                .drawingGroup(opaque: false, colorMode: .linear)
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

private struct BubbleControlButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let actionTitle: String
    let action: () -> Void

    var body: some View {
        let symbol = Image(systemName: controlIconName)
            .font(.system(size: 13, weight: .heavy))

        Button(action: action) {
            symbol
                .foregroundStyle(iconForegroundStyle)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.05 : 0),
                    radius: colorScheme == .dark ? 4 : 0,
                    y: colorScheme == .dark ? 1.5 : 0
                )
                .frame(width: 30, height: 30)
                .background {
                    GlassCircleShell(
                        tint: Color.white.opacity(colorScheme == .dark ? 0.03 : 0.03)
                    )
                }
        }
        .buttonStyle(.plain)
        .shadow(color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.06), radius: colorScheme == .dark ? 3 : 4, y: -1)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.06 : 0.03), radius: colorScheme == .dark ? 4 : 5, y: colorScheme == .dark ? 1.5 : 2)
    }

    private var controlIconName: String {
        switch actionTitle {
        case "Pause":
            return "pause.fill"
        case "Resume", "Start", "Start Again":
            return "play.fill"
        default:
            return "play.fill"
        }
    }

    private var iconForegroundStyle: AnyShapeStyle {
        if colorScheme == .light {
            return AnyShapeStyle(Color(red: 0.36, green: 0.37, blue: 0.40))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color.white.opacity(0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct BubbleGlassShell: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let sphereSize: CGFloat

    var body: some View {
        let isDark = colorScheme == .dark

        ZStack {
            if isDark {
                BubbleGlassShape()
                    .fill(.thinMaterial)

                BubbleGlassShape()
                    .fill(Color.white.opacity(0.045))

                BubbleGlassShape()
                    .fill(phase.glassTint.opacity(0.12))

                BubbleGlassShape()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.21),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: sphereSize * 0.62
                        )
                    )

                BubbleGlassShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.018),
                                Color.black.opacity(0.024)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                BubbleGlassShape()
                    .stroke(Color.white.opacity(0.42), lineWidth: 1)

                BubbleGlassShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.34),
                                Color.white.opacity(0.06),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.15
                    )
                    .blur(radius: 0.35)

                BubbleGlassShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask {
                        BubbleGlassShape()
                            .stroke(lineWidth: 10)
                    }

                Ellipse()
                    .fill(phase.shadowColor.opacity(0.07))
                    .frame(width: sphereSize * 0.34, height: sphereSize * 0.06)
                    .blur(radius: 10)
                    .offset(y: sphereSize * 0.38)
                    .mask(BubbleGlassShape())
            } else {
                BubbleGlassShape()
                    .fill(Color(red: 0.90, green: 0.91, blue: 0.93).opacity(0.235))

                BubbleGlassShape()
                    .fill(Color.white.opacity(0.052))

                BubbleGlassShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color(red: 0.92, green: 0.93, blue: 0.95).opacity(0.17),
                                phase.tintColor.opacity(0.016)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                BubbleGlassShape()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.23),
                                Color.white.opacity(0.085),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: sphereSize * 0.76
                        )
                    )

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.085),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: sphereSize * 0.24
                        )
                    )
                    .frame(width: sphereSize * 0.40, height: sphereSize * 0.20)
                    .blur(radius: 14)
                    .offset(x: -sphereSize * 0.16, y: -sphereSize * 0.30)
                    .mask(BubbleGlassShape())

                BubbleGlassShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.90, green: 0.91, blue: 0.93).opacity(0.105),
                                Color.white.opacity(0.030),
                                Color.clear,
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                BubbleGlassShape()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.88, green: 0.89, blue: 0.91).opacity(0.09),
                                phase.tintColor.opacity(0.020),
                                Color.clear
                            ],
                            center: .bottom,
                            startRadius: sphereSize * 0.10,
                            endRadius: sphereSize * 0.54
                        )
                    )

                BubbleGlassShape()
                    .stroke(Color.white.opacity(0.72), lineWidth: 1.15)

                BubbleGlassShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.54),
                                Color(red: 0.84, green: 0.86, blue: 0.90).opacity(0.20),
                                Color.black.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
                    .blur(radius: 0.25)

                BubbleGlassShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask {
                        BubbleGlassShape()
                            .stroke(lineWidth: 10)
                    }

                BubbleGlassShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.022)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask {
                        BubbleGlassShape()
                            .stroke(lineWidth: 12)
                    }

                Ellipse()
                    .fill(Color.white.opacity(0.018))
                    .frame(width: sphereSize * 0.36, height: sphereSize * 0.07)
                    .blur(radius: 11)
                    .offset(y: sphereSize * 0.34)
                    .mask(BubbleGlassShape())
            }
        }
        .drawingGroup(opaque: false, colorMode: .linear)
        .shadow(color: phase.shadowColor.opacity(isDark ? 0.052 : 0.005), radius: isDark ? 18 : 8, y: isDark ? 9 : 3)
        .shadow(color: Color.white.opacity(isDark ? 0.06 : 0.10), radius: isDark ? 8 : 9, y: -3)
        .allowsHitTesting(false)
    }
}

private struct BubbleGlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect.insetBy(dx: 0.9, dy: 0.9))
    }
}

private struct BubbleGlowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let glowExpansion: Double

    var body: some View {
        ZStack {
            BubbleGlassShape()
                .stroke(
                    phase.shadowColor.opacity(colorScheme == .dark ? 0.045 + glowExpansion * 0.009 : 0.018 + glowExpansion * 0.005),
                    lineWidth: colorScheme == .dark ? 13 : 11
                )
                .blur(radius: colorScheme == .dark ? 7.5 : 5.5)
                .scaleEffect(colorScheme == .dark ? 1.026 : 1.02)

            BubbleGlassShape()
                .stroke(
                    Color.white.opacity(colorScheme == .dark ? 0.020 + glowExpansion * 0.003 : 0.020 + glowExpansion * 0.004),
                    lineWidth: colorScheme == .dark ? 4.5 : 3.5
                )
                .blur(radius: colorScheme == .dark ? 3.2 : 3.5)
                .scaleEffect(colorScheme == .dark ? 1.012 : 1.01)
                .offset(y: colorScheme == .dark ? -1 : -2)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            phase.shadowColor.opacity(colorScheme == .dark ? 0.08 + glowExpansion * 0.05 : 0.08 + glowExpansion * 0.04),
                            phase.shadowColor.opacity(colorScheme == .dark ? 0.024 + glowExpansion * 0.018 : 0.024 + glowExpansion * 0.015),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 100 + glowExpansion * 24
                    )
                )
                .frame(width: 168 + glowExpansion * 28, height: 38 + glowExpansion * 7)
                .blur(radius: colorScheme == .dark ? 16 + glowExpansion * 5 : 16 + glowExpansion * 4)
                .offset(y: 126)

            Ellipse()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.06 + glowExpansion * 0.02 : 0.04 + glowExpansion * 0.015))
                .frame(width: 138 + glowExpansion * 10, height: 18 + glowExpansion * 3)
                .blur(radius: colorScheme == .dark ? 9 : 8)
                .offset(y: 118)
        }
    }
}

private struct BubbleLiquidLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: SessionPhase
    let progress: Double
    let isFinalDisplayedSecond: Bool
    let wavePhase: Double
    let glowExpansion: Double

    var body: some View {
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

            let secondaryLiquidPath = WaveLiquidShape(
                fillRatio: min(1, visualFillRatio + 0.012),
                phase: wavePhase * 1.08 + .pi / 5,
                amplitude: amplitude * 0.55
            ).path(in: sphereRect)

            context.fill(
                secondaryLiquidPath,
                with: .linearGradient(
                    Gradient(colors: secondaryLiquidGradientColors),
                    startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 14),
                    endPoint: CGPoint(x: sphereRect.midX, y: sphereRect.maxY)
                )
            )

            if colorScheme == .dark {
                var waterlineGlowContext = context
                waterlineGlowContext.addFilter(.blur(radius: 12))
                waterlineGlowContext.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: sphereRect.minX + sphereRect.width * 0.10,
                            y: waterlineY - 6,
                            width: sphereRect.width * 0.80,
                            height: 14
                        )
                    ),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.16),
                            Color.white.opacity(0.08),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: sphereRect.midX, y: waterlineY - 10),
                        endPoint: CGPoint(x: sphereRect.midX, y: waterlineY + 10)
                    )
                )
            } else {
                var waterlineGlowContext = context
                waterlineGlowContext.addFilter(.blur(radius: 9))
                waterlineGlowContext.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: sphereRect.minX + sphereRect.width * 0.12,
                            y: waterlineY - 5,
                            width: sphereRect.width * 0.76,
                            height: 11
                        )
                    ),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.12),
                            phase.tintColor.opacity(0.06),
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
                Color.white.opacity(0.12),
                Color.white.opacity(0.05),
                Color.clear
            ]
        }

        return [
            Color.white.opacity(0.16),
            phase.tintColor.opacity(0.16),
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
            let primaryAngle = Double(relativeX) * Double.pi * 2.1 + phase
            let secondaryAngle = Double(relativeX) * Double.pi * 4.3 + phase * 0.72
            let wave = CGFloat(sin(primaryAngle)) * mainAmplitude
            let secondaryWave = CGFloat(sin(secondaryAngle)) * mainAmplitude * 0.34
            let y = baseY + wave + secondaryWave
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: endX, y: rect.height))
        path.closeSubpath()
        return path
    }
}
