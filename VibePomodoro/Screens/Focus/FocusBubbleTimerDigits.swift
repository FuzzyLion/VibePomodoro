import SwiftUI

/// The liquid with the countdown inside it. The digits are drawn once, in their glass treatment,
/// and the liquid shader runs over their layer: above the wave line they stay as drawn, below it
/// they are seen through the liquid, refracted and tinted. The text changes once a second; the
/// liquid follows its own 12 Hz schedule. Once a session has ended, the vessel holds the focus
/// total instead of the countdown.
struct BubbleLiquidContent: View {
    @Environment(\.colorScheme) private var colorScheme

    let renderState: BubbleRenderState
    let driver: BubbleLiquidDriver

    var body: some View {
        // One timeline whether or not the clock ticks, so the readout keeps its identity and the
        // countdown can turn into the summary with a transition.
        TimelineView(.periodic(from: .now, by: renderState.textRefreshInterval)) { context in
            liquid(
                around: renderState.timeText(at: context.date),
                stepBoundaryCueProgress: renderState.stepBoundaryCueProgress(at: context.date)
            )
        }
        .frame(width: FocusScreenLayout.bubbleDiameter, height: FocusScreenLayout.bubbleDiameter)
        // The liquid stays inside the glass wall instead of reaching the outer edge.
        .mask { driver.phaseMorph.shape.scale(BubbleVessel.innerScale) }
        .allowsHitTesting(false)
    }

    private func liquid(around timeText: String, stepBoundaryCueProgress: Double) -> some View {
        let size = FocusScreenLayout.bubbleDiameter
        let isDark = colorScheme == .dark

        return BubbleLiquidTimeline(driver: driver) { frame in
            ZStack {
                // A layer effect only shades what its content draws. This all but invisible fill
                // makes that the whole vessel rather than the area around the digits.
                Rectangle()
                    .fill(Color.black.opacity(0.004))

                BubbleVesselReadout(
                    timeText: timeText,
                    summary: renderState.summary,
                    stepBoundaryCueProgress: stepBoundaryCueProgress,
                    glassTint: driver.phaseMorph.glassTint
                )
            }
            .frame(width: size, height: size)
            // One flattened layer: without it the effect runs on each child view separately.
            .compositingGroup()
            .layerEffect(
                BubbleLiquidShader.shader(
                    phaseMorph: driver.phaseMorph,
                    frame: frame,
                    renderingPolicy: driver.renderingPolicy,
                    isDark: isDark
                ),
                maxSampleOffset: BubbleLiquidShader.maxSampleOffset
            )
        }
    }
}

/// What the vessel reads: the countdown while a session runs, and the time spent focusing once it
/// has ended. One blurs into the other in place.
private struct BubbleVesselReadout: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let timeText: String
    let summary: BubbleSessionSummary?
    let stepBoundaryCueProgress: Double
    let glassTint: Color

    var body: some View {
        ZStack {
            if let summary {
                BubbleGlassText(stepBoundaryCueProgress: 0, glassTint: glassTint) {
                    BubbleSummaryLabel(summary: summary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "Focused \(FocusCompletionFormatting.accessibilityDurationText(summary.focusTime))"
                )
                .transition(transition)
            } else {
                BubbleGlassText(stepBoundaryCueProgress: stepBoundaryCueProgress, glassTint: glassTint) {
                    BubbleTimerTextLabel(display: BubbleTimeDisplay(text: timeText))
                }
                .transition(transition)
            }
        }
        .animation(animation, value: summary != nil)
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : AnyTransition(.blurReplace)
    }

    private var animation: Animation {
        if reduceMotion {
            return FocusCompletionMotion.reducedMotionFade
        }
        return summary != nil ? FocusCompletionMotion.readoutIn : FocusCompletionMotion.readoutOut
    }
}

/// Text in the vessel's glass treatment, as it looks above the liquid.
private struct BubbleGlassText<Label: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let stepBoundaryCueProgress: Double
    let glassTint: Color
    @ViewBuilder let label: () -> Label

    var body: some View {
        let textLabel = label()
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
                            // Kept a little darker so the digits hold contrast over the tinted liquid.
                            Color(red: 0.42 - cue * 0.03, green: 0.43 - cue * 0.03, blue: 0.46 - cue * 0.01),
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
                            glassTint.opacity(0.26 - cue * 0.09)
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

/// The focus total in the countdown's numerals, with smaller units, under a small label. The
/// number sits where the countdown was.
private struct BubbleSummaryLabel: View {
    let summary: BubbleSessionSummary

    var body: some View {
        let parts = FocusCompletionFormatting.durationParts(summary.focusTime)
        let digitCount = parts.reduce(0) { $0 + $1.value.count }
        // The units make the total wider than a countdown, so its numerals are a little smaller,
        // and smaller again for four digits, as in "10h 25m".
        let numeralSize: CGFloat = digitCount > 3 ? 46 : 52

        VStack(spacing: 2) {
            caption

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    Text(part.value)
                        .font(.system(size: numeralSize, weight: .heavy, design: .default))
                        .fontWidth(.expanded)

                    Text(part.unit)
                        .font(.system(size: numeralSize * 0.5, weight: .heavy, design: .default))
                        .fontWidth(.expanded)
                        .padding(.leading, 2)
                        .padding(.trailing, index < parts.count - 1 ? 12 : 0)
                }
            }
            .monospacedDigit()
            .tracking(-1.1)

            // Balances the label, so the number stays centered where the countdown was.
            caption.hidden()
        }
        .fixedSize()
    }

    private var caption: some View {
        Text("FOCUSED")
            .font(.system(size: 12, weight: .heavy, design: .default))
            .fontWidth(.expanded)
            .tracking(2.4)
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
