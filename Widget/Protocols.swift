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
        var watchLayout = WatchLayout(baseLayout: BaseLayout())
        let config = CalendarConfigure()
        let defaultLayout = ThemeData.staticLayoutCode
        watchLayout.update(from: defaultLayout)

        let chineseCalendar = ChineseCalendar(timezone: config.effectiveTimezone, location: config.customLocation, compact: compactCalendar(context: context), globalMonth: config.globalMonth, apparentTime: config.apparentTime, largeHour: config.largeHour)
        return Entry(configuration: Entry.Intent(), chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func snapshot(for configuration: Entry.Intent, in context: Context) async -> Entry {
        let asyncModel = await AsyncModels(compact: compactCalendar(context: context))
        let entry = Entry(configuration: configuration, chineseCalendar: asyncModel.chineseCalendar, watchLayout: asyncModel.layout)
        return entry
    }

    func timeline(for configuration: Entry.Intent, in context: Context) async -> Timeline<Entry> {
        let asyncModel = await AsyncModels(compact: compactCalendar(context: context))
        let entryDates = nextEntryDates(chineseCalendar: asyncModel.chineseCalendar, config: configuration, context: context)
        let entries: [Entry] = await generateEntries(baseChineseCalendar: asyncModel.chineseCalendar, timeline: entryDates, watchLayout: asyncModel.layout, calendarConfig: asyncModel.config, configuration: configuration)
        return Timeline(entries: entries, policy: .atEnd)
    }

    func compactCalendar(context: Context) -> Bool {
        return true
    }
}
