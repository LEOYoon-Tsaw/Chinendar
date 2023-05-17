//
//  WatchWidget.swift
//  WatchWidget
//
//  Created by Leo Liu on 5/10/23.
//

import Intents
import SwiftUI
import WidgetKit

struct LineProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> LineEntry {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        return LineEntry(date: Date(), configuration: SingleLineIntent(), chinsesCalendar: chineseCalendar)
    }

    func getSnapshot(for configuration: SingleLineIntent, in context: Context, completion: @escaping (LineEntry) -> ()) {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        let entry = LineEntry(date: Date(), configuration: configuration, chinsesCalendar: chineseCalendar)
        completion(entry)
    }

    func getTimeline(for configuration: SingleLineIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [LineEntry] = []
        DataContainer.shared.loadSave()
        LocationManager.shared.requestLocation(completion: nil)

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let chineseCalendar = ChineseCalendar(time: currentDate, timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        for hourOffset in 0 ..< 12 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            chineseCalendar.update(time: entryDate, timezone: chineseCalendar.calendar.timeZone, location: chineseCalendar.location)
            let entry = LineEntry(date: entryDate, configuration: configuration, chinsesCalendar: chineseCalendar.copy)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func recommendations() -> [IntentRecommendation<SingleLineIntent>] {
        return [
            IntentRecommendation(intent: SingleLineIntent(), description: "Single Line Widget")
        ]
    }
}

struct LineEntry: TimelineEntry {
    let date: Date
    let configuration: SingleLineIntent
    let chinsesCalendar: ChineseCalendar
}

struct LineEntryView: View {
    var entry: LineProvider.Entry

    var body: some View {
        LineDescription(chineseCalendar: entry.chinsesCalendar)
    }
}

struct LineWidget: Widget {
    let kind: String = "LineWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SingleLineIntent.self, provider: LineProvider()) { entry in
            LineEntryView(entry: entry)
        }
        .configurationDisplayName("Single Line")
        .description("Single line date and time widget.")
        .supportedFamilies([.accessoryInline])
    }
}

struct CircularProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> CircularEntry {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        return CircularEntry(date: Date(), configuration: CircularIntent(), chinsesCalendar: chineseCalendar)
    }

    func getSnapshot(for configuration: CircularIntent, in context: Context, completion: @escaping (CircularEntry) -> ()) {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        let entry = CircularEntry(date: Date(), configuration: configuration, chinsesCalendar: chineseCalendar)
        completion(entry)
    }

    func getTimeline(for configuration: CircularIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [CircularEntry] = []
        DataContainer.shared.loadSave()
        LocationManager.shared.requestLocation(completion: nil)

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let chineseCalendar = ChineseCalendar(time: currentDate, timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        for hourOffset in 0 ..< 12 {
            let entryDate: Date
            switch configuration.mode {
            case .monthDay:
                entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            default:
                entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset * 6, to: currentDate)!
            }
            chineseCalendar.update(time: entryDate, timezone: chineseCalendar.calendar.timeZone, location: chineseCalendar.location)
            let entry = CircularEntry(date: entryDate, configuration: configuration, chinsesCalendar: chineseCalendar.copy)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func recommendations() -> [IntentRecommendation<CircularIntent>] {
        let daylight = CircularIntent()
        daylight.mode = .daylight
        let monthDay = CircularIntent()
        monthDay.mode = .monthDay
        return [
            IntentRecommendation(intent: daylight, description: "日月光華"),
            IntentRecommendation(intent: monthDay, description: "歲月之輪")
        ]
    }
}

struct CircularEntry: TimelineEntry {
    let date: Date
    let configuration: CircularIntent
    let chinsesCalendar: ChineseCalendar
}

struct CircularEntryView: View {
    var entry: CircularProvider.Entry

    func sunTimes(times: [ChineseCalendar.NamedPosition?]) -> (start: CGFloat, end: CGFloat)? {
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

    func moonTimes(times: [ChineseCalendar.NamedPosition?]) -> ((start: CGFloat, end: CGFloat)?, CGFloat?) {
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

    var body: some View {
        let layout = WatchLayout.shared
        let phase = StartingPhase()
        switch entry.configuration.mode {
        case .monthDay:
            let outerGradient = applyGradient(gradient: layout.firstRing, startingAngle: phase.firstRing)
            let innerGradient = applyGradient(gradient: layout.secondRing, startingAngle: phase.secondRing)
            Circular(outer: (start: phase.firstRing, end: entry.chinsesCalendar.currentDayInYear + phase.firstRing),
                     inner: (start: phase.secondRing, end: entry.chinsesCalendar.currentDayInMonth + phase.secondRing),
                     outerGradient: outerGradient, innerGradient: innerGradient)
                .widgetLabel {
                    Text(String(entry.chinsesCalendar.dateString.reversed()))
                }
        default:
            let outerGradient = applyGradient(gradient: layout.thirdRing, startingAngle: phase.thirdRing)
            let innerGradient = applyGradient(gradient: layout.secondRing, startingAngle: phase.secondRing)
            let (inner, innerDirection) = moonTimes(times: entry.chinsesCalendar.sunMoonPositions.lunar)
            if let outer = sunTimes(times: entry.chinsesCalendar.sunMoonPositions.solar), let inner = inner {
                Circular(outer: (start: outer.start + phase.thirdRing, end: outer.end + phase.thirdRing),
                         inner: (start: inner.start + phase.secondRing, end: inner.end + phase.secondRing),
                         current: entry.chinsesCalendar.currentHourInDay,
                         innerDirection: innerDirection,
                         outerGradient: outerGradient, innerGradient: innerGradient,
                         currentColor: Color(cgColor: layout.thirdRing.interpolate(at: entry.chinsesCalendar.currentHourInDay)))
                    .widgetLabel {
                        Text(String((entry.chinsesCalendar.hourString + entry.chinsesCalendar.shortQuarterString).reversed()))
                    }
            } else {
                Circular(outer: (start: 0, end: 1e-7), inner: (start: 0, end: 1e-7),
                         current: entry.chinsesCalendar.currentHourInDay, outerGradient: outerGradient, innerGradient: innerGradient,
                         currentColor: Color(cgColor: layout.thirdRing.interpolate(at: entry.chinsesCalendar.currentHourInDay)))
                    .widgetLabel {
                        Text(String((entry.chinsesCalendar.hourString + entry.chinsesCalendar.shortQuarterString).reversed()))
                    }
            }
        }
    }
}

struct CircularWidget: Widget {
    let kind: String = "Circular"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: CircularIntent.self, provider: CircularProvider()) { entry in
            CircularEntryView(entry: entry)
        }
        .configurationDisplayName("Circular")
        .description("Circular View.")
#if os(watchOS)
            .supportedFamilies([.accessoryCircular, .accessoryCorner])
#else
        .supportedFamilies([.accessoryCircular])
#endif
    }
}
