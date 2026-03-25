import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: PomodoroStore

    var body: some View {
        NavigationStack {
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
            .onAppear(perform: normalizeTimerSettingsIfNeeded)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func normalizeTimerSettingsIfNeeded() {
        let normalizedFocus = SettingsTimerField.focus.value(in: store.settings)
        if store.settings.focusMinutes != normalizedFocus {
            store.updateFocusMinutes(normalizedFocus, fireFeedback: false)
        }

        let normalizedShortBreak = SettingsTimerField.shortBreak.value(in: store.settings)
        if store.settings.shortBreakMinutes != normalizedShortBreak {
            store.updateShortBreakMinutes(normalizedShortBreak, fireFeedback: false)
        }

        let normalizedLongBreak = SettingsTimerField.longBreak.value(in: store.settings)
        if store.settings.longBreakMinutes != normalizedLongBreak {
            store.updateLongBreakMinutes(normalizedLongBreak, fireFeedback: false)
        }

        let normalizedRounds = SettingsTimerField.rounds.value(in: store.settings)
        if store.settings.targetRounds != normalizedRounds {
            store.updateTargetRounds(normalizedRounds, fireFeedback: false)
        }
    }
}
