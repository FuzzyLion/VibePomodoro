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
        stepDuration: 25 * 60,
        targetEndDate: Date().addingTimeInterval(12 * 60),
        pausedRemainingDuration: nil,
        scheduledSteps: [
            PomodoroActivityAttributes.ScheduledStep(
                phase: .focus,
                roundNumber: 2,
                stepDuration: 25 * 60,
                startDate: Date().addingTimeInterval(-13 * 60),
                endDate: Date().addingTimeInterval(12 * 60)
            ),
            PomodoroActivityAttributes.ScheduledStep(
                phase: .shortBreak,
                roundNumber: 2,
                stepDuration: 5 * 60,
                startDate: Date().addingTimeInterval(12 * 60),
                endDate: Date().addingTimeInterval(17 * 60)
            )
        ]
    )
    PomodoroActivityAttributes.ContentState(
        sessionID: UUID().uuidString,
        phase: .shortBreak,
        roundNumber: 2,
        targetRounds: 4,
        runState: .paused,
        stepDuration: 5 * 60,
        targetEndDate: nil,
        pausedRemainingDuration: 4 * 60 + 22,
        scheduledSteps: []
    )
}
