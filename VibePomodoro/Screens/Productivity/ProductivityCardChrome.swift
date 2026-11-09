import SwiftUI

struct ProductivityCardChromeStyle {
    let cornerRadius: CGFloat
    let highlightHorizontalInset: CGFloat
    let borderLineWidth: CGFloat
    let borderDarkOpacity: Double
    let borderLightOpacity: Double
    let highlightDarkOpacity: Double
    let highlightLightOpacity: Double
    let shadowDarkOpacity: Double
    let shadowLightOpacity: Double
    let shadowDarkRadius: CGFloat
    let shadowLightRadius: CGFloat
    let shadowDarkYOffset: CGFloat
    let shadowLightYOffset: CGFloat
    let surfaceDarkTopOpacity: Double
    let surfaceLightTopOpacity: Double
    let surfaceDarkBottomOpacity: Double
    let surfaceLightBottomOpacity: Double
    let glassTintDarkOpacity: Double
    let glassTintLightOpacity: Double

    static func summary(contentInset: CGFloat, cornerRadius: CGFloat) -> Self {
        ProductivityCardChromeStyle(
            cornerRadius: cornerRadius,
            highlightHorizontalInset: contentInset,
            borderLineWidth: 0.85,
            borderDarkOpacity: 0.15,
            borderLightOpacity: 0.66,
            highlightDarkOpacity: 0.12,
            highlightLightOpacity: 0.46,
            shadowDarkOpacity: 0.13,
            shadowLightOpacity: 0.05,
            shadowDarkRadius: 16,
            shadowLightRadius: 10,
            shadowDarkYOffset: 8,
            shadowLightYOffset: 5,
            surfaceDarkTopOpacity: 0.035,
            surfaceLightTopOpacity: 0.20,
            surfaceDarkBottomOpacity: 0.01,
            surfaceLightBottomOpacity: 0.08,
            glassTintDarkOpacity: 0.045,
            glassTintLightOpacity: 0.12
        )
    }

    static func trend(contentInset: CGFloat, cornerRadius: CGFloat) -> Self {
        ProductivityCardChromeStyle(
            cornerRadius: cornerRadius,
            highlightHorizontalInset: contentInset,
            borderLineWidth: 0.75,
            borderDarkOpacity: 0.13,
            borderLightOpacity: 0.60,
            highlightDarkOpacity: 0.08,
            highlightLightOpacity: 0.40,
            shadowDarkOpacity: 0.10,
            shadowLightOpacity: 0.04,
            shadowDarkRadius: 14,
            shadowLightRadius: 8,
            shadowDarkYOffset: 7,
            shadowLightYOffset: 4,
            surfaceDarkTopOpacity: 0,
            surfaceLightTopOpacity: 0,
            surfaceDarkBottomOpacity: 0,
            surfaceLightBottomOpacity: 0,
            glassTintDarkOpacity: 0.035,
            glassTintLightOpacity: 0.08
        )
    }

    func borderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(borderDarkOpacity) : Color.white.opacity(borderLightOpacity)
    }

    func topHighlightGradient(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? highlightDarkOpacity : highlightLightOpacity),
                Color.white.opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func shadowColor(for colorScheme: ColorScheme) -> Color {
        Color.black.opacity(colorScheme == .dark ? shadowDarkOpacity : shadowLightOpacity)
    }

    func shadowRadius(for colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? shadowDarkRadius : shadowLightRadius
    }

    func shadowYOffset(for colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? shadowDarkYOffset : shadowLightYOffset
    }

    func surfaceGradient(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? surfaceDarkTopOpacity : surfaceLightTopOpacity),
                Color.white.opacity(colorScheme == .dark ? surfaceDarkBottomOpacity : surfaceLightBottomOpacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func glassTint(for colorScheme: ColorScheme) -> Color {
        Color.white.opacity(colorScheme == .dark ? glassTintDarkOpacity : glassTintLightOpacity)
    }
}

private struct ProductivityGlassCardModifier<AccentOverlay: View>: ViewModifier {
    let colorScheme: ColorScheme
    let style: ProductivityCardChromeStyle
    let accentOverlay: AccentOverlay

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)

        content
            .background {
                shape
                    .fill(style.surfaceGradient(for: colorScheme))
                    .overlay {
                        accentOverlay
                            .clipShape(shape)
                    }
            }
            .glassEffect(.regular.tint(style.glassTint(for: colorScheme)), in: shape)
            .overlay {
                shape
                    .strokeBorder(style.borderColor(for: colorScheme), lineWidth: style.borderLineWidth)
            }
            .overlay(alignment: .top) {
                shape
                    .fill(style.topHighlightGradient(for: colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, style.highlightHorizontalInset)
            }
            .shadow(
                color: style.shadowColor(for: colorScheme),
                radius: style.shadowRadius(for: colorScheme),
                y: style.shadowYOffset(for: colorScheme)
            )
    }
}

extension View {
    func productivityGlassCard<AccentOverlay: View>(
        colorScheme: ColorScheme,
        style: ProductivityCardChromeStyle,
        @ViewBuilder accentOverlay: () -> AccentOverlay
    ) -> some View {
        modifier(
            ProductivityGlassCardModifier(
                colorScheme: colorScheme,
                style: style,
                accentOverlay: accentOverlay()
            )
        )
    }
}

/// Text colors shared by the Productivity cards.
enum ProductivityTextColors {
    static func primary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.TrendCard.primaryTextDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.primaryTextLightOpacity)
    }

    static func secondary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? VibePalette.warmBackground.opacity(ProductivityLayout.TrendCard.secondaryTextDarkOpacity)
            : Color.black.opacity(ProductivityLayout.TrendCard.secondaryTextLightOpacity)
    }
}

/// Phase colors as Productivity marks them: amber for focus, jade for breaks.
enum ProductivityPhaseColors {
    static func focus(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? VibePalette.amberGold : VibePalette.amberGoldDeep
    }

    static func breaks(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? VibePalette.softJade : VibePalette.softJadeDeep
    }
}
