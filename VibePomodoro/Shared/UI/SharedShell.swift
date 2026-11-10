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
