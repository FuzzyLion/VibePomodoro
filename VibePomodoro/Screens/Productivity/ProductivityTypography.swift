import SwiftUI

/// The Productivity page's type scale. Each role keeps its size at the default text size and grows
/// with Dynamic Type along the system text style closest to it.
enum ProductivityTextRole {
    /// Chart axis labels.
    case axisLabel
    /// Daily Focus Avg and Streak.
    case metricLabel
    /// Uppercase card headings such as SESSION TIME.
    case sectionLabel
    /// The summary's finished-session line.
    case footnote
    /// The range line, the empty-state note, and a selected bar's date.
    case caption
    case cardIcon
    case cardTitle
    /// A trend card's total or selected value.
    case cardFigure
    /// Daily Focus Avg and Streak values.
    case secondaryFigure
    /// Session Time.
    case primaryFigure

    var size: CGFloat {
        switch self {
        case .axisLabel, .metricLabel: 11
        case .sectionLabel, .footnote: 12
        case .caption: 13
        case .cardIcon: 15
        case .cardTitle: 19
        case .secondaryFigure: 24
        case .cardFigure: 28
        case .primaryFigure: 44
        }
    }

    var weight: Font.Weight {
        switch self {
        case .axisLabel, .footnote, .caption: .medium
        case .metricLabel, .sectionLabel, .cardIcon, .cardTitle, .secondaryFigure, .cardFigure, .primaryFigure: .semibold
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .axisLabel, .metricLabel: .caption2
        case .sectionLabel, .footnote: .caption
        case .caption: .footnote
        case .cardIcon, .cardTitle: .title3
        case .secondaryFigure: .title2
        case .cardFigure: .title
        case .primaryFigure: .largeTitle
        }
    }
}

private struct ProductivityScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight

    init(_ role: ProductivityTextRole) {
        _size = ScaledMetric(wrappedValue: role.size, relativeTo: role.textStyle)
        weight = role.weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}

extension View {
    func productivityFont(_ role: ProductivityTextRole) -> some View {
        modifier(ProductivityScaledFont(role))
    }
}
