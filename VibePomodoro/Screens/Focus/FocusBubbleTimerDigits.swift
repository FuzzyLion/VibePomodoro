import SwiftUI

struct BubbleForegroundContent: View {
    let renderState: BubbleRenderState
    let driver: BubbleLiquidDriver

    var body: some View {
        BubbleTimerDigitsView(renderState: renderState, driver: driver)
            .frame(width: FocusScreenLayout.bubbleDiameter, height: FocusScreenLayout.bubbleDiameter)
    }
}

private struct BubbleTimerDigitsView: View {
    @Environment(\.colorScheme) private var colorScheme

    let renderState: BubbleRenderState
    let driver: BubbleLiquidDriver

    var body: some View {
        Group {
            if renderState.shouldTickSeconds {
                TimelineView(.periodic(from: .now, by: renderState.textRefreshInterval)) { context in
                    digitsInLiquid(at: context.date)
                }
            } else {
                digitsInLiquid(at: .now)
            }
        }
        .allowsHitTesting(false)
    }

    /// Above the liquid the digits keep their glass treatment; below the surface they take on
    /// the liquid's color. The text refreshes once a second; only the masks follow the waves.
    @ViewBuilder
    private func digitsInLiquid(at date: Date) -> some View {
        let timeText = renderState.timeText(at: date)
        let cue = renderState.stepBoundaryCueProgress(at: date)
        let size = FocusScreenLayout.bubbleDiameter

        switch Self.level(of: driver.frame(at: date)) {
        case .dry:
            digits(for: timeText, stepBoundaryCueProgress: cue)
        case .submerged:
            submergedDigits(for: timeText)
        case .crossing:
            ZStack {
                digits(for: timeText, stepBoundaryCueProgress: cue)
                    .frame(width: size, height: size)
                    .mask {
                        BubbleLiquidTimeline(driver: driver) { frame in
                            BubbleLiquidRegionShape(frame: frame, below: false, overlap: 1.5)
                        }
                    }

                submergedDigits(for: timeText)
                    .frame(width: size, height: size)
                    .mask {
                        BubbleLiquidTimeline(driver: driver) { frame in
                            BubbleLiquidRegionShape(frame: frame, below: true)
                        }
                    }
            }
        }
    }

    private enum Level {
        case dry
        case crossing
        case submerged
    }

    /// Where the water line sits relative to the digits, leaving room for waves and the surface.
    private static func level(of frame: BubbleLiquidFrame) -> Level {
        let size = FocusScreenLayout.bubbleDiameter
        let waterline = BubbleWave.waterlineY(fillRatio: frame.fillRatio, in: CGRect(x: 0, y: 0, width: size, height: size))
        let reach = CGFloat(frame.amplitude) + 16
        let digitsHalfHeight: CGFloat = 40

        if waterline - reach > size / 2 + digitsHalfHeight {
            return .dry
        }
        if waterline + reach < size / 2 - digitsHalfHeight {
            return .submerged
        }
        return .crossing
    }

    private func submergedDigits(for timeText: String) -> some View {
        BubbleTimerTextLabel(display: BubbleTimeDisplay(text: timeText))
            .padding(.horizontal, 2)
            .padding(.vertical, 6)
            .foregroundStyle(submergedFill)
            // Seen through the liquid, the digits shift a little, as if refracted.
            .blur(radius: 0.3)
            .offset(x: 1.2, y: 0.6)
    }

    private var submergedFill: LinearGradient {
        let phaseMorph = driver.phaseMorph
        let submergedInk = Color(red: 0.26, green: 0.22, blue: 0.17)
        return LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.90), phaseMorph.tint.opacity(0.95)]
                // The top stays dark enough to hold about 3.5:1 against the deepest light liquid.
                : [phaseMorph.shadow.mix(with: submergedInk, by: 0.45), submergedInk],
            startPoint: .top,
            endPoint: .bottom
        )
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
                            driver.phaseMorph.glassTint.opacity(0.26 - cue * 0.09)
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
