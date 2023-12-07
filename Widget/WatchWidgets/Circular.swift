//
//  Circular.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
import WidgetKit

enum CircularMode: String, AppEnum {
    case daylight, monthDay

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "圓輪掛件選項")
    static var caseDisplayRepresentations: [CircularMode : DisplayRepresentation] = [
        .daylight: .init(title: "日月光華"),
        .monthDay: .init(title: "歲月之輪"),
    ]
}

struct CircularConfiguration: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "CircularIntent"
    static var title: LocalizedStringResource = "圓輪"
    static var description = IntentDescription("簡化之輪以展現日時")

    @Parameter(title: "型制", default: .daylight)
    var mode: CircularMode
    
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$mode
        }
    }
}

struct CircularProvider: AppIntentTimelineProvider {
    typealias Entry = CircularEntry
    typealias Intent = CircularConfiguration
    let modelContext = ThemeData.context
    let locationManager = LocationManager.shared
    
    func placeholder(in context: Context) -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadStatic()
        let chineseCalendar = ChineseCalendar(time: .now, compact: true)
        return Entry(configuration: Intent(), chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()
        let chineseCalendar = ChineseCalendar(location: location, compact: true)
        return Entry(configuration: configuration, chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()

        let chineseCalendar = ChineseCalendar(location: location, compact: true)
        let entryDates = switch configuration.mode {
        case .monthDay:
            chineseCalendar.nextHours(count: 12)
        case .daylight:
            chineseCalendar.nextQuarters(count: 15)
        }
        var chineseCalendars = [chineseCalendar.copy]
        for entryDate in entryDates {
            chineseCalendar.update(time: entryDate, location: location)
            chineseCalendars.append(chineseCalendar.copy)
        }
        let entries: [Entry] = await generateEntries(chineseCalendars: chineseCalendars, watchLayout: watchLayout, configuration: configuration)
        return Timeline(entries: entries, policy: .atEnd)
    }

    func recommendations() -> [AppIntentRecommendation<Intent>] {
        let daylight = Intent()
        daylight.mode = .daylight
        let monthDay = Intent()
        monthDay.mode = .monthDay
        return [
            AppIntentRecommendation(intent: daylight, description: "日月光華"),
            AppIntentRecommendation(intent: monthDay, description: "歲月之輪")
        ]
    }
}

private func sunTimes(times: [ChineseCalendar.NamedPosition?]) -> (start: CGFloat, end: CGFloat)? {
    guard times.count == 5 else { return nil }
    if let sunrise = times[1]?.pos, let sunset = times[3]?.pos {
        return (start: CGFloat(sunrise), end: CGFloat(sunset))
    } else if times[1] == nil && times[3] == nil {
        if let _ = times[2]?.pos {
            return (start: 0, end: 1)
        } else {
            return (start: 0, end: 1e-7)
        }
    } else {
        if let sunrise = times[1]?.pos {
            return (start: CGFloat(sunrise), end: 1.0)
        } else if let sunset = times[3]?.pos {
            return (start: 0, end: CGFloat(sunset))
        } else {
            return (start: 0, end: 1e-7)
        }
    }
}

private func moonTimes(times: [ChineseCalendar.NamedPosition?]) -> ((start: CGFloat, end: CGFloat)?, CGFloat?) {
    guard times.count == 6 else { return (nil, nil) }
    if let firstMoonRise = times[0]?.pos {
        if let firstMoonSet = times[2]?.pos {
            return ((start: CGFloat(firstMoonRise), end: CGFloat(firstMoonSet)), times[1].flatMap { CGFloat($0.pos) })
        } else {
            return ((start: CGFloat(firstMoonRise), end: 1.0), times[1].flatMap { CGFloat($0.pos) } ?? 1.0)
        }
    } else if let secondMoonSet = times[5]?.pos {
        if let secondMoonRise = times[3]?.pos {
            return ((start: CGFloat(secondMoonRise), end: CGFloat(secondMoonSet)), times[4].flatMap { CGFloat($0.pos) })
        } else {
            return ((start: 0.0, end: CGFloat(secondMoonSet)), times[4].flatMap { CGFloat($0.pos) } ?? 0.0)
        }
    } else if let firstMoonSet = times[2]?.pos, let secondMoonRise = times[3]?.pos {
        return ((start: CGFloat(secondMoonRise), end: CGFloat(firstMoonSet)), (times[1] ?? times[4]).flatMap { CGFloat($0.pos) })
    } else {
        if let firstMoonSet = times[2]?.pos {
            return ((start: 0, end: CGFloat(firstMoonSet)), times[1].flatMap { CGFloat($0.pos) } ?? 0.0)
        } else if let secondMoonRise = times[3]?.pos {
            return ((start: CGFloat(secondMoonRise), end: 1.0), times[4].flatMap { CGFloat($0.pos) } ?? 1.0)
        } else {
            if times[1] != nil || times[4] != nil {
                return ((start: 0, end: 1), nil)
            } else {
                return ((start: 0, end: 1e-7), nil)
            }
        }
    }
}

struct CircularEntry: TimelineEntry, ChineseTimeEntry {
    let date: Date
    let configuration: CircularProvider.Intent
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout
    let inner: (CGFloat, CGFloat)
    let outer: (CGFloat, CGFloat)
    let innerGradient: Gradient
    let outerGradient: Gradient
    let current: CGFloat?
    let innerDirection: CGFloat?
    let currentColor: Color?
    let relevance: TimelineEntryRelevance?
    
    init(configuration: CircularProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        date = chineseCalendar.time
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        let phase = StartingPhase()
        
        switch configuration.mode {
        case .monthDay:
            outer = (start: phase.firstRing, end: chineseCalendar.currentDayInYear + phase.firstRing)
            inner = (start: phase.secondRing, end: chineseCalendar.currentDayInMonth + phase.secondRing)
            outerGradient = applyGradient(gradient: watchLayout.firstRing, startingAngle: phase.firstRing)
            innerGradient = applyGradient(gradient: watchLayout.secondRing, startingAngle: phase.secondRing)
            current = nil
            innerDirection = nil
            currentColor = nil
            relevance = TimelineEntryRelevance(score: 5, duration: 3600)
            
        case .daylight:
            let (inner, innerDirection) = moonTimes(times: chineseCalendar.sunMoonPositions.lunar)
            let outer = sunTimes(times: chineseCalendar.sunMoonPositions.solar)
            self.inner = inner ?? (start: 0, end: 1e-7)
            self.innerDirection = innerDirection
            self.outer = outer ?? (start: 0, end: 1e-7)
            outerGradient = applyGradient(gradient: watchLayout.thirdRing, startingAngle: phase.thirdRing)
            innerGradient = applyGradient(gradient: watchLayout.secondRing, startingAngle: phase.secondRing)
            current = chineseCalendar.currentHourInDay
            currentColor = Color(cgColor: watchLayout.thirdRing.interpolate(at: chineseCalendar.currentHourInDay))
            relevance = TimelineEntryRelevance(score: 5, duration: 864)
        }
    }
}

struct CircularEntryView: View {
    var entry: CircularProvider.Entry

    var body: some View {
        switch entry.configuration.mode {
        case .monthDay:
            Circular(outer: entry.outer, inner: entry.inner, outerGradient: entry.outerGradient, innerGradient: entry.innerGradient)
                .containerBackground(Color.clear, for: .widget)
                .widgetLabel {
                    Text(String(entry.chineseCalendar.dateString.reversed()))
                }
        case .daylight:
            Circular(outer: entry.outer, inner: entry.inner, current: entry.current, innerDirection: entry.innerDirection, outerGradient: entry.outerGradient, innerGradient: entry.innerGradient, currentColor: entry.currentColor)
                .containerBackground(Color.clear, for: .widget)
                .widgetLabel {
                    Text(String((entry.chineseCalendar.hourString + entry.chineseCalendar.shortQuarterString).reversed()))
                }
        }
    }
}

struct CircularWidget: Widget {
    static let kind: String = "Circular"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: CircularProvider.Intent.self, provider: CircularProvider()) { entry in
            CircularEntryView(entry: entry)
        }
        .containerBackgroundRemovable()
        .configurationDisplayName("圓輪")
        .description("展現日時之圓輪")
#if os(watchOS)
            .supportedFamilies([.accessoryCircular, .accessoryCorner])
#else
        .supportedFamilies([.accessoryCircular])
#endif
    }
}

#Preview("Circular Daylight", as: .accessoryCircular, using: {
    let intent = CircularProvider.Intent()
    intent.mode = .daylight
    return intent
}()) {
    CircularWidget()
} timelineProvider: {
    CircularProvider()
}

#Preview("Circular Monthday", as: .accessoryCircular, using: {
    let intent = CircularProvider.Intent()
    intent.mode = .monthDay
    return intent
}()) {
    CircularWidget()
} timelineProvider: {
    CircularProvider()
}
