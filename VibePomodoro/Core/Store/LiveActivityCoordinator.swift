import ActivityKit
import Foundation

@MainActor
protocol PomodoroLiveActivityCoordinating {
    func refresh(session: SessionSnapshot?, now: Date)
}

@MainActor
final class LiveActivityCoordinator: PomodoroLiveActivityCoordinating {
    private let client: PomodoroLiveActivityClient

    init(client: PomodoroLiveActivityClient? = nil) {
        self.client = client ?? ActivityKitPomodoroLiveActivityClient()
    }

    func refresh(session: SessionSnapshot?, now: Date = .now) {
        Task {
            await apply(session: session, now: now)
        }
    }

    func apply(session: SessionSnapshot?, now: Date = .now) async {
        let snapshot = PomodoroLiveActivitySnapshot(session: session, now: now)
        await client.apply(snapshot)
    }
}

@MainActor
struct NoopLiveActivityCoordinator: PomodoroLiveActivityCoordinating {
    func refresh(session: SessionSnapshot?, now: Date) {}
}

@MainActor
protocol PomodoroLiveActivityClient {
    func apply(_ snapshot: PomodoroLiveActivitySnapshot?) async
}

@MainActor
struct ActivityKitPomodoroLiveActivityClient: PomodoroLiveActivityClient {
    func apply(_ snapshot: PomodoroLiveActivitySnapshot?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            await endAllActivities()
            return
        }

        guard let snapshot else {
            await endAllActivities()
            return
        }

        let content = ActivityContent(
            state: snapshot.contentState,
            staleDate: snapshot.contentState.targetEndDate?.addingTimeInterval(60)
        )
        let activities = Activity<PomodoroActivityAttributes>.activities
        let matchingActivity = activities.first {
            $0.content.state.sessionID == snapshot.contentState.sessionID
        }

        for activity in activities where activity.content.state.sessionID != snapshot.contentState.sessionID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        if snapshot.contentState.runState == .completed {
            if let matchingActivity {
                await matchingActivity.end(
                    content,
                    dismissalPolicy: .after(.now.addingTimeInterval(15 * 60))
                )
            }
            return
        }

        if let matchingActivity {
            await matchingActivity.update(content)
            return
        }

        do {
            _ = try Activity<PomodoroActivityAttributes>.request(
                attributes: snapshot.attributes,
                content: content,
                pushType: nil
            )
        } catch {
            await endAllActivities()
        }
    }

    private func endAllActivities() async {
        for activity in Activity<PomodoroActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
