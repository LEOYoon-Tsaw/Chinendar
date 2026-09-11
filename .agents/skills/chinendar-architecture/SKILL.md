---
name: chinendar-architecture
description: Map Chinendar features to source files and Xcode targets when locating code, tracing data flow, or planning structural and cross-platform changes.
---

# Chinendar Architecture

Use this map to find the relevant implementation, then check current source and target membership before changing it. All paths below are relative to the repository root containing `Chinendar.xcodeproj`; there is no additional `Chinendar/` directory on disk.

## Targets and source membership

| App scheme | Entry point | Widget scheme | Widget bundle folder |
| --- | --- | --- | --- |
| `Chinendar Mac` | `macOS/macApp.swift` | `Mac Widget Extension` | `MacWidget/` |
| `Chinendar iOS` | `iOS/iOSApp.swift` | `iOS Widget Extension` | `iOSWidget/` |
| `Chinendar Watch` | `Watch/watchApp.swift` | `Watch Widget Extension` | `WatchWidget/` |
| `Chinendar Vision` | `Vision/visionApp.swift` | `Vision Widget Extension` | `VisionWidget/` |

`Chinendar Tests` is the Swift Testing scheme, with tests in `Chinendar-Tests/Chinendar_Tests.swift`. It compiles calendar-related shared sources directly rather than importing an app module; it does not cover the full app or widget source set.

`Shared/` and `Widget/` contain sources compiled into multiple products, not standalone framework targets. Each app defines its own `ViewModel` in its entry file and platform layout support in `Layout.swift` and `layout.json`. Keep those same-named platform types in their intended targets.

The project mixes explicit file membership with synchronized groups (`Chinendar-Tests/` and `VisionWidget/`). Adding a file on disk does not necessarily add it to a target. For additions, moves, or platform API changes, inspect the affected source phases and synchronized-group exceptions in `Chinendar.xcodeproj/project.pbxproj` or equivalent project tools. Folder names and `#if os(...)` guards alone do not establish membership or extension safety.

Shared schemes live in `Chinendar.xcodeproj/xcshareddata/xcschemes/`. Read current build settings when Swift language mode, deployment targets, module names, or extension restrictions matter; this skill does not pin their values. `CelestialSystem` supplies astronomical calculations; its resolved version is recorded in `Chinendar.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Where to change behavior

| Concern | Starting point |
| --- | --- |
| Chinese calendar, date conversion, solar terms, moon phases, event lookup | `Shared/DataModel/Calendar.swift` (`ChineseCalendar`) |
| Layout, theme, config, reminders, shared view-model behavior | `Shared/DataModel/ViewModel.swift` (`WatchLayout`, `CalendarConfigure`, `WatchSetting`, `ViewModelType`) |
| SwiftData schemas, migration plans, persisted payload wrappers | `Shared/DataModel/DataModel.swift` (`DataSchema`, `LocalSchema`) |
| Location and reminder scheduling | `Shared/DataModel/LocationManager.swift`, `Shared/DataModel/Notification.swift` |
| Watch-face drawing shared by apps and widgets | `Shared/Views/WatchFaceView.swift` and nearby drawing helpers |
| Shared settings controls | `Shared/Setting/` |
| AppIntents, entities, shortcuts | `Shared/Siri/` |
| iPhone/watch layout and config synchronization | `Shared/WatchConnectivity.swift`, `iOS/iOSApp.swift`, `Watch/watchApp.swift` |
| Localization and locale helpers | `Shared/Localizable.xcstrings`, `Shared/InfoPlist.xcstrings`, `Shared/Locale.swift` |
| Widget entries and timeline generation | `Widget/WidgetModels.swift` and the relevant provider |
| Reusable widget views and families | `Widget/`, including `Widget/WatchWidgets/` |
| Which widgets a platform exposes | That platform's `*WidgetBundle.swift` |

Platform lifecycle and UI belong with their app: macOS status item/popover/windows in `macOS/`, iOS navigation and watch-sync observation in `iOS/`, compact watch UI in `Watch/`, visionOS windows/ornaments in `Vision/`. Follow existing consumers when deciding whether a view belongs in a platform folder, `Shared/Views/`, or `Widget/`.

## Data flow and compatibility boundaries

- Platform apps inject `ViewModel.shared` with `.environment(viewModel)` and their SwiftData container with `.modelContainer(...)`. Concrete view models load `LocalTheme` and `LocalConfig` from `LocalSchema.container`.
- The `@MainActor` `ViewModelType` protocol and extensions expose persisted layout/config and update `ChineseCalendar`. `setup()` retains continuous observation through `observationTokens`; platform refresh tasks also advance time.
- `DataSchema` holds CloudKit-capable shared data; `LocalSchema` holds local device state. Debug container configuration disables CloudKit, so a debug run alone does not validate cloud synchronization.
- Widgets construct entries from intent-selected config, `WatchLayout`, and `ChineseCalendar`. Shared model changes can therefore affect widgets and AppIntents even when initiated from an app setting.
- iOS sends `.layout` and `.config` payloads through `WatchConnectivityManager`. watchOS requests/applies them only when `syncFromPhone` is enabled. Applying a phone layout preserves the watch's `baseLayout.offsets`.

For encoded model or schema changes, trace persistence, imported/exported payloads, watch sync, and widget/intent consumers as applicable. Preserve existing decoding compatibility and the watch-specific offset behavior unless the task explicitly changes them.

## Validation scope

Choose checks from the affected source membership and behavior. Build the affected app or widget scheme; shared changes need coverage of materially different platform branches and app/extension contexts. A successful active-scheme build does not establish that every consumer compiles.

For calendar behavior, run focused tests through `Chinendar Tests`. Use an available compatible destination; inspect destinations if uncertain. Project-aware diagnostics can shorten feedback, and `xcodebuild` can build/test without switching the IDE's active scheme. Report any SDK, destination, or signing limitation and which checks remain unverified. Documentation-only edits do not require an app build.
