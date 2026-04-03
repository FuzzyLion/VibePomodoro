import SwiftUI
import UIKit

struct VibeBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    VibePalette.amberGold.opacity(colorScheme == .dark ? 0.12 : 0.09),
                    Color.clear
                ],
                center: .top,
                startRadius: 16,
                endRadius: colorScheme == .dark ? 260 : 320
            )
            .offset(y: -120)

            RadialGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.72),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 360
            )

            RadialGradient(
                colors: [
                    VibePalette.softJade.opacity(colorScheme == .dark ? 0.06 : 0.035),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 280
            )
            .offset(x: 80, y: 80)
        }
        .ignoresSafeArea()
    }

    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                VibePalette.darkBackground,
                VibePalette.darkSurface,
                Color(red: 0.10, green: 0.11, blue: 0.14)
            ]
        }

        return [
            VibePalette.warmBackground,
            Color(red: 0.97, green: 0.97, blue: 0.98),
            VibePalette.mistBackground
        ]
    }
}

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(22)
            .liquidGlassSurface(
                .regular.tint(Color.white.opacity(0.08)),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous),
                stroke: Color.white.opacity(0.38)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 28, y: 12)
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 188, height: 64)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.86), Color.white.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 16)
        }
        .shadow(color: Color.black.opacity(0.10), radius: 22, y: 10)
    }

    private func iconName(for tab: AppTab) -> String {
        switch tab {
        case .focus:
            return "timer"
        case .productivity:
            return "chart.bar"
        case .settings:
            return "gearshape"
        }
    }

    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selection == tab

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 0) {
                Image(systemName: iconName(for: tab))
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(isSelected ? VibePalette.focusTint : Color.primary.opacity(0.38))
                    .frame(width: 52, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isSelected ? selectedTabBackground : AnyShapeStyle(Color.clear))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(isSelected ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                            }
                    )

                Circle()
                    .fill(isSelected ? VibePalette.focusTint : Color.clear)
                    .frame(width: 4, height: 4)
                    .offset(y: 4)
            }
            .frame(width: 56, height: 48)
        }
        .buttonStyle(.plain)
    }

    private var selectedTabBackground: AnyShapeStyle {
        AnyShapeStyle(
            RadialGradient(
                colors: [
                    VibePalette.focusTint.opacity(0.24),
                    VibePalette.focusTint.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 4,
                endRadius: 36
            )
        )
    }
}

struct SystemTabBarVisibilityBridge: UIViewControllerRepresentable {
    var isHidden: Bool
    var animationDuration: TimeInterval = 0.18

    func makeUIViewController(context: Context) -> TabBarVisibilityController {
        TabBarVisibilityController()
    }

    func updateUIViewController(_ controller: TabBarVisibilityController, context: Context) {
        controller.applyTabBarVisibility(
            isHidden: isHidden,
            animationDuration: animationDuration
        )
    }
}

final class TabBarVisibilityController: UIViewController {
    private weak var observedTabBar: UITabBar?
    private var lastAppliedHiddenState: Bool?

    func applyTabBarVisibility(isHidden: Bool, animationDuration: TimeInterval) {
        let applyChanges = {
            guard let tabBar = self.resolveTabBarIfNeeded() else { return }
            let targetAlpha: CGFloat = isHidden ? 0 : 1
            let shouldAnimate = self.lastAppliedHiddenState != nil
                && self.lastAppliedHiddenState != isHidden
                && animationDuration > 0

            tabBar.isHidden = false
            tabBar.isUserInteractionEnabled = !isHidden
            tabBar.accessibilityElementsHidden = isHidden
            tabBar.transform = .identity

            if shouldAnimate {
                if !isHidden {
                    tabBar.alpha = 0
                }

                tabBar.layer.removeAllAnimations()
                UIView.animate(
                    withDuration: animationDuration,
                    delay: 0,
                    options: [.beginFromCurrentState, .curveEaseOut, .allowUserInteraction]
                ) {
                    tabBar.alpha = targetAlpha
                }
            } else {
                tabBar.alpha = targetAlpha
            }

            self.lastAppliedHiddenState = isHidden
        }

        if Thread.isMainThread {
            applyChanges()
        } else {
            DispatchQueue.main.async(execute: applyChanges)
        }
    }

    @discardableResult
    private func resolveTabBarIfNeeded() -> UITabBar? {
        if let observedTabBar, observedTabBar.window != nil {
            return observedTabBar
        }

        observedTabBar = findTabBarController(in: rootViewController())?.tabBar
        return observedTabBar
    }

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

    private func findTabBarController(in root: UIViewController?) -> UITabBarController? {
        guard let root else { return nil }

        if let tabBarController = root as? UITabBarController {
            return tabBarController
        }

        for child in root.children {
            if let tabBarController = findTabBarController(in: child) {
                return tabBarController
            }
        }

        if let presentedViewController = root.presentedViewController,
           let tabBarController = findTabBarController(in: presentedViewController) {
            return tabBarController
        }

        if let navigationController = root as? UINavigationController {
            for controller in navigationController.viewControllers {
                if let tabBarController = findTabBarController(in: controller) {
                    return tabBarController
                }
            }
        }

        if let splitViewController = root as? UISplitViewController {
            for controller in splitViewController.viewControllers {
                if let tabBarController = findTabBarController(in: controller) {
                    return tabBarController
                }
            }
        }

        return nil
    }
}

private extension View {
    func liquidGlassSurface<S: Shape>(
        _ glass: Glass = .regular,
        in shape: S,
        stroke: Color = Color.white.opacity(0.36)
    ) -> some View {
        background {
            Color.clear
                .glassEffect(glass, in: shape)
        }
        .overlay {
            shape
                .stroke(stroke, lineWidth: 1)
        }
    }
}
