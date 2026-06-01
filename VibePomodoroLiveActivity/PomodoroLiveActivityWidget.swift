import ActivityKit
import SwiftUI
import WidgetKit

struct PomodoroLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            PomodoroLockScreenLiveActivityContainer(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    PomodoroExpandedIslandContent(state: context.state)
                }
            } compactLeading: {
                PomodoroPhaseDot(phase: context.state.phase)
                    .frame(width: 13, height: 13)
            } compactTrailing: {
                EmptyView()
            } minimal: {
                PomodoroMinimalView(state: context.state)
            }
        }
    }
}
