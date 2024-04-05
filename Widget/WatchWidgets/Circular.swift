//
//  Circular.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

enum CircularMode: String, AppEnum {
    case daylight, monthDay

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "圓輪掛件選項")
    static let caseDisplayRepresentations: [CircularMode : DisplayRepresentation] = [
        .daylight: .init(title: "日月光華"),
        .monthDay: .init(title: "歲月之輪"),
    ]
}

struct CircularConfiguration: ChinendarWidgetConfigIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "CircularIntent"
    static let title: LocalizedStringResource = "圓輪"
    static let description = IntentDescription("簡化之輪以展現日時")

    @Parameter(title: "選日曆")
    var calendarConfig: ConfigIntent
    
    @Parameter(title: "型制", default: .daylight)
    var mode: CircularMode
    
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$calendarConfig
            \.$mode
        }
    }
}

struct CircularProvider: ChinendarAppIntentTimelineProvider {
    typealias Entry = CircularEntry
    typealias Intent = CircularConfiguration
    let modelContext = DataSchema.context
    let locationManager = LocationManager()
    
    func nextEntryDates(chineseCalendar: ChineseCalendar, config: CircularConfiguration, context: Context) -> [Date] {
        return switch config.mode {
        case .monthDay:
            chineseCalendar.nextHours(count: 12)
        case .daylight:
            chineseCalendar.nextQuarters(count: 15)
        }
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

struct CircularEntry: TimelineEntry, ChinendarEntry {
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
    let phase: (CGFloat, CGFloat)
    
    init(configuration: CircularProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        date = chineseCalendar.time
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        let phase = watchLayout.startingPhase
        
        switch configuration.mode {
        case .monthDay:
            outer = (start: 0, end: chineseCalendar.currentDayInYear)
            inner = (start: 0, end: chineseCalendar.currentDayInMonth)
            outerGradient = applyGradient(gradient: watchLayout.firstRing, startingAngle: 0)
            innerGradient = applyGradient(gradient: watchLayout.secondRing, startingAngle: 0)
            current = nil
            innerDirection = nil
            currentColor = nil
            self.phase = (phase.firstRing, phase.secondRing)
            relevance = TimelineEntryRelevance(score: 5, duration: 3600)
            
        case .daylight:
            let (inner, innerDirection) = moonTimes(times: chineseCalendar.sunMoonPositions.lunar)
            let outer = sunTimes(times: chineseCalendar.sunMoonPositions.solar)
            self.inner = inner ?? (start: 0, end: 1e-7)
            self.innerDirection = innerDirection
            self.outer = outer ?? (start: 0, end: 1e-7)
            outerGradient = applyGradient(gradient: watchLayout.thirdRing, startingAngle: 0)
            innerGradient = applyGradient(gradient: watchLayout.secondRing, startingAngle: 0)
            current = chineseCalendar.currentHourInDay
            currentColor = Color(cgColor: watchLayout.thirdRing.interpolate(at: chineseCalendar.currentHourInDay))
            self.phase = (phase.thirdRing, phase.thirdRing)
            relevance = TimelineEntryRelevance(score: 5, duration: 864)
        }
    }
}

struct CircularEntryView: View {
    var entry: CircularProvider.Entry

    var body: some View {
        switch entry.configuration.mode {
        case .monthDay:
            Circular(outer: entry.outer, inner: entry.inner, startingPhase: entry.phase, outerGradient: entry.outerGradient, innerGradient: entry.innerGradient)
                .containerBackground(Color.clear, for: .widget)
                .widgetLabel {
                    Text(String(entry.chineseCalendar.dateString.reversed()))
                }
        case .daylight:
            Circular(outer: entry.outer, inner: entry.inner, current: entry.current, startingPhase: entry.phase, innerDirection: entry.innerDirection, outerGradient: entry.outerGradient, innerGradient: entry.innerGradient, currentColor: entry.currentColor)
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
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.mode = .daylight
    return intent
}()) {
    CircularWidget()
} timelineProvider: {
    CircularProvider()
}

#Preview("Circular Monthday", as: .accessoryCircular, using: {
    let intent = CircularProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.mode = .monthDay
    return intent
}()) {
    CircularWidget()
} timelineProvider: {
    CircularProvider()
}
