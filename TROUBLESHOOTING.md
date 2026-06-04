# Troubleshooting

This document records environment-level issues that can interrupt local development. These fixes are for the developer machine and Simulator state; they do not change app code or erase simulator data unless a step explicitly says so.

## Simulator Only Shows External Display

### Symptoms

Simulator.app opens a black window titled like:

```text
iPhone 17 - External Display
```

The normal iPhone device window is missing or hidden, even though `simctl` and XcodeBuildMCP can still capture screenshots and inspect the simulator UI.

### Cause

This is usually caused by Simulator.app persisting an external display selection for the device. In the Simulator preferences plist, the affected device can have a saved key such as:

```text
DevicePreferences:<DEVICE_UDID>:SimulatorExternalDisplay = 2114
```

When that key is present, Simulator.app can keep restoring the external `TVOut` window instead of the integrated `LCD` device window. Killing `xcodebuild` is not the root cause; it can make the situation visible if a test or recording flow leaves Simulator.app focused on the external display window.

You can confirm the device still has a healthy main display with:

```bash
xcrun simctl io <DEVICE_UDID> enumerate
xcrun simctl io <DEVICE_UDID> screenshot --display internal /private/tmp/main-display.png
```

In `enumerate`, the main screen should appear as `Screen ID: 1`, `Name: LCD`, `Unique ID: PurpleMain`. The external screen usually appears as `Screen ID: 2`, `Name: TVOut`, `Unique ID: PurpleTVOut`.

### Preferred Fix

Use the Simulator menu:

```text
I/O -> External Displays -> Disabled
```

Then quit and reopen Simulator.app for the same device:

```bash
killall Simulator
rm -rf "$HOME/Library/Saved Application State/com.apple.iphonesimulator.savedState"
open -a Simulator --args -CurrentDeviceUDID <DEVICE_UDID>
```

### Command-Line Recovery

If the menu is not usable, run these commands. Replace `<DEVICE_UDID>` with the affected simulator UDID.

```bash
xcrun simctl io <DEVICE_UDID> screenConfig --display external power off
xcrun simctl io <DEVICE_UDID> screenConfig --display internal power on
killall Simulator
rm -rf "$HOME/Library/Saved Application State/com.apple.iphonesimulator.savedState"
open -a Simulator --args -CurrentDeviceUDID <DEVICE_UDID>
```

If Simulator.app still opens the external display window, clear the persisted external display preference for only that device:

```bash
cp "$HOME/Library/Preferences/com.apple.iphonesimulator.plist" \
  /private/tmp/com.apple.iphonesimulator.plist.backup-before-display-fix

/usr/libexec/PlistBuddy \
  -c "Delete :DevicePreferences:<DEVICE_UDID>:SimulatorExternalDisplay" \
  "$HOME/Library/Preferences/com.apple.iphonesimulator.plist"

/usr/libexec/PlistBuddy \
  -c "Delete :DevicePreferences:<DEVICE_UDID>:SimulatorWindowGeometry" \
  "$HOME/Library/Preferences/com.apple.iphonesimulator.plist"

rm -rf "$HOME/Library/Saved Application State/com.apple.iphonesimulator.savedState"
open -a Simulator --args -CurrentDeviceUDID <DEVICE_UDID>
```

If the `PlistBuddy Delete` command reports that a key does not exist, that part is already clean.

### Last Resort: Restart the Device Without Erasing Data

If the external display screenshot command hangs or the display topology remains stale, restart only the affected simulator device:

```bash
xcrun simctl shutdown <DEVICE_UDID>
xcrun simctl boot <DEVICE_UDID>
xcrun simctl bootstatus <DEVICE_UDID> -b
xcrun simctl io <DEVICE_UDID> screenConfig --display external power off
xcrun simctl io <DEVICE_UDID> screenConfig --display internal power on
open -a Simulator --args -CurrentDeviceUDID <DEVICE_UDID>
```

This restarts the simulator runtime but does not erase app data. Avoid `simctl erase` unless you intentionally want to wipe the simulator.

### Verification

After recovery, verify all three layers:

```bash
xcrun simctl io <DEVICE_UDID> screenshot --display internal /private/tmp/main-display-after-fix.png
/usr/libexec/PlistBuddy -c "Print :DevicePreferences:<DEVICE_UDID>" \
  "$HOME/Library/Preferences/com.apple.iphonesimulator.plist"
```

The visible Simulator.app window should be titled like:

```text
iPhone 17 - iOS 26.4
```

It should not be titled:

```text
iPhone 17 - External Display
```

XcodeBuildMCP or `simctl` screenshots should show the normal iPhone screen, not a blank external display.
