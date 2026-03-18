//
//  ContentView.swift
//  VibePomodoro
//
//  Created by Qi Wu on 15.03.26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PomodoroStore

    var body: some View {
        ZStack {
            VibeBackground()
            TabView(selection: $store.selectedTab) {
                FocusScreen()
                    .tag(AppTab.focus)
                    .tabItem {
                        Label("Focus", systemImage: "timer")
                    }

                ProductivityScreen()
                    .tag(AppTab.productivity)
                    .tabItem {
                        Label("Productivity", systemImage: "chart.bar")
                    }

                SettingsScreen()
                    .tag(AppTab.settings)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .tint(VibePalette.warmAmberAccent)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.88), value: store.selectedTab)
    }
}
