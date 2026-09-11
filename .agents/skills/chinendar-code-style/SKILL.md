---
name: chinendar-code-style
description: Apply Chinendar conventions when editing Swift app, widget, calendar, persistence, or test code, especially observation, concurrency, localization, and encoded-data compatibility.
---

# Chinendar Code Style

Follow nearby code and `.swiftlint.yml` for formatting. The conventions below are defaults for Chinendar, not reasons to expand a task into a rewrite or block an explicit user request. Paths are relative to the repository root.

## State and concurrency

- App view models use `@Observable final class` and conform to the `@MainActor` `ViewModelType` protocol. Put shared behavior in that protocol's extensions and platform behavior in the concrete view model. Inject state through `.environment(viewModel)` and SwiftData through `.modelContainer(...)`.
- Preserve the lifetime of `ObservationTracking.Token` values stored in `observationTokens` when changing `withContinuousObservation` setup. Use `@ObservationIgnored` for dependencies that should not invalidate views.
- Continue the existing async/await, actor, and async-stream approach; avoid adding Combine as a parallel state mechanism. Services such as `NotificationManager`, `LocationManager`, and `WatchConnectivityManager` have their own isolation boundaries.
- Choose task scope from ownership, actor isolation, and cancellation needs. Existing `Task.detached` calls are examples to inspect, not a default for new work. Keep observable UI mutations on the main actor and preserve cancellation of long-lived refresh/sync tasks.
- Widget entry generation copies `ChineseCalendar` for independent task-group work and sorts results by date afterward. Preserve chronological output when changing that path; task completion order is not timeline order.
- Check current project/compiler settings before relying on a language feature. Address isolation or transfer diagnostics at the owning boundary rather than weakening concurrency checking just to make a change compile.

## Models and persistence

- Layout/config models use `Codable`, commonly with `Equatable` and `Sendable` through existing protocols. Add conformances to fit actual consumers rather than making every shared type codable.
- Preserve JSON keys and decoding behavior for layouts, calendar configuration, watch settings, and reminders. Existing decoders often use `decodeIfPresent` to retain defaults for missing fields. Check old payloads and platform `layout.json` defaults when adding or changing encoded fields.
- SwiftData schema evolution belongs in the versioned schemas and migration plans in `Shared/DataModel/DataModel.swift`. Distinguish changes to the SwiftData schema from changes inside an encoded payload; assess migration and decoding compatibility at the layer that changed.
- Phone/watch layout synchronization preserves the watch's own offsets. Maintain that behavior when updating layout models or sync code.

## UI

- Match the existing compact, functional SwiftUI style and platform conventions, unless the requested design calls for a change. Shared drawing lives in `Shared/Views/`; widget implementations live in `Widget/`; platform bundles select the widgets to expose.
- Check target membership and API availability when shared code touches AppKit, UIKit, WatchKit, or other platform APIs. An OS guard does not make an app-only API valid in a widget extension.
- Use SF Symbols with `Label`/`systemImage` where appropriate.

## Localization

Use `Shared/Localizable.xcstrings` and `Shared/InfoPlist.xcstrings`, with `zh-Hant` as the source language. Follow nearby `String(localized:)`, `LocalizedStringResource`, or localized SwiftUI text patterns. Preserve keys, placeholder meaning/types, and plural variations while adapting word order and punctuation to each locale.

Keep UI labels compact and explanations conversational. Chinese copy uses a concise, often literary register and traditional calendar/astronomical vocabulary; retain that character in both scripts. In other languages, use established local terms and natural phrasing. Match nearby capitalization and formality without forcing Chinese brevity or syntax onto another language.

Reuse terminology from related catalog entries and `Shared/Locale.swift` across settings, widgets, shortcuts, and help. Preserve distinctions between calendar systems, astronomical instants and civil dates, and traditional time units; explain unfamiliar concepts in help text. Changes to domain strings in `ChineseCalendar` can affect behavior: check translation mappings and affected tests.

The fixed product/calendar name is **Chinendar** (`en`), **華曆** (`zh-Hant`), **华历** (`zh-Hans`), **華暦** (`ja`), **화력** (`ko`), and **Hoa lịch** (`vi`). Keep these forms consistent in UI and bundle names. Distinguish the brand from explanatory references to the underlying calendar system.

## Calendar behavior and tests

`ChineseCalendar` is a mutable value type initialized with time, timezone, location, and calculation options. Its supported interval is defined by `ChineseCalendar.start` and `.end`. `globalMonth`, `apparentTime`, `largeHour`, and `compact` affect calculation behavior; preserve the options relevant to the consumer.

Use Swift Testing (`@Test`, `#expect`) following `Chinendar-Tests/Chinendar_Tests.swift`. For calendar logic changes, cover the changed behavior with fixed dates, explicit `TimeZone` and `GeoLocation`, and explicit relevant options. Choose boundary cases from the change, such as month/year transitions, leap months, or local day boundaries; avoid dependence on the current clock or machine timezone.

For persistence or synchronization changes, validate the relevant decoding or round-trip behavior, including missing fields when compatibility is affected. For UI changes, build the affected scheme and use previews or runtime checks when appearance or interaction needs verification. Select further builds from actual shared-source consumers; the calendar test target does not validate app/widget UI. No Swift build is needed for skill prose alone.

## Editing project files

Use available project-aware tools or direct file edits according to the operation. Direct inspection of `Chinendar.xcodeproj/project.pbxproj`, Info.plist, and entitlements is valid; keep edits focused and verify the resulting project structure/settings. Check whether a plist value is generated by build settings before editing it. For file additions or moves, account for explicit target membership and synchronized-group exceptions. Keep unrelated formatting changes out of large shared files.
