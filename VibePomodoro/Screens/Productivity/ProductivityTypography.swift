import SwiftUI

/// The Productivity page's type scale. Each role keeps its size at the default text size and grows
/// with Dynamic Type along the system text style closest to it.
enum ProductivityTextRole {
    /// Chart axis labels.
    case axisLabel
    /// Daily Focus Avg and Streak.
    case metricLabel
    /// Uppercase card headings such as FOCUS TIME.
    case sectionLabel
    /// The summary's finished-session line.
    case footnote
    /// The range line, the empty-state note, a selected slot's date, and a session's start.
    case caption
    /// A session row's focus time.
    case rowValue
    case cardTitle
    /// Breaks and Blocks in the rhythm card.
    case statFigure
    /// Focus in the rhythm card.
    case cardFigure
    /// Daily Focus Avg and Streak values.
    case secondaryFigure
    /// Focus Time, the summary's lead.
    case primaryFigure

    var size: CGFloat {
        switch self {
        case .axisLabel, .metricLabel: 11
        case .sectionLabel, .footnote: 12
        case .caption, .rowValue: 13
        case .cardTitle: 19
        case .statFigure: 20
        case .secondaryFigure: 24
        case .cardFigure: 28
        case .primaryFigure: 44
        }
    }

    var weight: Font.Weight {
        switch self {
        case .axisLabel, .footnote, .caption: .medium
        case .metricLabel, .sectionLabel, .rowValue, .cardTitle, .statFigure, .secondaryFigure, .cardFigure, .primaryFigure: .semibold
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .axisLabel, .metricLabel: .caption2
        case .sectionLabel, .footnote: .caption
        case .caption, .rowValue: .footnote
        case .cardTitle, .statFigure: .title3
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
