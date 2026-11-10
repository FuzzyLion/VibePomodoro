import SwiftUI
import UIKit

/// The liquid with the countdown inside it. The digits are drawn once, in their solid treatment,
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
        .mask { BubbleInnerShape(phaseMorph: driver.phaseMorph) }
        .allowsHitTesting(false)
    }

    private func liquid(around timeText: String, stepBoundaryCueProgress: Double) -> some View {
        let size = FocusScreenLayout.bubbleDiameter
        let isDark = colorScheme == .dark
        let vessel = driver.phaseMorph.shape.path(in: CGRect(x: 0, y: 0, width: size, height: size)).boundingRect

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
                    phaseTint: driver.phaseMorph.tint
                )
                // The numerals float in the middle of the vessel, which stands on the bottom of
                // the frame and is not always as tall as it.
                .offset(y: vessel.midY - size / 2)
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
    let phaseTint: Color

    var body: some View {
        ZStack {
            if let summary {
                BubbleNumeralText(stepBoundaryCueProgress: 0, phaseTint: phaseTint) {
                    BubbleSummaryLabel(summary: summary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "Focused \(FocusCompletionFormatting.accessibilityDurationText(summary.focusTime))"
                )
                .transition(transition)
            } else {
                BubbleNumeralText(stepBoundaryCueProgress: stepBoundaryCueProgress, phaseTint: phaseTint) {
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

/// The numerals as an object inside the vessel, as they look above the liquid: a thin solid lit
/// from the top left like the vessel. The face has a bevel, light along its upper-left edges and a
/// faint rim of light along its lower-right ones. A side about 2 pt deep runs down and to the
/// right, and a soft shadow lands on the back of the vessel well away from the numerals, so they
/// float inside the glass rather than lie on it. Over the last seconds of a step the face dims a
/// little.
private struct BubbleNumeralText<Label: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let stepBoundaryCueProgress: Double
    let phaseTint: Color
    @ViewBuilder let label: () -> Label

    /// The copies that build the side, each a step further down and to the right.
    private static var sideLayerCount: Int { 4 }
    private static var sideStep: CGSize { CGSize(width: 0.45, height: 0.55) }

    var body: some View {
        let textLabel = label()
            .padding(.horizontal, 2)
            .padding(.vertical, 6)
        let material = BubbleNumeralMaterial(
            isDark: colorScheme == .dark,
            increasedContrast: colorSchemeContrast == .increased,
            phaseTint: phaseTint,
            cue: max(0, min(stepBoundaryCueProgress, 1))
        )
        let sideLayerCount = Self.sideLayerCount

        ZStack {
            // The shadow and the side are copies of the text; only the face is read aloud.
            Group {
                textLabel
                    .foregroundStyle(material.shadow)
                    .blur(radius: 8)
                    .offset(x: 8, y: 12)

                if let contactShadow = material.contactShadow {
                    textLabel
                        .foregroundStyle(contactShadow)
                        .blur(radius: 1.5)
                        .offset(x: 2, y: 2.5)
                }

                ForEach(0..<sideLayerCount, id: \.self) { index in
                    let depth = CGFloat(sideLayerCount - index)
                    textLabel
                        .foregroundStyle(material.side(nearness: Double(index) / Double(sideLayerCount - 1)))
                        .offset(x: depth * Self.sideStep.width, y: depth * Self.sideStep.height)
                }
            }
            .accessibilityHidden(true)

            textLabel
                .foregroundStyle(
                    material.face
                        .shadow(.inner(color: material.upperEdge, radius: 0.5, x: 0.8, y: 1.0))
                        .shadow(.inner(color: material.lowerEdge, radius: 1.0, x: -0.9, y: -1.1))
                )
        }
    }
}

/// The colors of the numerals' material in one appearance.
private struct BubbleNumeralMaterial {
    let face: LinearGradient
    let upperEdge: Color
    let lowerEdge: Color
    let shadow: Color
    let contactShadow: Color?
    private let nearSide: Color
    private let farSide: Color

    init(isDark: Bool, increasedContrast: Bool, phaseTint: Color, cue: Double) {
        if isDark {
            // White porcelain over a gray side, with a dark shadow behind it.
            face = Self.gradient([
                Color(white: 1.0 - cue * 0.03),
                Color(white: 0.95 - cue * 0.05),
                Color(white: 0.88 - cue * 0.06)
            ])
            upperEdge = .white.opacity(0.95 - cue * 0.3)
            lowerEdge = .black.opacity(0.16)
            nearSide = Color(red: 0.72, green: 0.72, blue: 0.75)
            farSide = Color(red: 0.56, green: 0.56, blue: 0.59)
            shadow = .black.opacity(0.42 + cue * 0.04)
            contactShadow = nil
        } else {
            // Warm graphite rather than neutral gray, which made the numerals look heavy and
            // lifeless. The rim of light along the lower-right edges keeps the dark face from going
            // flat, and the shadow takes the phase color, as light through the tinted vessel would.
            // The face's lightest corner stays at 3:1 against the glass.
            let ink = increasedContrast ? 0.3 : cue * 0.06
            face = Self.gradient([
                Color(red: 0.54, green: 0.51, blue: 0.48).mix(with: .black, by: ink),
                Color(red: 0.44, green: 0.415, blue: 0.39).mix(with: .black, by: ink),
                Color(red: 0.31, green: 0.29, blue: 0.27).mix(with: .black, by: ink)
            ])
            upperEdge = .white.opacity(0.85 - cue * 0.3)
            lowerEdge = .white.opacity(0.32)
            nearSide = Color(red: 0.42, green: 0.39, blue: 0.36)
            farSide = Color(red: 0.35, green: 0.325, blue: 0.30)
            shadow = phaseTint.opacity(0.55)
            contactShadow = .black.opacity(0.05)
        }
    }

    /// The side's color, from its far edge (0) to the edge beside the face (1).
    func side(nearness: Double) -> Color {
        farSide.mix(with: nearSide, by: nearness)
    }

    private static func gradient(_ colors: [Color]) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// The numerals in the vessel: Didot Bold, whose hairlines catch the light and bend visibly in the
/// liquid. Its digits share one width, so the countdown never shifts as it ticks. At the countdown
/// size, "25:00" spans about as wide as the earlier expanded numerals did.
private enum BubbleNumerals {
    static let fontName = "Didot-Bold"
    static let countdownSize: CGFloat = 74

    static func font(size: CGFloat) -> Font {
        .custom(fontName, fixedSize: size)
    }

    /// Text centers its line box, and Didot's tall ascender leaves the numerals a little high in
    /// it. This moves the middle of their cap height to the middle of the line box.
    static func capCenterOffset(size: CGFloat) -> CGFloat {
        guard let font = UIFont(name: fontName, size: size) else { return 0 }
        return (font.capHeight - font.ascender - font.descender) / 2
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
        let numeralSize: CGFloat = digitCount > 3 ? 59 : 66

        VStack(spacing: 2) {
            caption

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    Text(part.value)
                        .font(BubbleNumerals.font(size: numeralSize))

                    Text(part.unit)
                        .font(BubbleNumerals.font(size: numeralSize * 0.5))
                        .padding(.leading, 2)
                        .padding(.trailing, index < parts.count - 1 ? 12 : 0)
                }
            }
            .monospacedDigit()
            .offset(y: BubbleNumerals.capCenterOffset(size: numeralSize))

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
        let size = BubbleNumerals.countdownSize

        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(display.minutes)

            Text(":")
                .padding(.horizontal, size * 0.07)
                .opacity(0.96)

            Text(display.seconds)
        }
        .font(BubbleNumerals.font(size: size))
        .monospacedDigit()
        .fixedSize(horizontal: true, vertical: false)
        .offset(y: BubbleNumerals.capCenterOffset(size: size))
    }
}
