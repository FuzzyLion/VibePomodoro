//
//  VibePomodoroApp.swift
//  VibePomodoro
//
//  Created by Qi Wu on 15.03.26.
//

import SwiftUI

@main
struct VibePomodoroApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = PomodoroStore(defaults: PomodoroStore.runtimeDefaults())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(store.settings.appearanceMode.preferredColorScheme)
                .onChange(of: scenePhase) { _, newValue in
                    store.handleScenePhaseChange(newValue)
                }
        }
    }
}

private extension PomodoroAppearanceMode {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
