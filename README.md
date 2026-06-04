# VibePomodoro

`VibePomodoro` is a calm, timestamp-driven Pomodoro app for iOS. It is built around accurate focus timing, quiet visual feedback, basic productivity review, settings that affect the next session only, and Live Activity support for lock screen and Dynamic Island surfaces.

The full product direction lives in [PRODUCT_VISION.md](./PRODUCT_VISION.md). The implementation contract for future agents and engineering work lives in [AGENT_CONTEXT.md](./AGENT_CONTEXT.md).

## Key Features

- Date-based Pomodoro timing with `targetEndDate` as the runtime truth.
- `Focus -> Short Break` cycles with a final `Long Break` and session completion only after the final long break.
- `Start`, `Pause`, `Resume`, `Reset`, `Skip`, and `Back to last step` semantics.
- Background recovery and app relaunch restoration for unfinished sessions.
- Productivity statistics based only on completed sessions, with `Week / Month / Year` chart ranges.
- Session settings for focus duration, break duration, target rounds, notifications, sound, haptics, and keep-screen-on behavior.
- Fixed event sound mapping for phase boundaries, reset, backward navigation, and session completion.
- Lock screen and Dynamic Island Live Activity surfaces.

## Screens

- `Focus`: the primary single-screen timer experience, centered on a calm liquid-glass bubble timer, lightweight phase/session indicators, secondary controls, and a distinct completion summary state.
- `Productivity`: the review screen for completed session time, daily focus average, streak, and trend charts. Its role is clear and trustworthy data presentation, not decorative analytics.
- `Settings`: the control surface for session rhythm, alerts, display preferences, feedback/share placeholders, and productivity history clearing.
- `Live Activity`: extension target for lock screen and Dynamic Island representations of the current session.

## Tech Stack

- Swift and SwiftUI for the app UI.
- ActivityKit and WidgetKit for Live Activities.
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
├── AGENT_CONTEXT.md
├── VibePomodoro.xcodeproj
├── VibePomodoro/
│   ├── VibePomodoroApp.swift
│   ├── ContentView.swift
│   ├── Core/
│   │   ├── Engine/
│   │   ├── LiveActivity/
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
├── VibePomodoroLiveActivity/
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

The project currently exposes these schemes:

- `VibePomodoro`
- `VibePomodoroLiveActivity`

## Roadmap

1. Continue polishing the `Focus` bubble and layout details.
2. Integrate real custom sound assets where needed.
3. Improve the local notification experience.
4. Migrate productivity persistence to `SwiftData`.
5. Continue polishing lock screen and Dynamic Island Live Activity visuals.
6. Consider `iCloud` sync after the local model is stable.
