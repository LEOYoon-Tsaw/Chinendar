//
//  WidgetModels.swift
//  Chinendar
//
//  Created by Leo Liu on 9/3/23.
//

import WidgetKit
import AppIntents

protocol ChinendarWidgetConfigIntent: AppIntent, WidgetConfigurationIntent {
    var calendarConfig: ConfigIntent? { get set }
    var calendarTheme: ThemeIntent? { get set }
}

protocol ChinendarEntry: Sendable {
    associatedtype Intent: ChinendarWidgetConfigIntent
    init(configuration: Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout)
}

func generateEntries<Entry: TimelineEntry & ChinendarEntry, Intent: WidgetConfigurationIntent>(baseChineseCalendar: ChineseCalendar, timeline: [Date], watchLayout: WatchLayout, configuration: Intent) async -> [Entry] where Entry.Intent == Intent {
    var entries: [Entry] = [Entry(configuration: configuration, chineseCalendar: baseChineseCalendar, watchLayout: watchLayout)]
    await withTaskGroup { group in
        for date in timeline {
            group.addTask {
                var newCalendar = baseChineseCalendar
                newCalendar.update(time: date)
                return Entry(configuration: configuration, chineseCalendar: newCalendar, watchLayout: watchLayout)
            }
        }
        for await result in group {
            entries.append(result)
        }
    }
    entries.sort { $0.date < $1.date }
    return entries
}

#if DEBUG
extension ConfigIntent {
    static let preview: Self = {
        var config = CalendarConfigure()
        config.locationEnabled = true
        config.timezone = TimeZone(identifier: "America/New_York")!
        config.customLocation = GeoLocation(lat: 40, lon: -74)
        return Self(id: "preview", name: "preview", config: config)
    }()
}
#endif
