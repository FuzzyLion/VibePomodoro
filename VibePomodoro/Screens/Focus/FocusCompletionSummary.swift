import SwiftUI

enum FocusCompletionMotion {
    static let backdropFadeDuration: Double = 0.34
    static let containerFadeInDuration: Double = 0.32
    static let containerFadeOutDuration: Double = 0.28
    static let badgeEntranceDuration: Double = 0.40
    static let contentEntranceDuration: Double = 0.42
    static let actionEntranceDuration: Double = 0.38
    static let badgeDismissDuration: Double = 0.30
    static let contentDismissDuration: Double = 0.32
    static let actionDismissDuration: Double = 0.26

    static let contentRevealDelay: UInt64 = 140_000_000
    static let actionRevealDelay: UInt64 = 120_000_000
    static let contentDismissDelay: UInt64 = 70_000_000
    static let dismissCompletionDelay: UInt64 = 240_000_000

    static func easeOutQuart(duration: Double) -> Animation {
        .timingCurve(0.25, 1, 0.5, 1, duration: duration)
    }

    static func easeOutQuint(duration: Double) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }

    static var backdropAnimation: Animation {
        easeOutQuart(duration: backdropFadeDuration)
    }

    static var containerFadeInAnimation: Animation {
        easeOutQuart(duration: containerFadeInDuration)
    }

    static var containerFadeOutAnimation: Animation {
        easeOutQuart(duration: containerFadeOutDuration)
    }

    static var badgeAnimation: Animation {
        easeOutQuint(duration: badgeEntranceDuration)
    }

    static var contentAnimation: Animation {
        easeOutQuint(duration: contentEntranceDuration)
    }

    static var actionAnimation: Animation {
        easeOutQuint(duration: actionEntranceDuration)
    }

    static var badgeDismissAnimation: Animation {
        easeOutQuart(duration: badgeDismissDuration)
    }

    static var contentDismissAnimation: Animation {
        easeOutQuart(duration: contentDismissDuration)
    }

    static var actionDismissAnimation: Animation {
        easeOutQuart(duration: actionDismissDuration)
    }
}

struct FocusCompletionSummaryState: Equatable {
    let title: String
    let message: String?
    let focusTimeText: String
    let focusTimeAccessibilityText: String
    let breakTimeText: String
    let breakTimeAccessibilityText: String
    let completedFocusText: String
    let completedFocusAccessibilityText: String

    init?(session: SessionSnapshot?) {
        guard let session, session.runState == .completed else { return nil }

        let statistics = session.statistics(now: .now)
        let isFinishedEarly = session.currentStepIndex < session.steps.count
        let completedFocusCount = statistics.completedFocusCount

        title = isFinishedEarly ? "Session finished" : "Session complete"
        message = isFinishedEarly ? "Saved what you completed so far." : nil
        focusTimeText = FocusCompletionFormatting.durationText(statistics.focusTime)
        focusTimeAccessibilityText = FocusCompletionFormatting.accessibilityDurationText(statistics.focusTime)
        breakTimeText = FocusCompletionFormatting.durationText(statistics.breakTime)
        breakTimeAccessibilityText = FocusCompletionFormatting.accessibilityDurationText(statistics.breakTime)
        completedFocusText = completedFocusCount == 0
            ? "No full focus blocks completed yet"
            : completedFocusCount == 1
                ? "1 focus block completed"
                : "\(completedFocusCount) focus blocks completed"
        completedFocusAccessibilityText = completedFocusCount == 0
            ? "No full focus blocks completed yet"
            : completedFocusCount == 1
                ? "1 focus block completed"
                : "\(completedFocusCount) focus blocks completed"
    }

    static func make(from session: SessionSnapshot) -> FocusCompletionSummaryState {
        FocusCompletionSummaryState(session: session)!
    }
}

struct FocusCompletionSummaryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var backdropProgress: CGFloat = 0
    @State private var badgeRevealProgress: CGFloat = 0
    @State private var contentRevealProgress: CGFloat = 0
    @State private var actionRevealProgress: CGFloat = 0
    @State private var isDismissing = false
    @State private var entranceTask: Task<Void, Never>?

    let state: FocusCompletionSummaryState
    let doneAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CompletionBackdropVeil(progress: backdropProgress)

                VStack(spacing: 0) {
                    Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 34 : 54)

                    FocusCompletionBadge(
                        revealProgress: badgeRevealProgress
                    )

                    VStack(spacing: state.message == nil ? 0 : 10) {
                        Text(state.title)
                            .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 30 : 34, weight: .semibold))
                            .foregroundStyle(titleColor)
                            .multilineTextAlignment(.center)

                        if let message = state.message {
                            Text(message)
                                .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 16 : 15, weight: .medium))
                                .foregroundStyle(messageColor)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .opacity(Double(contentRevealProgress))
                    .offset(y: (1 - contentRevealProgress) * 8)
                    .mask(CompletionVerticalRevealMask(progress: contentRevealProgress))
                    .padding(.top, dynamicTypeSize.isAccessibilitySize ? 20 : 22)

                    FocusCompletionSummaryCard(state: state)
                        .opacity(Double(contentRevealProgress))
                        .offset(y: (1 - contentRevealProgress) * 12)
                        .padding(.top, state.message == nil ? 20 : 24)

                    Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 28 : 34)

                    FocusCompletionDoneButton(action: beginDismissal)
                        .frame(width: doneButtonWidth(for: proxy.size.width))
                        .opacity(Double(actionRevealProgress))
                        .offset(y: (1 - actionRevealProgress) * 10)
                        .allowsHitTesting(actionRevealProgress > 0.96 && !isDismissing)
                        .padding(.bottom, bottomActionPadding(for: proxy.safeAreaInsets.bottom))
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            runEntranceAnimation()
        }
        .onDisappear {
            entranceTask?.cancel()
            entranceTask = nil
            resetEntranceState()
        }
    }

    private var titleColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.96)
            : Color.black.opacity(0.78)
    }

    private var messageColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.72)
            : Color.black.opacity(0.50)
    }

    private func bottomActionPadding(for bottomInset: CGFloat) -> CGFloat {
        let basePadding = dynamicTypeSize.isAccessibilitySize ? 10.0 : 6.0
        return max(bottomInset, dynamicTypeSize.isAccessibilitySize ? 20.0 : 12.0) + basePadding
    }

    private func doneButtonWidth(for containerWidth: CGFloat) -> CGFloat {
        let availableWidth = max(0, containerWidth - 48)
        let preferredWidth = availableWidth * 0.56
        let clampedWidth = min(192, max(160, preferredWidth))
        return min(availableWidth, clampedWidth)
    }

    private func runEntranceAnimation() {
        entranceTask?.cancel()
        entranceTask = nil
        resetEntranceState()

        guard !reduceMotion else {
            backdropProgress = 1
            badgeRevealProgress = 1
            contentRevealProgress = 1
            actionRevealProgress = 1
            return
        }

        entranceTask = Task { @MainActor in
            await Task.yield()

            withAnimation(FocusCompletionMotion.backdropAnimation) {
                backdropProgress = 1
            }

            withAnimation(FocusCompletionMotion.badgeAnimation) {
                badgeRevealProgress = 1
            }

            try? await Task.sleep(nanoseconds: FocusCompletionMotion.contentRevealDelay)
            guard !Task.isCancelled else { return }

            withAnimation(FocusCompletionMotion.contentAnimation) {
                contentRevealProgress = 1
            }

            try? await Task.sleep(nanoseconds: FocusCompletionMotion.actionRevealDelay)
            guard !Task.isCancelled else { return }

            withAnimation(FocusCompletionMotion.actionAnimation) {
                actionRevealProgress = 1
            }
        }
    }

    private func beginDismissal() {
        guard !isDismissing else { return }

        entranceTask?.cancel()
        entranceTask = nil

        guard !reduceMotion else {
            doneAction()
            return
        }

        isDismissing = true
        entranceTask = Task { @MainActor in
            withAnimation(FocusCompletionMotion.actionDismissAnimation) {
                actionRevealProgress = 0
            }

            try? await Task.sleep(nanoseconds: FocusCompletionMotion.contentDismissDelay)
            guard !Task.isCancelled else { return }

            withAnimation(FocusCompletionMotion.contentDismissAnimation) {
                contentRevealProgress = 0
                badgeRevealProgress = 0
            }

            withAnimation(FocusCompletionMotion.backdropAnimation) {
                backdropProgress = 0
            }

            try? await Task.sleep(nanoseconds: FocusCompletionMotion.dismissCompletionDelay)
            guard !Task.isCancelled else { return }
            doneAction()
        }
    }

    private func resetEntranceState() {
        backdropProgress = 0
        badgeRevealProgress = 0
        contentRevealProgress = 0
        actionRevealProgress = 0
        isDismissing = false
    }
}

private struct FocusCompletionBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let revealProgress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    VibePalette.softMist.opacity(colorScheme == .dark ? 0.28 : 0.22),
                                    VibePalette.softJade.opacity(colorScheme == .dark ? 0.22 : 0.18),
                                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
}

private struct CompletionBackdropVeil: View {
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

private struct CompletionVerticalRevealMask: View {
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

private struct FocusCompletionSummaryCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let state: FocusCompletionSummaryState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            summaryRow(
                title: "Focus Time",
                value: state.focusTimeText,
                accessibilityValue: state.focusTimeAccessibilityText,
                systemImage: "timer.circle.fill",
                accent: focusAccent,
                topPadding: dynamicTypeSize.isAccessibilitySize ? 10 : 8,
                bottomPadding: dynamicTypeSize.isAccessibilitySize ? 14 : 16
            )

            divider

            summaryRow(
                title: "Break Time",
                value: state.breakTimeText,
                accessibilityValue: state.breakTimeAccessibilityText,
                systemImage: "cup.and.saucer.fill",
                accent: breakAccent,
                topPadding: dynamicTypeSize.isAccessibilitySize ? 14 : 16,
                bottomPadding: dynamicTypeSize.isAccessibilitySize ? 14 : 16
            )

            divider

            Text(state.completedFocusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(footerColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
                .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 2 : 4)
                .accessibilityLabel(state.completedFocusAccessibilityText)
        }
        .padding(.horizontal, 20)
        .padding(.top, dynamicTypeSize.isAccessibilitySize ? 14 : 12)
        .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 18 : 20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.22),
                                    Color.white.opacity(colorScheme == .dark ? 0.015 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.58), lineWidth: 0.85)
                }
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.06),
            radius: colorScheme == .dark ? 18 : 12,
            y: colorScheme == .dark ? 10 : 6
        )
    }

    private func summaryRow(
        title: String,
        value: String,
        accessibilityValue: String,
        systemImage: String,
        accent: Color,
        topPadding: CGFloat,
        bottomPadding: CGFloat
    ) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(labelColor)

                Text(value)
                    .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 28 : 30, weight: .semibold))
                    .foregroundStyle(valueColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 12)
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.40))
            .frame(height: 1)
    }

    private var labelColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.76)
            : Color.black.opacity(0.52)
    }

    private var valueColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.96)
            : Color.black.opacity(0.82)
    }

    private var footerColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.62)
            : Color.black.opacity(0.44)
    }

    private var focusAccent: Color {
        colorScheme == .dark ? VibePalette.softMist : VibePalette.softMistDeep
    }

    private var breakAccent: Color {
        colorScheme == .dark ? VibePalette.warmAmberAccent : VibePalette.warmAmberAccentDeep
    }
}

private struct FocusCompletionDoneButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Done")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(buttonTextColor)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule(style: .continuous)
                                .fill(buttonSurfaceTint)
                        }
                        .overlay {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.42), lineWidth: 0.9)
                        }
                }
        }
        .buttonStyle(.plain)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.14 : 0.06),
            radius: colorScheme == .dark ? 14 : 10,
            y: colorScheme == .dark ? 7 : 5
        )
    }

    private var buttonTextColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.96)
            : Color.black.opacity(0.72)
    }

    private var buttonSurfaceTint: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.white.opacity(0.22)
    }
}

private enum FocusCompletionFormatting {
    static func durationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "\(seconds)s"
    }

    static func accessibilityDurationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hourText(hours)) \(minuteText(minutes))"
            }
            return hourText(hours)
        }
        if minutes > 0 {
            if seconds > 0 {
                return "\(minuteText(minutes)) \(secondText(seconds))"
            }
            return minuteText(minutes)
        }
        return secondText(seconds)
    }

    private static func hourText(_ count: Int) -> String {
        count == 1 ? "1 hour" : "\(count) hours"
    }

    private static func minuteText(_ count: Int) -> String {
        count == 1 ? "1 minute" : "\(count) minutes"
    }

    private static func secondText(_ count: Int) -> String {
        count == 1 ? "1 second" : "\(count) seconds"
    }
}
