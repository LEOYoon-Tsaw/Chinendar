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

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "圓輪掛件選項")
    static let caseDisplayRepresentations: [CircularMode: DisplayRepresentation] = [
        .daylight: .init(title: "日月光華"),
        .monthDay: .init(title: "歲月之輪")
    ]
}

struct CircularConfiguration: ChinendarWidgetConfigIntent {
    static let title: LocalizedStringResource = "圓輪"
    static let description = IntentDescription("簡化之輪以展現日時")

    @Parameter(title: "選日曆")
    var calendarConfig: ConfigIntent?

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

    func relevances() async -> WidgetRelevance<Intent> {
        let asyncModels = await AsyncModels()

        var relevantIntents = [WidgetRelevanceAttribute<Entry.Intent>]()

        for date in asyncModels.chineseCalendar.nextHours(count: 6) {
            let config = Intent()
            config.mode = .daylight
            let relevantContext = RelevantContext.date(from: date - 900, to: date + 600)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in [asyncModels.chineseCalendar.startOfNextDay] {
            let config = Intent()
            config.mode = .monthDay
            let relevantContext = RelevantContext.date(from: date - 3600, to: date + 900)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        return WidgetRelevance(relevantIntents)
    }
}

private func sunTimes(times: Solar<ChineseCalendar.NamedPosition?>) -> (start: Double, end: Double)? {
    if let sunrise = times.sunrise?.pos {
        if let sunset = times.sunset?.pos {
            return (start: sunrise, end: sunset)
        } else {
            return (start: sunrise, end: 1)
        }
    } else {
        if let sunset = times.sunset?.pos {
            return (start: 0, end: sunset)
        } else {
            if times.noon != nil {
                return (start: 0, end: 1)
            } else {
                return (start: 0, end: 1e-7)
            }
        }
    }
}

private func moonTimes(times: Lunar<ChineseCalendar.NamedPosition?>) -> ((start: Double, end: Double)?, Double?) {
    if let moonrise = times.moonrise?.pos {
        if let moonset = times.moonset?.pos {
            return ((start: moonrise, end: moonset), times.highMoon?.pos)
        } else {
            return ((start: moonrise, end: 1), times.highMoon?.pos ?? 1)
        }
    } else {
        if let moonset = times.moonset?.pos {
            return ((start: 0, end: moonset), times.highMoon?.pos ?? 0)
        } else {
            if times.highMoon != nil {
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
    let phase: (CGFloat, CGFloat)

    init(configuration: CircularProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        let baseLayout = watchLayout.baseLayout
        date = chineseCalendar.time
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        let phase = baseLayout.startingPhase
        var chineseCalendar = chineseCalendar

        switch configuration.mode {
        case .monthDay:
            outer = (start: 0, end: chineseCalendar.currentDayInYear)
            inner = (start: 0, end: chineseCalendar.currentDayInMonth)
            outerGradient = baseLayout.firstRing.apply(startingAngle: 0)
            innerGradient = baseLayout.secondRing.apply(startingAngle: 0)
            current = nil
            innerDirection = nil
            currentColor = nil
            self.phase = (phase.firstRing, phase.secondRing)

        case .daylight:
            let (inner, innerDirection) = moonTimes(times: chineseCalendar.sunMoonPositions.lunar)
            let outer = sunTimes(times: chineseCalendar.sunMoonPositions.solar)
            self.inner = inner.map { (start: CGFloat($0.start), end: CGFloat($0.end)) } ?? (start: 0, end: 1e-7)
            self.innerDirection = innerDirection.map { CGFloat($0) }
            self.outer = outer.map { (start: CGFloat($0.start), end: CGFloat($0.end)) } ?? (start: 0, end: 1e-7)
            outerGradient = baseLayout.thirdRing.apply(startingAngle: 0)
            innerGradient = baseLayout.secondRing.apply(startingAngle: 0)
            current = chineseCalendar.currentHourInDay
            currentColor = Color(cgColor: baseLayout.thirdRing.interpolate(at: chineseCalendar.currentHourInDay))
            self.phase = (phase.thirdRing, phase.thirdRing)
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
