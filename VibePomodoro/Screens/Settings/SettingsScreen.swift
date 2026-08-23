import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: PomodoroStore

    var body: some View {
        NavigationStack {
            ZStack {
                VibeBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: SettingsLayout.pageSectionSpacing) {
                        SettingsSessionRhythmSection()
                        SettingsAlertsSection()
                        SettingsDisplaySection()
                        SettingsOtherSection()
                    }
                    .padding(.horizontal, SettingsLayout.pageHorizontalInset)
                    .padding(.top, SettingsLayout.pageTopInset)
                    .padding(.bottom, SettingsLayout.pageBottomInset)
                }
                .onAppear {
                    store.normalizeSettingsIfNeeded()
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }
}
