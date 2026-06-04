import ActivityKit
import SwiftUI
import WidgetKit

struct PomodoroLockScreenLiveActivityContainer: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        let palette = PomodoroLiveActivityPalette()

        PomodoroLockScreenLiveActivityView(state: state, palette: palette)
            .activityBackgroundTint(palette.cardBackground(for: state.phase))
            .activitySystemActionForegroundColor(state.phase.activityStyle.accent)
    }
}

struct PomodoroLockScreenLiveActivityView: View {
    let state: PomodoroActivityAttributes.ContentState
    let palette: PomodoroLiveActivityPalette

    var body: some View {
        Group {
            if state.shouldUseTimelineDisplay {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    content(at: timeline.date)
                }
            } else {
                content(at: .now)
            }
        }
    }

    private func content(at date: Date) -> some View {
        ZStack(alignment: .topLeading) {
            PomodoroBreathField(phase: state.displayPhase(at: date))

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    PomodoroPhaseBadge(state: state, foregroundColor: palette.primaryText)
                    Spacer(minLength: 12)
                    PomodoroRoundLabel(
                        state: state,
                        size: .lockScreen,
                        foregroundColor: palette.secondaryText
                    )
                }

                PomodoroRemainingTimeText(state: state, size: .lockScreen, foregroundColor: palette.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                PomodoroStepProgressBar(state: state, inactiveColor: palette.inactiveProgress)
            }
            .padding(18)
        }
    }
}
