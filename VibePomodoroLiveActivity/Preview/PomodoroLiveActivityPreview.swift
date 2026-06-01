import ActivityKit
import SwiftUI
import WidgetKit

#Preview("Lock Screen", as: .content, using: PomodoroActivityAttributes()) {
    PomodoroLiveActivityWidget()
} contentStates: {
    PomodoroActivityAttributes.ContentState(
        sessionID: UUID().uuidString,
        phase: .focus,
        roundNumber: 2,
        targetRounds: 4,
        runState: .running,
        targetEndDate: Date().addingTimeInterval(12 * 60),
        pausedRemainingDuration: nil
    )
    PomodoroActivityAttributes.ContentState(
        sessionID: UUID().uuidString,
        phase: .shortBreak,
        roundNumber: 2,
        targetRounds: 4,
        runState: .paused,
        targetEndDate: nil,
        pausedRemainingDuration: 4 * 60 + 22
    )
}
