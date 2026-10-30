# VibePomodoro

A quiet Pomodoro timer for iOS, and a small project I am building with AI.

I wanted a timer that feels like a small object beside me: easy to read, easy to trust, and easy to leave alone while I work. VibePomodoro brings that idea together through a liquid-glass bubble, a simple focus routine, and a clear record of finished sessions.

## A project made with AI

I lead the product direction, interaction and visual decisions, acceptance criteria, and hands-on review. AI agents have written much of the code and helped me work through architecture, bugs, tests, and revisions.

This is also a learning project. I am interested in the whole process: deciding what the app should do, trying it, noticing what feels wrong, and refining it. The app runs locally, and I am still working on its design and performance.

## A look inside

These screenshots come from the built app on an iPhone 14 Pro simulator running iOS 26.4. Focus shows a paused demo session. Productivity uses generated test history so the charts have something to show.

| Focus | Productivity | Settings |
| :---: | :---: | :---: |
| <img src="docs/screenshots/focus-light.png" alt="Focus in light mode, with a liquid bubble and a paused timer" width="250"> | <img src="docs/screenshots/productivity-light.png" alt="Productivity in light mode, showing sample completed-session totals and trends" width="250"> | <img src="docs/screenshots/settings-light.png" alt="Settings in light mode, showing session rhythm and alert preferences" width="250"> |
| <img src="docs/screenshots/focus-dark.png" alt="Focus in dark mode, with a liquid bubble and a paused timer" width="250"> | <img src="docs/screenshots/productivity-dark.png" alt="Productivity in dark mode, showing the same sample history" width="250"> | <img src="docs/screenshots/settings-dark.png" alt="Settings in dark mode, showing the same session and alert controls" width="250"> |

The [product vision](./PRODUCT_VISION.md) explains the behavior, design choices, current boundaries, and next steps. [Screenshot notes](./docs/screenshots/README.md) record how these previews were captured.

## What it does

- **Focus:** a single-screen timer with start, pause, resume, reset, skip, back, and early completion.
- **Session rhythm:** focus blocks alternate with short breaks; the final focus block leads to a long break.
- **Reliable timing:** real timestamps keep progress consistent across backgrounding and relaunching. Paused time is excluded from the totals.
- **Productivity:** completed-session history, all-time totals, and week, month, and year trends. An active session enters the charts only when it is finished.
- **Preferences:** adjustable durations and rounds, local notifications, fixed event sounds, haptics, screen-awake behavior, and light, dark, or system appearance.

Duration and round changes apply to the next session. Appearance and feedback preferences take effect immediately. Settings and session history are stored locally; active sessions stay on their device.

The active product is the iOS app. Native macOS and Live Activity experiments are archived. SwiftData storage and iCloud history sync remain future work; the current app does not offer cross-device timer control. The feedback and sharing rows in Settings are still marked “Soon.”

## How it is built

The app uses Swift and SwiftUI, with Charts, Combine, UserNotifications, AVFoundation, and UserDefaults. One `PomodoroStore` owns runtime state for the app process. A running timer derives its remaining time from `Date` and `targetEndDate`; UI refreshes only display that state.

```text
VibePomodoro/
├── VibePomodoroApp.swift   # App composition and the single store
├── ContentView.swift      # Shared shell and tab navigation
├── Core/
│   ├── Engine/            # Deterministic session transitions
│   ├── Models/            # Settings, snapshots, history, aggregates
│   └── Store/             # Runtime state, persistence, side effects
├── Screens/
│   ├── Focus/
│   ├── Productivity/
│   └── Settings/
└── Shared/                # Shared theme and UI
```

Completed sessions have their own archive, separate from the active timer. Productivity reads a derived aggregate cache. A setting change writes only the affected data, keeping history writes out of routine adjustments.

## Run it

Use Xcode with an iOS SDK and simulator runtime that support the project's **iOS 26.2** deployment target or later. The app has no external package dependencies.

Open `VibePomodoro.xcodeproj`, select the `VibePomodoro` scheme, and choose an iPhone simulator. For a physical device, select your own signing team in Xcode first.

To build from the command line:

```bash
xcodebuild \
  -project VibePomodoro.xcodeproj \
  -scheme VibePomodoro \
  -destination 'generic/platform=iOS Simulator' \
  build CODE_SIGNING_ALLOWED=NO
```

To run the existing unit and UI tests, replace `<Simulator Name>` with an available device from `xcrun simctl list devices available`:

```bash
xcodebuild \
  -project VibePomodoro.xcodeproj \
  -scheme VibePomodoro \
  -destination 'platform=iOS Simulator,name=<Simulator Name>' \
  test CODE_SIGNING_ALLOWED=NO
```

The tests cover session transitions, background reconciliation, completed-session aggregation, persistence, reminder feedback, and the main screen flows. Simulator captures show layout and app state; energy use, physical haptics, and lock-screen delivery still need device testing.

## What comes next

The next step is a stable version that is easy to understand, run, and review.

- Measure the bubble's rendering and energy cost on an iPhone 14 Pro and refine its animation budget.
- Keep long histories responsive as aggregation and persistence evolve.
- Explore animated numerals as a possible future visual anchor, with Focus, Productivity, and Settings considered together.
- Migrate completed-session history to SwiftData when the current behavior is stable, then consider syncing completed history and selected settings through iCloud.

The liquid bubble remains the current interface while I explore what might come next.
