//
//  Protocols.swift
//  Chinendar
//
//  Created by Leo Liu on 1/21/24.
//

import WidgetKit
import AppIntents
import SwiftData

protocol ChinendarAppIntentTimelineProvider: AppIntentTimelineProvider where Entry: ChinendarEntry {
    func nextEntryDates(chineseCalendar: ChineseCalendar, config: Entry.Intent, context: Context) -> [Date]
    func compactCalendar(context: Context) -> Bool
}

extension ChinendarAppIntentTimelineProvider {
    func placeholder(in context: Context) -> Entry {
        let watchLayout = WatchLayout.defaultLayout
        let config = CalendarConfigure()

        let chineseCalendar = ChineseCalendar(timezone: config.effectiveTimezone, location: config.customLocation, compact: compactCalendar(context: context), globalMonth: config.globalMonth, apparentTime: config.apparentTime, largeHour: config.largeHour)
        return Entry(configuration: Entry.Intent(), chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func snapshot(for configuration: Entry.Intent, in context: Context) async -> Entry {
        let asyncModel = await AsyncLocalModels(compact: compactCalendar(context: context), config: configuration.calendarConfig?.config, theme: configuration.calendarTheme?.theme)
        let entry = Entry(configuration: configuration, chineseCalendar: asyncModel.chineseCalendar, watchLayout: asyncModel.layout)
        return entry
    }

    func timeline(for configuration: Entry.Intent, in context: Context) async -> Timeline<Entry> {
        let asyncModel = await AsyncLocalModels(compact: compactCalendar(context: context), config: configuration.calendarConfig?.config, theme: configuration.calendarTheme?.theme)
        let entryDates = nextEntryDates(chineseCalendar: asyncModel.chineseCalendar, config: configuration, context: context)
        let entries: [Entry] = await generateEntries(baseChineseCalendar: asyncModel.chineseCalendar, timeline: entryDates, watchLayout: asyncModel.layout, configuration: configuration)
        return Timeline(entries: entries, policy: .atEnd)
    }

    func compactCalendar(context: Context) -> Bool {
#if os(watchOS)
        return true
#else
        return Set<WidgetFamily>([.systemSmall, .systemMedium]).contains(context.family)
#endif
    }
}

protocol ChinendarCountDownConfigIntent: ChinendarWidgetConfigIntent {
    var target: NextEventType { get set }
}

protocol ChinendarCountDownProvider: ChinendarAppIntentTimelineProvider where Entry.Intent: ChinendarCountDownConfigIntent {
    func recommendations() -> [AppIntentRecommendation<Entry.Intent>]
    func relevance() async -> WidgetRelevance<Entry.Intent>
}

extension ChinendarCountDownProvider {
    func recommendations() -> [AppIntentRecommendation<Entry.Intent>] {
        let solarTerms = { var intent = Entry.Intent(); intent.target = .solarTerms; return intent }()
        let lunarPhases = { var intent = Entry.Intent(); intent.target = .lunarPhases; return intent }()
        let chineseHoliday = { var intent = Entry.Intent(); intent.target = .chineseHoliday; return intent }()
        let sunriseSet = { var intent = Entry.Intent(); intent.target = .sunriseSet; return intent }()
        let moonriseSet = { var intent = Entry.Intent(); intent.target = .moonriseSet; return intent }()

        return [
            AppIntentRecommendation(intent: solarTerms, description: "ET_ST"),
            AppIntentRecommendation(intent: lunarPhases, description: "ET_MP"),
            AppIntentRecommendation(intent: chineseHoliday, description: "ET_HOLIDAY"),
            AppIntentRecommendation(intent: sunriseSet, description: "SUNRISE_SET"),
            AppIntentRecommendation(intent: moonriseSet, description: "MOONRISE_SET")
        ]
    }

    func relevance() async -> WidgetRelevance<Entry.Intent> {
        let asyncModels = await AsyncLocalModels()

        async let sunTimes = nextSunTimes(chineseCalendar: asyncModels.chineseCalendar)
        async let moonTimes = nextMoonTimes(chineseCalendar: asyncModels.chineseCalendar)
        async let solarTerms = nextSolarTerm(chineseCalendar: asyncModels.chineseCalendar)
        async let moonPhases = nextMoonPhase(chineseCalendar: asyncModels.chineseCalendar)
        async let chineseHolidays = nextChineseHoliday(chineseCalendar: asyncModels.chineseCalendar)

        var relevantIntents = [WidgetRelevanceAttribute<Entry.Intent>]()

        for date in await sunTimes {
            var config = Entry.Intent()
            config.target = .sunriseSet
            let relevantContext = RelevantContext.date(range: (date - 3600)...(date + 900), kind: .informational)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in await moonTimes {
            var config = Entry.Intent()
            config.target = .moonriseSet
            let relevantContext = RelevantContext.date(range: (date - 3600)...(date + 900), kind: .informational)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in await solarTerms {
            var config = Entry.Intent()
            config.target = .solarTerms
            var solarTermDate = asyncModels.chineseCalendar
            solarTermDate.update(time: date)
            let relevantContext = RelevantContext.date(range: solarTermDate.startOfDay...solarTermDate.startOfNextDay, kind: .informational)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in await moonPhases {
            var config = Entry.Intent()
            config.target = .lunarPhases
            var lunarPhaseDate = asyncModels.chineseCalendar
            lunarPhaseDate.update(time: date)
            let relevantContext = RelevantContext.date(range: lunarPhaseDate.startOfDay...lunarPhaseDate.startOfNextDay, kind: .informational)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in await chineseHolidays {
            var config = Entry.Intent()
            config.target = .chineseHoliday
            var holidayDate = asyncModels.chineseCalendar
            holidayDate.update(time: date)
            let relevantContext = RelevantContext.date(range: holidayDate.startOfDay...holidayDate.startOfNextDay, kind: .informational)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        return WidgetRelevance(relevantIntents)
    }
}

func astronomyKind(target: NextEventType, previousDate: ChineseCalendar.NamedDate?,
                                 nextDate: ChineseCalendar.NamedDate?, chineseCalendar: ChineseCalendar) -> String? {
    switch target {
    case .sunriseSet:
        if let nextDate, previousDate != nil {
            return nextDate.name
        }
        guard chineseCalendar.location != nil else { return ChineseCalendar.dayTimeName.unknown }
        var chineseCalendar = chineseCalendar
        return chineseCalendar.getSunTimes(for: .current).noon != nil ? ChineseCalendar.dayTimeName.polarDay : ChineseCalendar.dayTimeName.polarNight
    case .moonriseSet:
        if let nextDate, previousDate != nil {
            return nextDate.name
        }
        guard chineseCalendar.location != nil else { return ChineseCalendar.moonTimeName.unknown }
        var chineseCalendar = chineseCalendar
        return chineseCalendar.getMoonTimes(for: .current).highMoon != nil ? ChineseCalendar.moonTimeName.evermoon : ChineseCalendar.moonTimeName.moonless
    default:
        return nil
    }
}

func nextMoonTimes(chineseCalendar: ChineseCalendar) -> [Date] {
    var chineseCalendar = chineseCalendar
    let current = chineseCalendar.getMoonTimes(for: .current)
    let next = chineseCalendar.getMoonTimes(for: .next)
    let allTimes = [current.moonrise, current.moonset, next.moonrise, next.moonset]
    let nextTimes = allTimes.compactMap { (time: ChineseCalendar.NamedDate?) -> Date? in
        guard let time = time, time.date > chineseCalendar.time else { return nil }
        return time.date
    }
    return nextTimes
}

func nextSunTimes(chineseCalendar: ChineseCalendar) -> [Date] {
    var chineseCalendar = chineseCalendar
    let current = chineseCalendar.getSunTimes(for: .current)
    let next = chineseCalendar.getSunTimes(for: .next)
    let allTimes = [current.sunrise, current.sunset, next.sunrise, next.sunset]
    let nextTimes = allTimes.compactMap { (time: ChineseCalendar.NamedDate?) -> Date? in
        guard let time = time, time.date > chineseCalendar.time else { return nil }
        return time.date
    }
    return nextTimes
}

func nextSolarTerm(chineseCalendar: ChineseCalendar) -> [Date] {
    let nextSolarTerm = chineseCalendar.solarTerms.first {
        $0.date > chineseCalendar.time
    }
    if let next = nextSolarTerm?.date {
        return [next]
    } else {
        return []
    }
}

func nextMoonPhase(chineseCalendar: ChineseCalendar) -> [Date] {
    let nextLunarPhase = chineseCalendar.moonPhases.first {
        $0.date > chineseCalendar.time
    }
    if let next = nextLunarPhase?.date {
        return [next]
    } else {
        return []
    }
}

func nextChineseHoliday(chineseCalendar: ChineseCalendar) -> [Date] {
    let nextHoliday = chineseCalendar.lunarHolidays.first {
        $0.date > chineseCalendar.time
    }
    if let next = nextHoliday?.date {
        return [next]
    } else {
        var nextYearCalendar = chineseCalendar
        nextYearCalendar.update(time: chineseCalendar.solarTerms[24].date + 180 * 86400)
        return [nextYearCalendar.lunarHolidays.first].compactMap { $0?.date }
    }
}
