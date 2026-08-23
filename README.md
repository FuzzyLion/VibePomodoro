# VibePomodoro

`VibePomodoro` is a calm, timestamp-driven Pomodoro app for iOS. It is built around accurate focus timing, quiet visual feedback, straightforward productivity review, and settings that affect the next session only.

The full product direction lives in [PRODUCT_VISION.md](./PRODUCT_VISION.md).

## Key Features

- Date-based Pomodoro timing with `targetEndDate` as the runtime truth.
- `Focus -> Short Break` cycles with a final `Long Break` and session completion only after the final long break.
- `Start`, `Pause`, `Resume`, `Reset`, `Skip`, and `Back to last step` semantics.
- Background recovery and app relaunch restoration for unfinished sessions.
- Productivity statistics based only on completed sessions, with `Week / Month / Year` chart ranges.
- Session settings for focus duration, break duration, target rounds, notifications, sound, haptics, and keep-screen-on behavior.
- Fixed event sound mapping for phase boundaries, reset, backward navigation, and session completion.

## Screens

- `Focus`: the primary single-screen timer experience, centered on a calm liquid-glass bubble timer, lightweight phase/session indicators, secondary controls, and a distinct completion summary state.
- `Productivity`: the review screen for completed session time, daily focus average, streak, and trend charts. Its role is clear and trustworthy data presentation, not decorative analytics.
- `Settings`: the control surface for session rhythm, alerts, display preferences, feedback/share placeholders, and productivity history clearing.

## Tech Stack

- Swift and SwiftUI for the app UI.
- Charts for productivity trend rendering.
- Combine and `ObservableObject` for runtime store publishing.
- `UserDefaults` for current persistence.
- UserNotifications, AVFoundation, UIKit haptics, and idle-timer integration for reminders and feedback.
- XCTest and Swift Testing targets for tests.

## Repository Structure

```text
VibePomodoro/
├── README.md
├── PRODUCT_VISION.md
├── VibePomodoro.xcodeproj
├── VibePomodoro/
│   ├── VibePomodoroApp.swift
│   ├── ContentView.swift
│   ├── Core/
│   │   ├── Engine/
│   │   ├── Models/
│   │   └── Store/
│   ├── Screens/
│   │   ├── Focus/
│   │   ├── Productivity/
│   │   └── Settings/
│   ├── Shared/
│   │   ├── Theme/
│   │   └── UI/
│   ├── Resources/Sounds/
│   └── Assets.xcassets/
├── VibePomodoroTests/
└── VibePomodoroUITests/
```

## Build and Run

Open `VibePomodoro.xcodeproj` in Xcode, select the `VibePomodoro` scheme, choose an iOS simulator or device, then build and run.

From the command line, use an installed simulator destination:

```bash
xcodebuild -project VibePomodoro.xcodeproj -scheme VibePomodoro -destination 'platform=iOS Simulator,name=<Simulator Name>' build
```

To run tests:

```bash
xcodebuild -project VibePomodoro.xcodeproj -scheme VibePomodoro -destination 'platform=iOS Simulator,name=<Simulator Name>' test
```

The project exposes the `VibePomodoro` scheme.

## Roadmap

1. Continue polishing the `Focus` bubble and layout details.
2. Integrate real custom sound assets where needed.
3. Improve the local notification experience.
4. Migrate productivity persistence to `SwiftData`.
5. Strengthen accessibility and edge-case coverage.
6. Consider `iCloud` sync after the local model is stable.
