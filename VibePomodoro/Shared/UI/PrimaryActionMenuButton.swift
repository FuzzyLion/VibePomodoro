import SwiftUI
import UIKit

struct PrimaryActionMenuButton<Selection: Hashable, Label: View>: View {
    let options: [Selection]
    let selected: Selection
    let title: (Selection) -> String
    let onSelect: (Selection) -> Void
    let accessibilityLabel: String
    let accessibilityValue: String?
    @ViewBuilder let label: () -> Label

    var body: some View {
        label()
            .accessibilityHidden(true)
            .contentShape(Rectangle())
            .overlay {
                PrimaryActionMenuOverlay(
                    items: options.map { option in
                        PrimaryActionMenuItem(
                            id: AnyHashable(option),
                            title: title(option),
                            state: option == selected ? .on : .off
                        ) {
                            guard option != selected else { return }
                            onSelect(option)
                        }
                    },
                    accessibilityLabel: accessibilityLabel,
                    accessibilityValue: accessibilityValue
                )
            }
    }
}

private struct PrimaryActionMenuItem: Identifiable {
    let id: AnyHashable
    let title: String
    let state: UIMenuElement.State
    let action: () -> Void
}

private struct PrimaryActionMenuOverlay: UIViewRepresentable {
    let items: [PrimaryActionMenuItem]
    let accessibilityLabel: String
    let accessibilityValue: String?

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.tintColor = .clear
        button.setTitle(nil, for: .normal)
        button.setImage(nil, for: .normal)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = false
        button.accessibilityTraits.insert(.button)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        uiView.isEnabled = !items.isEmpty
        uiView.accessibilityLabel = accessibilityLabel
        uiView.accessibilityValue = accessibilityValue
        uiView.menu = UIMenu(
            children: items.map { item in
                UIAction(title: item.title, state: item.state) { _ in
                    item.action()
                }
            }
        )
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIButton,
        context: Context
    ) -> CGSize? {
        let size = proposal.replacingUnspecifiedDimensions()
        return CGSize(width: size.width, height: size.height)
    }
}
