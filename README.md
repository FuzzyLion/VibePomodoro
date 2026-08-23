# VibePomodoro

VibePomodoro is a calm Pomodoro timer for iOS. It keeps time accurately, stays out of the way while you work, and avoids turning focus into another game or dashboard.

I want it to feel more like a small object sitting beside you than an app constantly asking for attention. The current interface is built around a quiet liquid-glass bubble, with the timer always kept clear and readable.

## What it does

- Uses real timestamps and `targetEndDate`, so the timer stays accurate after backgrounding or relaunching.
- Runs `Focus -> Short Break` cycles followed by a final `Long Break`.
- Supports start, pause, resume, reset, skip, back, and early completion.
- Applies setting changes to the next session without mutating one already in progress.
- Counts only completed sessions in Productivity, with week, month, and year views.
- Handles local notifications, fixed event sounds, haptics, and optional screen-awake behavior.

Focus stays on one screen. Productivity is meant to be honest and easy to read. Settings stays quiet and close to the system. That is basically the product position.

The app is currently iOS-only, and active sessions stay on the device. More detailed behavior and design decisions live in [PRODUCT_VISION.md](./PRODUCT_VISION.md).

## Built with

Swift, SwiftUI, Charts, Combine, `UserDefaults`, UserNotifications, and AVFoundation. The app process has one `PomodoroStore`, while `Date` and `targetEndDate` remain the timer truth.

## What is next

The current goal is a clean public baseline, not endless polishing of the first visual idea.

- Reduce the bubble's steady-state rendering and energy cost, using iPhone 14 Pro as the real-device baseline.
- Remove repeated Productivity calculations and unnecessary full-history persistence work.
- Explore animated numerals as the next visual anchor, then redesign Focus, Productivity, and Settings together around that language.
- Move completed-session history to `SwiftData` once the current version is stable.

The dynamic numeral system is a future direction, not a half-finished feature hidden in the current UI.

## Run it

Open `VibePomodoro.xcodeproj`, select the `VibePomodoro` scheme, and run it on an iOS simulator or device.

```bash
xcodebuild \
  -project VibePomodoro.xcodeproj \
  -scheme VibePomodoro \
  -destination 'platform=iOS Simulator,name=<Simulator Name>' \
  build
```

Run the same command with `test` instead of `build` to execute the test suite.
