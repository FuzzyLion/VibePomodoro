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
    static let secondaryActionRowWidth: CGFloat = 261.29
    static let secondaryActionSpacing: CGFloat = 16
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
            return safeAreaInsets.top - FocusScreenLayout.topActionButtonSize + (isCompact ? 2 : 4)
        }

        return safeAreaInsets.top + (isCompact ? 2 : 4)
    }

    var topChromeInnerSpacing: CGFloat {
        20
    }

    var bottomChromeSpacing: CGFloat {
        isCompact ? 16 : 18
    }

    var defaultBubbleCenterY: CGFloat {
        size.height / 2
    }

    var bottomChromeOffset: CGFloat {
        isCompact ? 16 : 22
    }

    var bubbleAnchorSignature: FocusBubbleAnchorSignature {
        FocusBubbleAnchorSignature(
            size: size,
            topInset: safeAreaInsets.top,
            bottomInset: safeAreaInsets.bottom
        )
    }
}
