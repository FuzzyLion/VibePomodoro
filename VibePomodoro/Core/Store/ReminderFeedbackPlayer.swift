import AVFoundation
import Foundation
import UIKit

enum ReminderSoundResource: String, CaseIterable, Equatable {
    case phaseCompletePop = "phase-complete-pop"
    case nextPhaseWhoosh = "next-phase-whoosh"
    case sessionCompleteThud = "session-complete-thud"

    var fileName: String {
        "\(rawValue).caf"
    }

    var notificationSoundName: String {
        fileName
    }

    var bundleURL: URL? {
        let candidateBundles = [Bundle.main, Bundle(for: ReminderFeedbackBundleProbe.self)]
            + Bundle.allBundles
            + Bundle.allFrameworks

        for bundle in candidateBundles {
            if let url = bundle.url(forResource: rawValue, withExtension: "caf") {
                return url
            }

            if let url = bundle.url(forResource: rawValue, withExtension: "caf", subdirectory: "Sounds") {
                return url
            }

            if let url = bundle.url(forResource: rawValue, withExtension: "caf", subdirectory: "Resources/Sounds") {
                return url
            }
        }

        return nil
    }
}

enum ReminderHaptic: Equatable {
    case warning
    case success
    case softImpact
}

enum ReminderFeedbackAction: Equatable {
    case sound(ReminderSoundResource)
    case haptic(ReminderHaptic)
    case delay(TimeInterval)
}

enum ReminderFeedbackPlan {
    static let nextPhaseStartDelay: TimeInterval = 0.18

    static func actions(
        for events: [PomodoroEvent],
        isForeground: Bool,
        soundEnabled: Bool,
        hapticsEnabled: Bool
    ) -> [ReminderFeedbackAction] {
        guard isForeground else { return [] }

        if events.contains(.sessionCompleted) {
            return actions(
                sound: .sessionCompleteThud,
                haptic: .success,
                soundEnabled: soundEnabled,
                hapticsEnabled: hapticsEnabled
            )
        }

        let hasPhaseCompleted = events.contains { event in
            if case .phaseCompleted = event {
                return true
            }
            return false
        }
        let hasPhaseStarted = events.contains { event in
            if case .phaseStarted = event {
                return true
            }
            return false
        }

        guard hasPhaseCompleted else { return [] }

        var plannedActions = actions(
            sound: .phaseCompletePop,
            haptic: .warning,
            soundEnabled: soundEnabled,
            hapticsEnabled: hapticsEnabled
        )

        if hasPhaseStarted {
            let nextPhaseActions = actions(
                sound: .nextPhaseWhoosh,
                haptic: .softImpact,
                soundEnabled: soundEnabled,
                hapticsEnabled: hapticsEnabled
            )

            if !plannedActions.isEmpty && !nextPhaseActions.isEmpty {
                plannedActions.append(.delay(nextPhaseStartDelay))
            }

            plannedActions.append(contentsOf: nextPhaseActions)
        }

        return plannedActions
    }

    private static func actions(
        sound: ReminderSoundResource,
        haptic: ReminderHaptic,
        soundEnabled: Bool,
        hapticsEnabled: Bool
    ) -> [ReminderFeedbackAction] {
        var actions: [ReminderFeedbackAction] = []

        if soundEnabled {
            actions.append(.sound(sound))
        }

        if hapticsEnabled {
            actions.append(.haptic(haptic))
        }

        return actions
    }
}

@MainActor
protocol ReminderFeedbackPlaying: AnyObject {
    func play(_ actions: [ReminderFeedbackAction])
}

@MainActor
final class ReminderFeedbackPlayer: ReminderFeedbackPlaying {
    private var players: [AVAudioPlayer] = []

    func play(_ actions: [ReminderFeedbackAction]) {
        guard !actions.isEmpty else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }

            for action in actions {
                switch action {
                case .sound(let resource):
                    playSound(resource)
                case .haptic(let haptic):
                    playHaptic(haptic)
                case .delay(let interval):
                    try? await Task.sleep(nanoseconds: UInt64(max(0, interval) * 1_000_000_000))
                }
            }
        }
    }

    private func playSound(_ resource: ReminderSoundResource) {
        guard let url = resource.bundleURL else { return }

        players.removeAll { !$0.isPlaying }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            players.append(player)
        } catch {
            return
        }
    }

    private func playHaptic(_ haptic: ReminderHaptic) {
        switch haptic {
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case .softImpact:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.prepare()
            generator.impactOccurred(intensity: 0.55)
        }
    }
}

private final class ReminderFeedbackBundleProbe {}
