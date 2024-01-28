//
//  TaskGroup.swift
//  Chinendar
//
//  Created by Leo Liu on 9/3/23.
//

import WidgetKit
import AppIntents

protocol ChinendarEntry: Sendable {
    associatedtype Intent: WidgetConfigurationIntent
    init(configuration: Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout)
}

func generateEntries<Entry: TimelineEntry & ChinendarEntry, Intent: WidgetConfigurationIntent>(chineseCalendars: [ChineseCalendar], watchLayout: WatchLayout, configuration: Intent) async -> [Entry] where Entry.Intent == Intent {
    var entries: [Entry] = []
    await withTaskGroup(of: Entry.self) { group in
        for calendar in chineseCalendars {
            group.addTask {
                return Entry(configuration: configuration, chineseCalendar: calendar, watchLayout: watchLayout)
            }
        }
        for await result in group {
            entries.append(result)
        }
    }
    entries.sort { $0.date < $1.date }
    return entries
}
