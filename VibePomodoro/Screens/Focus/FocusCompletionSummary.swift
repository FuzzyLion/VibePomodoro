import SwiftUI

struct FocusCompletionSummaryState: Equatable {
    let title: String
    let message: String
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
        message = isFinishedEarly
            ? "Saved what you completed so far."
            : "Your focus and break time have been saved."
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

    let state: FocusCompletionSummaryState
    let doneAction: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .opacity(colorScheme == .dark ? 0.16 : 0.06)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 44 : 72)

                FocusCompletionBadge()

                VStack(spacing: 10) {
                    Text(state.title)
                        .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 30 : 34, weight: .semibold))
                        .foregroundStyle(titleColor)
                        .multilineTextAlignment(.center)

                    Text(state.message)
                        .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 16 : 15, weight: .medium))
                        .foregroundStyle(messageColor)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 26)

                FocusCompletionSummaryCard(state: state)
                    .padding(.top, 28)

                Spacer(minLength: 40)

                FocusCompletionDoneButton(action: doneAction)
                    .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 20 : 12)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
}

private struct FocusCompletionBadge: View {
    @Environment(\.colorScheme) private var colorScheme

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
        .shadow(
            color: VibePalette.softJadeDeep.opacity(colorScheme == .dark ? 0.18 : 0.10),
            radius: colorScheme == .dark ? 20 : 14,
            y: colorScheme == .dark ? 8 : 6
        )
        .accessibilityHidden(true)
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
                accent: focusAccent
            )

            divider

            summaryRow(
                title: "Break Time",
                value: state.breakTimeText,
                accessibilityValue: state.breakTimeAccessibilityText,
                systemImage: "cup.and.saucer.fill",
                accent: breakAccent
            )

            divider

            Text(state.completedFocusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(footerColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
                .accessibilityLabel(state.completedFocusAccessibilityText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 18 : 20)
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
        accent: Color
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
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 14 : 16)
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
                .frame(maxWidth: .infinity, minHeight: 58)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.thinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(buttonSurface)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.20 : 0.46), lineWidth: 0.9)
                        }
                }
        }
        .buttonStyle(.plain)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.08),
            radius: colorScheme == .dark ? 18 : 12,
            y: colorScheme == .dark ? 10 : 6
        )
    }

    private var buttonTextColor: Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(0.96)
            : Color.black.opacity(0.76)
    }

    private var buttonSurface: LinearGradient {
        LinearGradient(
            colors: [
                VibePalette.softMist.opacity(colorScheme == .dark ? 0.26 : 0.20),
                VibePalette.softJade.opacity(colorScheme == .dark ? 0.22 : 0.16),
                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
