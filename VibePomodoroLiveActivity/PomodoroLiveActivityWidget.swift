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
                PomodoroCompactProgressMark(state: context.state, size: .compact)
            } compactTrailing: {
                PomodoroRemainingTimeText(state: context.state, size: .compact)
                    .frame(width: 42, alignment: .trailing)
            } minimal: {
                PomodoroMinimalView(state: context.state)
            }
        }
    }
}
