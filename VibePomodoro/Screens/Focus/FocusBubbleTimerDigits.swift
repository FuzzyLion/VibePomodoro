import SwiftUI

struct BubbleForegroundContent: View {
    let renderState: BubbleRenderState

    var body: some View {
        BubbleTimerDigitsView(renderState: renderState)
            .frame(maxWidth: 208)
    }
}

private struct BubbleTimerDigitsView: View {
    @Environment(\.colorScheme) private var colorScheme

    let renderState: BubbleRenderState

    var body: some View {
        Group {
            if renderState.shouldTickSeconds {
                TimelineView(.periodic(from: .now, by: renderState.textRefreshInterval)) { context in
                    digits(
                        for: renderState.timeText(at: context.date),
                        stepBoundaryCueProgress: renderState.stepBoundaryCueProgress(at: context.date)
                    )
                }
            } else {
                digits(
                    for: renderState.timeText(at: .now),
                    stepBoundaryCueProgress: renderState.stepBoundaryCueProgress(at: .now)
                )
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func digits(for timeText: String, stepBoundaryCueProgress: Double) -> some View {
        let display = BubbleTimeDisplay(text: timeText)
        let textLabel = BubbleTimerTextLabel(display: display)
            .padding(.horizontal, 2)
            .padding(.vertical, 6)
        let cue = max(0, min(stepBoundaryCueProgress, 1))
        let topHighlightOpacity = colorScheme == .light ? 0.18 - cue * 0.08 : 0.24 - cue * 0.10
        let topBlurOpacity = colorScheme == .light ? 0.06 - cue * 0.024 : 0.08 - cue * 0.03

        if colorScheme == .light {
            textLabel
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.47 - cue * 0.03, green: 0.48 - cue * 0.03, blue: 0.51 - cue * 0.01),
                            Color(red: 0.36 - cue * 0.03, green: 0.37 - cue * 0.03, blue: 0.40 - cue * 0.01),
                            Color(red: 0.24 - cue * 0.01, green: 0.25 - cue * 0.01, blue: 0.28 + cue * 0.01)
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
                                    Color.white.opacity(max(0, topHighlightOpacity)),
                                    Color.white.opacity(max(0, topHighlightOpacity * 0.34)),
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
                        .foregroundStyle(Color.white.opacity(max(0, topBlurOpacity)))
                        .blur(radius: 0.24)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 10)
                        }
                }
                .shadow(color: Color.black.opacity(0.05 + cue * 0.015), radius: 7, y: 4)
        } else {
            textLabel
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98 - cue * 0.03),
                            Color.white.opacity(0.88 - cue * 0.05),
                            renderState.phase.glassTint.opacity(0.26 - cue * 0.09)
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
                                    Color.white.opacity(max(0, topHighlightOpacity)),
                                    Color.white.opacity(max(0, topHighlightOpacity * 0.30)),
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
                        .foregroundStyle(Color.white.opacity(max(0, topBlurOpacity)))
                        .blur(radius: 0.36)
                        .mask(alignment: .top) {
                            Rectangle()
                                .frame(height: 10)
                        }
                }
                .shadow(color: Color.black.opacity(0.08 + cue * 0.02), radius: 10, y: 5)
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
