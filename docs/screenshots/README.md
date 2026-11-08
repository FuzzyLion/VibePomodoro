# App screenshots

Captured from the locally built VibePomodoro app on **2026-10-30**. Both the project README and product vision use these same files.

| Capture detail | Value |
| --- | --- |
| Build | Debug, `VibePomodoro` iOS scheme |
| Toolchain | Xcode 27.2, build 27B52 |
| Simulator | iPhone 14 Pro, iOS 26.4 |
| Resolution | 1179 × 2556 pixels, portrait |
| Appearance | Explicit Light and Dark launch overrides |
| Status bar | 9:41, Wi-Fi, full battery |
| Storage | Isolated `Qi.VibePomodoro.DocsPreview` UserDefaults suite |

The PNG files are direct `simctl io … screenshot` captures. The documentation scales them for display; the source images retain their captured resolution.

## States shown

| Files | App state |
| --- | --- |
| `focus-light.png`, `focus-dark.png` | Paused in the second focus block of a four-round session, with 12:30 remaining. A local demo snapshot supplies the elapsed segments so the liquid level, round markers, and Resume control can be inspected together. |
| `productivity-light.png`, `productivity-dark.png` | Week view with the app's existing `long-extreme` UI-testing fixture. The totals and charts are generated sample data, not personal productivity records. |
| `settings-light.png`, `settings-dark.png` | Default session rhythm and alert preferences. The page is at the top; Display and Other continue below the visible area. |

Focus uses the same paused snapshot in both appearances. Productivity uses the same fixture recipe in both appearances. Neither demonstration changes the normal app storage suite.

## Refreshing the captures

Build and install the current app on an iPhone simulator. Use a separate `VIBE_DEFAULTS_SUITE` for previews. The existing `--ui-testing` launch argument suppresses the notification permission prompt; `--appearance-light` and `--appearance-dark` choose the appearance. `--open-productivity` and `--open-settings` open those pages directly.

For a populated Productivity preview, pass `VIBE_PRODUCTIVITY_FIXTURE=long-extreme` along with `--ui-testing`. When using `simctl launch`, app environment variables need the `SIMCTL_CHILD_` prefix, for example:

```bash
SIMCTL_CHILD_VIBE_DEFAULTS_SUITE=Qi.VibePomodoro.DocsPreview \
SIMCTL_CHILD_VIBE_PRODUCTIVITY_FIXTURE=long-extreme \
xcrun simctl launch booted Qi.VibePomodoro \
  --ui-testing --open-productivity --appearance-light

xcrun simctl io booted screenshot docs/screenshots/productivity-light.png
```

Terminate the app before relaunching with different arguments, let the page settle, and inspect each screenshot before replacing it. To reproduce the Focus state, also pass `VIBE_FOCUS_FIXTURE=focus-2-0.5`. With `--ui-testing`, it seeds a paused session with the first focus and short break complete and 750 seconds recorded in the second focus block. The value reads `<phase>-<round>-<progress>`, for example `shortBreak-1-0.3`, and a trailing `-running` starts the timer instead of pausing it.

Screenshots document the visible UI. They do not establish physical haptic quality, notification delivery while locked, or real-device energy use.
