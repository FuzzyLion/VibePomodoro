import SwiftUI

struct FocusCompletionSummaryCard: View {
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
        }
        .padding(.horizontal, 20)
        .padding(.top, dynamicTypeSize.isAccessibilitySize ? 14 : 12)
        .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 18 : 20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(summaryCardGradient)
        }
        .glassEffect(.regular.tint(summaryCardGlassTint), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.58), lineWidth: 0.85)
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

    // Same meaning as everywhere else: amber is focus, jade is break time.
    private var focusAccent: Color {
        colorScheme == .dark ? VibePalette.warmAmberAccent : VibePalette.warmAmberAccentDeep
    }

    private var breakAccent: Color {
        colorScheme == .dark ? VibePalette.softJade : VibePalette.softJadeDeep
    }

    private var summaryCardGlassTint: Color {
        Color.white.opacity(colorScheme == .dark ? 0.04 : 0.12)
    }

    private var summaryCardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.22),
                Color.white.opacity(colorScheme == .dark ? 0.015 : 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
