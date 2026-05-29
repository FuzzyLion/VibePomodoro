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
        let preferredWidth = availableWidth * 0.52
        let clampedWidth = min(176, max(148, preferredWidth))
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
