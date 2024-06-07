//
//  TaskGroup.swift
//  Chinendar
//
//  Created by Leo Liu on 9/3/23.
//

import WidgetKit
import AppIntents
import SwiftData

struct ConfigIntent: AppEntity {
    let id: String
    var name: String { id }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "選日曆"
    static var defaultQuery = ConfigQuery()

    var displayRepresentation: DisplayRepresentation {
        if name != AppInfo.defaultName {
            DisplayRepresentation(title: "\(name)")
        } else {
            DisplayRepresentation("常用")
        }
    }
}

struct ConfigQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ConfigIntent] {
        try await suggestedEntities().filter { identifiers.contains($0.name) }
    }

    func suggestedEntities() async throws -> [ConfigIntent] {
        var allConfigs = [ConfigIntent]()
        let context = DataSchema.context
        let descriptor = FetchDescriptor<ConfigData>(sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        let configs = try context.fetch(descriptor)
        for config in configs where !config.isNil {
            allConfigs.append(ConfigIntent(id: config.name!))
        }
        if allConfigs.count > 0 {
            return allConfigs
        } else {
            return [ConfigIntent(id: AppInfo.defaultName)]
        }
    }

    func defaultResult() async -> ConfigIntent? {
        let name = LocalData.read(context: LocalSchema.context)?.configName ?? AppInfo.defaultName
        return ConfigIntent(id: name)
    }
}

protocol ChinendarWidgetConfigIntent: AppIntent, WidgetConfigurationIntent {
    var calendarConfig: ConfigIntent { get set }
}

protocol ChinendarEntry: Sendable {
    associatedtype Intent: ChinendarWidgetConfigIntent
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
