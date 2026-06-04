import SwiftUI

struct PomodoroExpandedIslandContent: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                PomodoroPhaseBadge(state: state)
                    .frame(height: 24, alignment: .leading)

                Spacer(minLength: 12)

                PomodoroRemainingTimeText(state: state, size: .expanded)
                    .frame(width: 82, height: 24, alignment: .trailing)
            }

            PomodoroExpandedProgressView(state: state)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 2)
        .padding(.bottom, 4)
    }
}

struct PomodoroMinimalView: View {
    let state: PomodoroActivityAttributes.ContentState

    var body: some View {
        PomodoroCompactProgressMark(state: state, size: .minimal)
            .accessibilityLabel(state.phase.title)
    }
}
