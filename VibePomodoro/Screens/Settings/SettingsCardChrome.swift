import SwiftUI

struct SettingsCardChromeStyle {
    let cornerRadius: CGFloat
    let highlightHorizontalInset: CGFloat
    let borderLineWidth: CGFloat
    let borderDarkOpacity: Double
    /// Light mode draws a one-pixel dark rim instead of the white border, which vanishes on a white card.
    let rimLightOpacity: Double
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
    /// White over the material. Light mode lifts the card to near white, so it reads as a panel above the page.
    let liftDarkOpacity: Double
    let liftLightOpacity: Double

    static func summary(contentInset: CGFloat, cornerRadius: CGFloat) -> Self {
        SettingsCardChromeStyle(
            cornerRadius: cornerRadius,
            highlightHorizontalInset: contentInset,
            borderLineWidth: 0.85,
            borderDarkOpacity: 0.15,
            rimLightOpacity: 0.2,
            highlightDarkOpacity: 0.12,
            highlightLightOpacity: 0.46,
            shadowDarkOpacity: 0.13,
            shadowLightOpacity: 0.08,
            shadowDarkRadius: 16,
            shadowLightRadius: 12,
            shadowDarkYOffset: 8,
            shadowLightYOffset: 6,
            surfaceDarkTopOpacity: 0.035,
            surfaceLightTopOpacity: 0.20,
            surfaceDarkBottomOpacity: 0.01,
            surfaceLightBottomOpacity: 0.08,
            liftDarkOpacity: 0.045,
            liftLightOpacity: 0.92
        )
    }

    static func secondary(contentInset: CGFloat, cornerRadius: CGFloat) -> Self {
        SettingsCardChromeStyle(
            cornerRadius: cornerRadius,
            highlightHorizontalInset: contentInset,
            borderLineWidth: 0.75,
            borderDarkOpacity: 0.13,
            rimLightOpacity: 0.18,
            highlightDarkOpacity: 0.08,
            highlightLightOpacity: 0.40,
            shadowDarkOpacity: 0.10,
            shadowLightOpacity: 0.07,
            shadowDarkRadius: 14,
            shadowLightRadius: 10,
            shadowDarkYOffset: 7,
            shadowLightYOffset: 5,
            surfaceDarkTopOpacity: 0,
            surfaceLightTopOpacity: 0,
            surfaceDarkBottomOpacity: 0,
            surfaceLightBottomOpacity: 0,
            liftDarkOpacity: 0.035,
            liftLightOpacity: 0.92
        )
    }

    func borderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(borderDarkOpacity) : Color.black.opacity(rimLightOpacity)
    }

    func borderWidth(for colorScheme: ColorScheme, displayScale: CGFloat) -> CGFloat {
        colorScheme == .dark ? borderLineWidth : 1 / max(displayScale, 1)
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

    func lift(for colorScheme: ColorScheme) -> Color {
        Color.white.opacity(colorScheme == .dark ? liftDarkOpacity : liftLightOpacity)
    }
}

/// Cards are content, so they use a standard material. Liquid Glass stays with the controls and
/// navigation above them, and the material keeps its brightness whatever the system does to glass.
private struct SettingsCardChromeModifier<AccentOverlay: View>: ViewModifier {
    @Environment(\.displayScale) private var displayScale

    let colorScheme: ColorScheme
    let style: SettingsCardChromeStyle
    let accentOverlay: AccentOverlay

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)

        content
            .environment(
                \.settingsCardShadow,
                SettingsCardShadow(
                    color: style.shadowColor(for: colorScheme),
                    radius: style.shadowRadius(for: colorScheme),
                    y: style.shadowYOffset(for: colorScheme)
                )
            )
            .background {
                shape
                    .fill(.regularMaterial)
                    .overlay { shape.fill(style.lift(for: colorScheme)) }
                    .overlay { shape.fill(style.surfaceGradient(for: colorScheme)) }
                    .overlay {
                        accentOverlay
                            .clipShape(shape)
                    }
                    // The shadow belongs to the surface alone. Around the content it is inherited
                    // by every control in the card, and iOS then draws a menu's closing animation
                    // as a white, shadowed rectangle that stays on the row for over a second.
                    .shadow(
                        color: style.shadowColor(for: colorScheme),
                        radius: style.shadowRadius(for: colorScheme),
                        y: style.shadowYOffset(for: colorScheme)
                    )
            }
            .overlay {
                shape
                    .strokeBorder(
                        style.borderColor(for: colorScheme),
                        lineWidth: style.borderWidth(for: colorScheme, displayScale: displayScale)
                    )
            }
            .overlay(alignment: .top) {
                shape
                    .fill(style.topHighlightGradient(for: colorScheme))
                    .frame(height: 1)
                    .padding(.horizontal, style.highlightHorizontalInset)
            }
    }
}

/// The shadow of the card a view sits in.
struct SettingsCardShadow: Equatable {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

extension EnvironmentValues {
    @Entry var settingsCardShadow: SettingsCardShadow?
}

private struct SettingsCardLiftModifier: ViewModifier {
    @Environment(\.settingsCardShadow) private var shadow

    func body(content: Content) -> some View {
        content.shadow(color: shadow?.color ?? .clear, radius: shadow?.radius ?? 0, y: shadow?.y ?? 0)
    }
}

/// The enclosing card's shadow drawn on its own, in the outline of `shape`. A menu can't cast that
/// shadow itself, because iOS then draws the menu's closing animation with it, so this goes behind
/// the menu instead.
struct SettingsCardLiftShadow<Outline: Shape>: View {
    @Environment(\.settingsCardShadow) private var shadow

    let shape: Outline

    var body: some View {
        if let shadow {
            shape
                .fill(shadow.color)
                .blur(radius: shadow.radius)
                .offset(y: shadow.y)
                // Keep it out from under the control, where it would show through the glass.
                .mask {
                    Rectangle()
                        .padding(-(shadow.radius * 3 + abs(shadow.y)))
                        .overlay { shape.blendMode(.destinationOut) }
                        .compositingGroup()
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

extension View {
    /// Casts the enclosing card's shadow from this view, so a raised control keeps its lift now
    /// that the card's shadow no longer reaches its content.
    func settingsCardLift() -> some View {
        modifier(SettingsCardLiftModifier())
    }

    func settingsCardChrome<AccentOverlay: View>(
        colorScheme: ColorScheme,
        style: SettingsCardChromeStyle,
        @ViewBuilder accentOverlay: () -> AccentOverlay
    ) -> some View {
        modifier(
            SettingsCardChromeModifier(
                colorScheme: colorScheme,
                style: style,
                accentOverlay: accentOverlay()
            )
        )
    }
}

struct SettingsCard<Content: View, AccentOverlay: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let style: SettingsCardChromeStyle
    let topInset: CGFloat
    let bottomInset: CGFloat
    let accentOverlay: AccentOverlay
    let content: Content

    init(
        style: SettingsCardChromeStyle,
        topInset: CGFloat = SettingsLayout.cardVerticalInset,
        bottomInset: CGFloat = SettingsLayout.cardVerticalInset,
        @ViewBuilder accentOverlay: () -> AccentOverlay,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.topInset = topInset
        self.bottomInset = bottomInset
        self.accentOverlay = accentOverlay()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, SettingsLayout.cardContentInset)
        .padding(.top, topInset)
        .padding(.bottom, bottomInset)
        .settingsCardChrome(
            colorScheme: colorScheme,
            style: style
        ) {
            accentOverlay
        }
    }
}

struct SettingsCardHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var titleSize: CGFloat = 12

    let title: String
    var trailingText: String? = nil

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    titleLabel
                    if let trailingText {
                        trailingLabel(trailingText)
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    titleLabel
                    Spacer(minLength: 12)
                    if let trailingText {
                        trailingLabel(trailingText)
                    }
                }
            }
        }
        .padding(.bottom, SettingsLayout.cardHeaderBottomSpacing)
    }

    private var titleLabel: some View {
        Text(title)
            .font(.system(size: titleSize, weight: .semibold))
            .tracking(SettingsLayout.sectionTitleTracking)
            .foregroundStyle(SettingsTheme.sectionLabelColor(for: colorScheme))
            .accessibilityAddTraits(.isHeader)
    }

    private func trailingLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.footnote, weight: .semibold))
            .foregroundStyle(SettingsTheme.sectionAccentColor(for: colorScheme))
    }
}

struct SettingsSectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var titleSize: CGFloat = 12

    let title: String
    var trailingText: String? = nil

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    titleLabel
                    if let trailingText {
                        trailingLabel(trailingText)
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    titleLabel
                    Spacer(minLength: 12)
                    if let trailingText {
                        trailingLabel(trailingText)
                    }
                }
            }
        }
        .padding(.horizontal, SettingsLayout.cardContentInset)
    }

    private var titleLabel: some View {
        Text(title)
            .font(.system(size: titleSize, weight: .semibold))
            .tracking(SettingsLayout.sectionTitleTracking)
            .foregroundStyle(SettingsTheme.sectionLabelColor(for: colorScheme))
            .accessibilityAddTraits(.isHeader)
    }

    private func trailingLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.footnote, weight: .semibold))
            .foregroundStyle(SettingsTheme.sectionAccentColor(for: colorScheme))
    }
}

struct SettingsDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(SettingsTheme.dividerColor(for: colorScheme))
            .frame(height: 1)
    }
}
