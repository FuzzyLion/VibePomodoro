import SwiftUI

struct FocusBubbleAnchorSignature: Equatable {
    let size: CGSize
    let topInset: CGFloat
    let bottomInset: CGFloat
}

struct FocusScreenLayout {
    static let bubbleDiameter: CGFloat = 280
    static let horizontalPadding: CGFloat = 24
    static let topActionButtonSize: CGFloat = 44
    static let bottomControlRowWidth: CGFloat = bubbleDiameter
    static let bottomControlSpacing: CGFloat = 12
    static let bottomSecondaryButtonSize: CGFloat = 52
    static let bottomPrimaryButtonHeight: CGFloat = 54
    static let immersiveAnchorResetEpsilon: CGFloat = 1
    static let layoutSettlingEpsilon: CGFloat = 1
    static let immersiveLayoutRestoreFallbackDelay: UInt64 = 450_000_000
    static let immersiveVisualFadeAnimation = Animation.easeOut(duration: 0.18)

    let size: CGSize
    let safeAreaInsets: EdgeInsets

    var isCompact: Bool {
        size.height < 760
    }

    var topChromePadding: CGFloat {
        if safeAreaInsets.top > FocusScreenLayout.topActionButtonSize {
            return max(8, safeAreaInsets.top - FocusScreenLayout.topActionButtonSize)
        }

        return max(8, safeAreaInsets.top)
    }

    var topChromeInnerSpacing: CGFloat {
        20
    }

    var bottomChromeSpacing: CGFloat {
        isCompact ? 12 : 14
    }

    var defaultBubbleCenterY: CGFloat {
        size.height / 2
    }

    var bottomChromeOffset: CGFloat {
        isCompact ? 16 : 20
    }

    var bubbleAnchorSignature: FocusBubbleAnchorSignature {
        FocusBubbleAnchorSignature(
            size: size,
            topInset: safeAreaInsets.top,
            bottomInset: safeAreaInsets.bottom
        )
    }
}
