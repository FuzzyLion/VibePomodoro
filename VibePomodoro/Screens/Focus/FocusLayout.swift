import SwiftUI

struct FocusBubbleAnchorSignature: Equatable {
    let size: CGSize
    let topInset: CGFloat
    let bottomInset: CGFloat
}

struct FocusScreenLayout {
    static let bubbleDiameter: CGFloat = 280
    static let horizontalPadding: CGFloat = 24
    static let topChromeHorizontalPadding: CGFloat = 18
    static let topActionButtonHitSize: CGFloat = 40
    static let topActionButtonVisualSize: CGFloat = 36
    static let progressDotsHeight: CGFloat = 12
    static let bottomControlRowWidth: CGFloat = 324
    static let bottomControlSpacing: CGFloat = 14
    static let bottomGlassMergeSpacing: CGFloat = 0
    static let bottomSecondaryButtonHitSize: CGFloat = 58
    static let bottomSecondaryButtonSize: CGFloat = 50
    static let bottomPrimaryButtonHeight: CGFloat = 52
    static let bottomPrimaryButtonMinWidth: CGFloat = 176
    static let immersiveAnchorResetEpsilon: CGFloat = 1
    static let layoutSettlingEpsilon: CGFloat = 1
    static let immersiveLayoutRestoreFallbackDelay: UInt64 = 450_000_000
    static let immersiveVisualFadeAnimation = Animation.easeOut(duration: 0.18)
    static let phaseMorphAnimation = Animation.easeInOut(duration: 0.34)
    static let phaseChromeBreathInAnimation = Animation.easeOut(duration: 0.18)
    static let phaseChromeBreathOutAnimation = Animation.easeInOut(duration: 0.24)
    static let phaseChromeBreathHoldDuration: UInt64 = 90_000_000

    let size: CGSize
    let safeAreaInsets: EdgeInsets

    var isCompact: Bool {
        size.height < 760
    }

    var topChromePadding: CGFloat {
        max(6, safeAreaInsets.top - 50)
    }

    var topChromeInnerSpacing: CGFloat {
        16
    }

    var bottomChromeSpacing: CGFloat {
        isCompact ? 18 : 22
    }

    var progressDotsOffset: CGFloat {
        isCompact ? 16 : 20
    }

    var defaultBubbleCenterY: CGFloat {
        size.height / 2
    }

    var bottomChromeOffset: CGFloat {
        isCompact ? 40 : 56
    }

    var bubbleAnchorSignature: FocusBubbleAnchorSignature {
        FocusBubbleAnchorSignature(
            size: size,
            topInset: safeAreaInsets.top,
            bottomInset: safeAreaInsets.bottom
        )
    }
}
