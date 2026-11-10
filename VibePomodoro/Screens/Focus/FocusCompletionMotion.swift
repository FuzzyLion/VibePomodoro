import SwiftUI

/// The timing of a session's end on the Focus page. The liquid settles and the countdown turns
/// into the focus total while the controls make way for Done; Done drains the vessel into the
/// next session. Everything changes in place, so nothing has to disappear and come back.
enum FocusCompletionMotion {
    /// The liquid settling from overfull to its resting level.
    static let settleDuration: TimeInterval = 0.9
    static let settle = Animation.timingCurve(0.22, 1, 0.36, 1, duration: settleDuration)

    /// Done emptying the vessel to the next session's starting level, shape, and color.
    static let drainDuration: TimeInterval = 0.95
    static let drain = Animation.timingCurve(0.42, 0, 0.2, 1, duration: drainDuration)

    /// The status, the round markers, and the controls changing over.
    static let chrome = Animation.easeInOut(duration: 0.3)

    /// The countdown blurring into the focus total once the liquid starts to settle, and back.
    static let readoutIn = Animation.easeInOut(duration: 0.5).delay(0.18)
    static let readoutOut = Animation.easeInOut(duration: 0.45)

    /// The breakdown under the round markers arrives last and leaves first.
    static let captionIn = Animation.easeOut(duration: 0.4).delay(0.42)
    static let captionOut = Animation.easeOut(duration: 0.18)

    /// With Reduce Motion, whatever changes fades.
    static let reducedMotionFade = Animation.easeInOut(duration: 0.2)
}
