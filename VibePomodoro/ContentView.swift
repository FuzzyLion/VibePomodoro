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

            Group {
                switch store.selectedTab {
                case .focus:
                    FocusScreen()
                case .productivity:
                    ProductivityScreen()
                case .settings:
                    SettingsScreen()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selection: $store.selectedTab)
                .padding(.bottom, 6)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.88), value: store.selectedTab)
    }
}
