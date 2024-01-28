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
    var modelContext: ModelContext { get }
    var locationManager: LocationManager { get }
    
    func nextEntryDates(chineseCalendar: ChineseCalendar, config: Entry.Intent, context: Context) -> [Date]
    func compactCalendar(context: Context) -> Bool
}

extension ChinendarAppIntentTimelineProvider {
    func placeholder(in context: Context) -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadStatic()
        let chineseCalendar = ChineseCalendar(time: .now, compact: compactCalendar(context: context))
        return Entry(configuration: Entry.Intent(), chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }
    
    func snapshot(for configuration: Entry.Intent, in context: Context) async -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()
        let chineseCalendar = ChineseCalendar(location: location, compact: compactCalendar(context: context))
        let entry = Entry(configuration: configuration, chineseCalendar: chineseCalendar, watchLayout: watchLayout)
        return entry
    }
    
    func timeline(for configuration: Entry.Intent, in context: Context) async -> Timeline<Entry> {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()

        let chineseCalendar = ChineseCalendar(location: location, compact: compactCalendar(context: context))
        let originalChineseCalendar = chineseCalendar.copy
        let entryDates = nextEntryDates(chineseCalendar: chineseCalendar, config: configuration, context: context)
        
        var chineseCalendars = [chineseCalendar.copy]
        for entryDate in entryDates {
            chineseCalendar.update(time: entryDate, location: location)
            chineseCalendars.append(chineseCalendar.copy)
        }
        let entries: [Entry] = await generateEntries(chineseCalendars: chineseCalendars, watchLayout: watchLayout, configuration: configuration)
#if os(watchOS)
        if context.family == .accessoryRectangular {
            await updateCountDownRelevantIntents(chineseCalendar: originalChineseCalendar)
        }
#endif
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    func compactCalendar(context: Context) -> Bool {
        return true
    }
}
