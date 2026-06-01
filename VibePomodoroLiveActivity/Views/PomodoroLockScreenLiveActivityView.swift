import ActivityKit
import SwiftUI
import WidgetKit

struct PomodoroLockScreenLiveActivityContainer: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        let palette = PomodoroLiveActivityPalette()

        PomodoroLockScreenLiveActivityView(state: state, palette: palette)
            .activityBackgroundTint(palette.cardBackground)
            .activitySystemActionForegroundColor(state.phase.activityStyle.accent)
    }
}

struct PomodoroLockScreenLiveActivityView: View {
    let state: PomodoroActivityAttributes.ContentState
    let palette: PomodoroLiveActivityPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                PomodoroPhaseBadge(state: state, foregroundColor: palette.primaryText)
                Spacer(minLength: 12)
                Text("Round \(state.roundNumber)/\(state.targetRounds)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
                    .monospacedDigit()
            }

            PomodoroRemainingTimeText(state: state, size: .lockScreen, foregroundColor: palette.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            PomodoroRoundProgress(state: state, inactiveColor: palette.inactiveProgress)
        }
        .padding(18)
    }
}
