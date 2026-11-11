# Product Vision

I'm building VibePomodoro as an iOS Pomodoro timer with a glass vessel at its center. The app already handles focus and break cycles, restores unfinished sessions, and keeps completed history locally.

I want to start a timer and leave it beside me while I work. That is why the countdown stays prominent, frequent actions fit on one screen, and the vessel changes shape when the phase changes. A finished session leaves its focus total in the same vessel.

I make the product and design decisions and review the app hands-on. Much of the implementation was written by AI agents. This document records the decisions and the behavior that later changes must preserve. Setup is in the [README](README.md), and the [screenshot gallery](docs/screenshots/README.md) records the preview states.

## What I'm building

The app has three pages, Focus, Productivity, and Settings, and requires iOS 26.2 or later. I have archived the native macOS and Live Activity experiments. They are outside the active product.

The app supports timestamp-based timing, background and relaunch recovery, focus and break cycles, early completion, an in-place completion summary, local history, interactive productivity charts, local notifications, event sounds, haptics, and appearance preferences. Send Feedback and Share App remain placeholders marked Soon.

Settings, the active snapshot, completed sessions, and the statistics cache live on the device. Each device owns its active timer. Future iCloud work may cover completed sessions and explicitly selected settings. Active-session handoff, Handoff, and simultaneous timer control across devices remain outside this scope.

SwiftData, iCloud sync, advanced analytics, imported sounds, and more elaborate reminder rules aren't implemented. An interface built around animated numerals is still an idea. The vessels are the design in use.

### The app today

These are direct captures of the current build on iPhone 18 Pro / iOS 27.2, taken on 10 November 2026. The Focus session is a paused demonstration, and Productivity contains generated test history. Both appearances use the same fixture recipes. Productivity and Settings scroll beyond the captured viewport.

| Page | Light | Dark |
| --- | :---: | :---: |
| Focus | <img src="docs/screenshots/focus-light.png" alt="Paused Focus timer in the upright amber vessel, light appearance" width="230"> | <img src="docs/screenshots/focus-dark.png" alt="The same paused Focus state, dark appearance" width="230"> |
| Productivity | <img src="docs/screenshots/productivity-light.png" alt="All-time summary and Rhythm chart with generated history, light appearance" width="230"> | <img src="docs/screenshots/productivity-dark.png" alt="The same generated Productivity history, dark appearance" width="230"> |
| Settings | <img src="docs/screenshots/settings-light.png" alt="Session Rhythm and alert preferences, light appearance" width="230"> | <img src="docs/screenshots/settings-dark.png" alt="The same default preferences, dark appearance" width="230"> |

### Design choices

The vessel gives the app its identity. I don't want every control competing with it, so the surrounding navigation stays native and the movement stays slow. Gamified check-ins, rewards, decorative statistics, bright icon walls, floating particles, spirals, and constant wobbling don't fit that purpose.

I use Liquid Glass for controls that sit above content, including the tab bar, menus, value controls, and Focus actions. The vessel is the one exception. Productivity and Settings cards use regular material because their text needs a stable background.

The accounting has to match the controls. For example, skipping an unfinished block keeps time already spent but earns no completed block. Paused time and sessions still in progress stay out of archived totals.

## Session rules

### Time and recovery

`Date` and `targetEndDate` are the timing truth. A running step derives its remaining duration from its end timestamp. Pausing settles the elapsed segment, preserves the remaining time, and clears the end timestamp. Resuming creates a new timestamp from that remaining duration.

I keep time separate from screen refreshes. A decreasing counter would depend on the app continuing to run, which is the wrong assumption when the phone locks. Timers and `TimelineView` can refresh the screen or reconcile boundaries, but elapsed time comes from timestamps. Returning to the app reconciles any crossed phase boundaries. Relaunching restores the unfinished session without duplicating its archive.

### Rhythm and controls

Each focus block is followed by a short break until the final round, which leads to a long break. With four rounds:

```text
Focus → Short Break → Focus → Short Break
      → Focus → Short Break → Focus → Long Break → Session End
```

One round is `Focus → Long Break → Session End`. The normal session ends after the final long break. Skipping the final step or confirming Finish early also ends and archives it. Only focus blocks that ran their full planned duration count as completed.

| Action | Required behavior |
| --- | --- |
| Start | Begin the current step. The initial manual start is silent. |
| Pause | Settle elapsed time and hold the remainder. Paused time is excluded. |
| Resume | Continue from the remainder with a new end timestamp. |
| Reset | Clear the current step's recorded time and restore its full duration. Restart immediately if running; otherwise return to idle. |
| Skip | Settle elapsed time and advance once. Stay running if running; otherwise stay paused. An unfinished focus block earns no completed round. |
| Back to last step | Clear recorded time for the current and previous steps and restore the previous step at full duration. Continue running if running; otherwise return to paused or idle. On the first step, act as Reset. |
| Finish early | Become available after some time has elapsed. Confirm, settle elapsed time, archive the session, and show what was completed. |
| Done | Dismiss the summary and prepare a fresh session from the current settings. |

An archive keeps only the recorded time and fully completed focus blocks. Reset and Back must also remove the affected time from the eventual archive.

A session keeps the durations and round count chosen when it was created. Rhythm changes affect the next session. Appearance, notifications, sound, haptics, and screen-awake preferences apply immediately.

### Reminders and feedback

A phase ending and its successor starting form one boundary event with one response. A completion event uses only the completion response. Background reconciliation must not replay a sequence of missed foreground sounds or haptics.

| Event | Sound | Foreground haptic |
| --- | --- | --- |
| Move forward, including Skip | `next-phase-whoosh.caf` | Soft impact |
| Back to last step | `phase-complete-pop.caf` | Rigid impact |
| Reset | `phase-reset-notification.caf` | Soft impact |
| Session complete | `session-complete-thud.caf` | Success |

Local notifications carry the boundary or completion sound while the app is backgrounded or the phone is locked. The app does not drive background haptics. Settings adjustments have their own gentle haptic response; silently normalizing an older saved value must not trigger one.

I ask for notification permission on the first Start. At launch, the user hasn't done anything that needs a reminder yet. Permission is read again whenever the app returns to the foreground, since it may have changed in iOS Settings.

## Focus

### Three vessels

| Phase | Default duration | Shape | Color |
| --- | --- | --- | --- |
| Focus | 25 minutes | Upright drop, full low down and gathered toward the top | Amber Gold |
| Short Break | 5 minutes | Rising bubble, wider high up and gently leaning | Soft Mist |
| Long Break | 15 minutes | Broad, low vessel at rest | Soft Jade |

I want the outline to read as blown glass. An earlier version bent sharply at the curve joins and looked cut, so the current outlines need smooth changes in curvature. Focus is taller than it is wide to distinguish it from the long break. All three stand on one baseline, with liquid filling each from its own bottom to its own top. The numerals stay centered. A phase change can raise or lower the top without lifting the vessel off the page.

The wall has visible thickness. Liquid sits inside it and meets the glass without gaps at the sides, bottom, or surface. Light comes from the upper left, catching the wall and the far edge of the liquid. A soft shadow falls lower right, with a tighter contact shadow at the base. A phase-tinted caustic brightens and drifts within that shadow as the vessel fills, without a hard white core.

The vessel can use `UltraThinMaterial` with additional refraction, highlights, and shading. Light and dark mode keep the same geometry. Brightness and contrast adapt to the background.

### Liquid, numerals, and movement

The surface has two wave layers. Near and far edges move differently and meet the glass all the way around. Seen slightly from above, the surface reads as an ellipse, with a lit far edge, a near waterline, and a faint meniscus. Surface highlights fade toward the walls. In light mode, a thin glass edge, a soft tinted rim, and a slightly deeper waterline keep the level readable.

Liquid color follows the light's path through it. A longer path takes more tint, making the center deeper than the edges and the lower part of a full vessel darker. Curved glass gathers light along the wall away from the source. The surface reflects more toward its far edge and glints where waves face the light. Faint caustic threads stay low, away from the surface; radial glows inside the liquid are outside this design. Distance to the wall must be evaluated horizontally and vertically so the liquid meets near-level bottoms and tops correctly.

The countdown uses Didot Bold, with equal digit widths so it does not shift as time changes. The numerals read as a thin solid inside the vessel. They have a lit upper-left bevel, a faint lower-right rim, a side about two points deep, and a soft shadow on the back wall. The warm graphite face in light mode must maintain at least 3:1 contrast against the glass, with a phase-tinted shadow. Dark mode uses white porcelain over a gray side with a dark shadow. Increase Contrast deepens the light face; the face dims slightly over the last seconds.

Above the surface, the numerals keep that treatment and stay in front of its highlight. Below it, the liquid tints, gently magnifies, and refracts them. Refraction at the waterline is a small kink, never a second digit. The wave and refraction can move while the figures themselves refresh once per second.

The surface moves slowly and stops when paused. During a phase change, the outline, wall, liquid, glow, shadow, and color follow the same transition progress. Otherwise one layer can reach the new shape before its neighbors. The waves keep their motion through the change. The final fill happens during `00:01`; appearing full several seconds early would give the wrong timing cue.

Continuous surface animation stops while paused, off Focus, or backgrounded. Reduce Motion disables surface movement and replaces spatial transitions with fades. Low Power Mode omits caustic threads and the glow beneath the vessel.

### Controls, status, and immersion

Start / Pause / Resume is the primary action below the vessel. Back and Skip occupy separate secondary slots; Reset and Finish early sit in the top row around the phase title and status light. Secondary actions appear only when useful, but retain their layout slots so the primary button stays put. Before starting, show the vessel and Start; after finishing, show its summary and Done.

Keep controls aligned with the vessel, low on the page with a clear gap above native navigation. Top actions should feel like toolbar items. Pause is neutral; Start, Resume, and Done carry a light wash of the phase color. Button width accommodates the longest label. Icons share a consistent weight, with restrained dark foregrounds in light mode and warm white in dark mode.

A circular `.glass` button owns its visible circle; an outer slot owns hit area and alignment. Keep custom pressed-opacity animations off that surface because the system already provides interaction feedback. Back, Pause/Resume, and Skip may share a sampling region, but their shapes must stay separate. If sampling flicker returns, check their host and `GlassEffectContainer` structure first.

Status reads Ready, Focus, Short Break, or Long Break. The primary control communicates running versus paused. The badge follows its content on one line and remains subordinate to the countdown.

One compact marker represents each focus round. The current focus round is half filled. A past round fills only when its focus block reached the full duration; skipped and early-finished blocks remain outlined. Future markers stay subdued. The same completed-block meaning carries into Productivity.

Tapping the background outside the vessel hides chrome, system status, and the tab bar; tapping again restores them. Keep the vessel's global position stable through safe-area changes. Immersion is unavailable during the completion summary and while VoiceOver is running. The shared shell coordinates tab-bar visibility.

### Completion in place

The vessel stays on Focus and becomes the summary. Its countdown turns into recorded focus time beneath FOCUSED, in the same numeral and liquid treatment. The fill settles to the share of planned focus actually recorded, just below the rim when the plan is met. The surface becomes calm.

Use Session complete after the normal end and Session finished after early completion, with a short note that the work was kept. Round markers show fully completed blocks; one line gives that count and break time. Other controls step aside for Done, and the tab bar remains hidden until Done.

Change controls first, settle the liquid from the final overfill, blur the countdown into its total, and reveal the breakdown last. Keep one continuous object through the transition, without doubled or empty frames. Done drains the vessel toward its starting level as it returns to the focus shape; the total becomes the countdown and Done becomes Start. Reduce Motion uses fades.

I have left duration changes off the vessel itself. A drag could change the time accidentally and complicate both timing and statistics. Finish early covers ending sooner. If I add extensions later, I would start with explicit actions such as +5 min or Adjust Duration.

## Productivity

### Accounting

Productivity uses effective running time from archived sessions. A session enters the charts after the final long break, a final Skip, or confirmed early completion. Active sessions remain outside formal totals. Pauses add nothing. Time crossing midnight is allocated to the calendar days it occupied, and an archive enters the aggregate cache exactly once.

| Metric | Definition |
| --- | --- |
| Focus Time | Recorded time in focus blocks. |
| Short Break Time | Recorded time in short breaks. |
| Long Break Time | Recorded time in long breaks. |
| Break Time | Short Break Time + Long Break Time. |
| Session Time | Focus Time + Break Time. |
| Completed Focus Count | Focus blocks that ran their full planned duration. |
| Daily Focus Avg | Archived focus time divided by calendar days with recorded focus. Days without focus are excluded. |
| Streak | Consecutive days with archived focus. Count backward from today, or from yesterday until today has focus, so the streak holds through the day and ends only after a full missed day. |

Clear Productivity History removes completed records and the aggregate cache. The page immediately returns to an empty history; later sessions begin a fresh one. The active session and settings survive.

With no archive, the summary and Rhythm show zeros and No finished sessions yet. Leave out the Sessions card and explain that sessions appear when they end, including ones finished early. Generated bars belong only in tests and labeled documentation previews.

### Hierarchy and ranges

Keep the system large title and an icon-only range `Menu` in the trailing toolbar. Its Week, Month, and Year entries are toggles so iOS supplies the selected checkmark, including at accessibility text sizes. Use system toolbar material.

The first card is headed ALL TIME COMPLETED SESSIONS. I put Focus Time first because Session Time also increases with longer breaks. Daily Focus Avg and Streak sit below it. The footer keeps Session Time, finished-session count, and completed focus-block count available without giving them equal weight.

A block is one focus round; a session is the whole cycle. Lifetime time stays in hours so it cannot be confused with the streak's days. From 100 hours onward, omit minutes.

That summary always stays all-time. A quiet caption below it names the chart window and dates. Rhythm and Sessions follow, without title icons or range badges.

| Range | Window | Slots |
| --- | --- | --- |
| Week | Last seven days, including today | One per day, all labeled |
| Month | Last 30 days, including today | One per day, every seventh day labeled backward from today |
| Year | Last 12 months, including the current month | One per calendar month, all labeled |

Week and Month read daily aggregates; Year rolls them into calendar months. I keep Month as 30 daily bars because 30 days don't divide into equal weeks. A short last group could look like a drop in activity. Grouping must preserve totals, labels and bars must share slot centers, and the rightmost label must stay readable.

### Rhythm and Sessions

Rhythm's top row shows Focus, Breaks, and Blocks. Amber and jade dots beside the first two also serve as the legend. Each bar stacks focus below breaks, with a deeper tint at the base and a faint surface highlight fading toward the walls. Week and Year keep empty glass columns behind the bars so missing days or months retain their place. I leave those tracks out of Month because thirty background columns read as stripes.

A dashed line marks average focus across slots with any focus, matching the active-day rule used by Daily Focus Avg. An amber avg names it in the value-axis column; a nearby step label yields space. Bars carry no value labels and the card adds no explanatory sentence about its figures.

Use a fixed-width value-axis column with round steps and at most four intervals. Up to one hour, show 0–60 minutes in 20-minute steps. Above that, use whole hours so axis labels do not need minute components.

Tapping a slot places its date at the Rhythm card's upper right, replaces the top row with that slot's figures, and dims other bars. Keep numeric columns fixed. The current month names its elapsed dates, such as 1–10 Nov. The Sessions card then shows the latest five sessions that started in that slot, newest first, followed by a count such as 29 more when needed.

Tap the selected slot again or tap the value-axis labels to return to the whole range. Changing the range clears the selection. Selection is tap-only, so starting a drag over the chart still scrolls the page.

Without a selection, Sessions lists the latest five starts in the range. Each row shows its start, one filled or outlined marker per focus round, and recorded focus time. A bar allocates time by the day it occurred; a session row is grouped by its start, so a session crossing midnight can contribute to more than one bar.

### Readability and accessibility

All three cards use regular material, with more visual weight on the summary. I keep SF Pro and monospaced digits on this page. Didot works inside the Focus vessel, but repeating it across statistics adds a second voice and crowds the metric row. Amber marks focus, jade marks breaks, and other text stays neutral. Summary focus labels use amber ink, deeper in light mode and lighter in dark mode.

Card text must reach at least 4.5:1 contrast in both appearances and strengthen with Increase Contrast. Typography follows system text styles. At accessibility sizes, summary metrics and Rhythm figures stack; a selected date takes its own line; session starts move above their markers and focus time. Axis text caps at xxLarge to preserve chart width; the selected date and figures above the chart provide the detail at larger sizes. The range button keeps the system bar-item size.

VoiceOver reads each slot's date, focus, breaks, and blocks, and each session's start, completed rounds, and focus time. Each slot's accessibility frame covers exactly its own column and activates that selection.

The system may log `Called -[UIContextMenuInteraction updateVisibleMenuWithBlock:] while no context menu is visible.` for the range menu. Treat it as diagnostic context; reopen it as a product issue if interaction breaks, state becomes inconsistent, or the app crashes.

## Settings and shared design

Session Rhythm is the main card. Alerts, Display, and Other use quieter cards from the same material family. Page-specific styling stays within Settings.

| Rhythm setting | Supported values |
| --- | --- |
| Focus | 15–90 minutes, in five-minute steps |
| Short Break | 5 or 10 minutes |
| Long Break | 15, 20, or 30 minutes |
| Rounds | 1–10 |

I use one inline wheel for all four rhythm settings so choosing rounds works the same way as choosing minutes. The drawer opens from its row's lower edge and closes in place. The card, rows below it, and chevron move together. Opening one row closes the other, and the wheel must never draw over a neighboring row.

Keep Next session only in the card heading. Preserve the active session's durations and rounds. On appearance, the store normalizes legacy values to the nearest supported choice without feedback.

Alerts contains Notifications, Sound, and Haptics. Sound controls both in-app event sounds and notification sound. It remains adjustable with Notifications off, when its subtitle reads Only while the app is open. If the app switch is on but iOS denies permission, show Off in iOS Settings and replace that switch with Open Settings. Event-to-sound mappings are fixed; there is no per-event sound picker.

Display contains Appearance and Keep Screen On. The appearance menu orders Follow System / Light / Dark, uses system checkmarks, saves its choice, and applies immediately. It opens from a glass value pill like the rhythm rows, and closes back into that pill without leaving a highlight on the row. Keep Screen On says Active sessions only and prevents automatic locking only while running. Pause restores normal system behavior.

Other contains Send Feedback and Share App, both marked Soon, and Clear Productivity History. Keep the history action visible. Disable it with No history yet when empty, using secondary text for both title and icon. Otherwise use destructive title styling, an ordinary secondary subtitle, and open the final confirmation alert directly. Confirmation removes `completedSessions` and `productivityCache`, preserving the active session and settings.

At accessibility sizes, labels and values stack and stay leading-aligned. Section labels and badges grow with the text. Card text must reach 4.5:1 contrast in both appearances, with stronger text and dividers under Increase Contrast.

### Material and app icon

Light mode uses warm white, mist gray, and pale gold. Both waves must remain visible, and the countdown needs contrast even where the glass catches light. The central action icon uses solid dark gray. Dark mode uses smoky gray and charcoal, with broad liquid highlights, warm amber, and warm-white supporting controls.

Content cards use regular material. In light mode a white lift, one-pixel rim, and soft shadow make them read as panels. Dark mode keeps them deep warm gray so glass controls remain distinct. Their material should retain its hierarchy when system Liquid Glass tuning or iOS 27 Appearance settings change.

SF Symbols are usually single-color. Accents mark phases, selected items, and meaningful states. External assets stay limited to the icon's vector source, restrained visual details, and bundled sounds. A photo library and imported sound collection are outside the MVP.

The icon uses the same vessel outlines as Focus, sized by default phase duration. Amber Focus is largest and sits low on the left; jade Long Break floats higher on the right; mist Short Break is smallest and highest. I separated them because the nested version read as a target or an eye, while a composition around the upright Focus shape looked like an egg. Separate shapes rising at different heights read more clearly as bubbles.

Each vessel is about 60% full. Liquid below the waterline deepens toward the bottom, while the glass above remains nearly clear. Waterlines preserve recognition without color. `AppIcon.icon` is the Icon Composer source, letting the system render default, dark, tinted, and clear appearances. In tinted and clear modes, the vessels become equally bright white and the liquid remains brighter than the empty glass.

## Implementation and verification

One `PomodoroStore` is created by the app process. `SessionSnapshot` owns active-session data, `CompletedSession` owns archived records, and `ProductivityAggregateCache` derives statistics from those records. The engine owns deterministic transitions; the store owns runtime coordination, lifecycle recovery, persistence, and reminder side effects. Screens render state and send actions.

UserDefaults currently stores settings, the active session, completed sessions, and the cache under separate write scopes. A settings adjustment writes only the affected scope. Productivity shares one statistics snapshot within a page render and reads cached aggregates. Long-history performance remains a measurement task.

The liquid is a Metal layer effect in `FocusBubbleLiquid.metal`, applied to the countdown's layer so it can refract the figures. Builds require Xcode's Metal Toolchain. The visible running surface has a 12 Hz budget; countdown figures refresh once per second. Those schedules present time rather than own it.

| Area | Acceptance and verification focus |
| --- | --- |
| Timing | Exclude pauses; reconcile multiple background boundaries; restore without duplicate archives. |
| Controls | Skip preserves elapsed time without false rounds; Reset and Back roll back time; early completion archives only what happened. |
| Statistics | Split midnight segments, preserve range totals, handle large durations, clear history, and restart cleanly. |
| Interface | Inspect all pages and phases in both appearances, immersion, inline wheels, menus, slot selection, completion, and Done. |
| Accessibility | Check larger text, leading alignment, VoiceOver slot targeting, Increase Contrast, and Reduce Motion. |
| Physical device | Measure sustained rendering, heat, and energy on iPhone 14 Pro; verify lock-screen notifications, sounds, and haptics. |

The repository has unit tests and UI smoke tests. The screenshots show visible states on the simulator. Sustained energy use and physical feedback still need device testing. Build and test commands are in the README.

### Unfinished work

I still need to measure sustained rendering, heat, and energy use on iPhone 14 Pro, along with aggregation and persistence under long histories. Larger text, VoiceOver, Reduce Motion, and recovery edge cases also need continued checks.

I want those behaviors settled before migrating completed history to SwiftData. That migration must preserve elapsed-time accounting, deduplication, and history clearing. Any later iCloud work is limited to completed sessions and selected settings. An interface built around animated numerals remains an exploration across all three pages; the vessels stay in use until I choose another direction.
