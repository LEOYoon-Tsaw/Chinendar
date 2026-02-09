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
        let asyncModel = await AsyncLocalModels(compact: compactCalendar(context: context), config: configuration.calendarConfig?.config)
        let entry = Entry(configuration: configuration, chineseCalendar: asyncModel.chineseCalendar, watchLayout: asyncModel.layout)
        return entry
    }

    func timeline(for configuration: Entry.Intent, in context: Context) async -> Timeline<Entry> {
        let asyncModel = await AsyncLocalModels(compact: compactCalendar(context: context), config: configuration.calendarConfig?.config)
        let entryDates = nextEntryDates(chineseCalendar: asyncModel.chineseCalendar, config: configuration, context: context)
        let entries: [Entry] = await generateEntries(baseChineseCalendar: asyncModel.chineseCalendar, timeline: entryDates, watchLayout: asyncModel.layout, calendarConfig: asyncModel.config, configuration: configuration)
        return Timeline(entries: entries, policy: .atEnd)
    }

    func compactCalendar(context: Context) -> Bool {
        return true
    }
}

struct AsyncLocalModels {
    let chineseCalendar: ChineseCalendar
    let config: CalendarConfigure
    let layout: WatchLayout

    init(compact: Bool = true, config: CalendarConfigure? = nil) async {
        var loadedLayout: WatchLayout = .defaultLayout
        try? await LocalDataModel.shared.load { (model: LocalTheme?, context) in
            if let model {
                loadedLayout = model.theme
            } else {
                try context.insert(LocalTheme(loadedLayout))
                try context.save()
            }
        }
        layout = loadedLayout
        if let config {
            self.config = config
        } else {
            var loadedConfig: CalendarConfigure = .init()
            try? await LocalDataModel.shared.load { (model: LocalConfig?, context) in
                if let model {
                    loadedConfig = model.config
                } else {
                    try context.insert(LocalConfig(loadedConfig))
                    try context.save()
                }
            }
            self.config = loadedConfig
        }

        let location = await self.config.location(maxWait: .seconds(2))
        chineseCalendar = ChineseCalendar(timezone: self.config.effectiveTimezone, location: location, compact: compact, globalMonth: self.config.globalMonth, apparentTime: self.config.apparentTime, largeHour: self.config.largeHour)
    }
}
