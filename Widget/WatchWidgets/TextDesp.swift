//
//  WatchWidget.swift
//  WatchWidget
//
//  Created by Leo Liu on 5/10/23.
//

import AppIntents
import SwiftUI
import WidgetKit

struct TextConfiguration: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "SingleLineIntent"
    static var title: LocalizedStringResource = "文字"
    static var description = IntentDescription("簡單華曆文字")
}

struct TextProvider: AppIntentTimelineProvider {    
    typealias Intent = TextConfiguration
    typealias Entry = TextEntry
    let modelContext = ThemeData.context
    let locationManager = LocationManager.shared
    
    func placeholder(in context: Context) -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadStatic()
        let chineseCalendar = ChineseCalendar(time: .now, compact: true)
        return Entry(configuration: Intent(), chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()
        let chineseCalendar = ChineseCalendar(location: location, compact: true)
        let entry = Entry(configuration: configuration, chineseCalendar: chineseCalendar, watchLayout: watchLayout)
        return entry
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()

        let chineseCalendar = ChineseCalendar(location: location, compact: true)
        let entryDates = switch context.family {
        case .accessoryInline:
            chineseCalendar.nextHours(count: 12)
        case .accessoryRectangular:
            chineseCalendar.nextQuarters(count: 12)
        default:
            [Date]()
        }

        var chineseCalendars = [chineseCalendar.copy]
        for entryDate in entryDates {
            chineseCalendar.update(time: entryDate, location: location)
            chineseCalendars.append(chineseCalendar.copy)
        }
        let entries: [Entry] = await generateEntries(chineseCalendars: chineseCalendars, watchLayout: watchLayout, configuration: configuration)
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    func recommendations() -> [AppIntentRecommendation<Intent>] {
        return [
            AppIntentRecommendation(intent: Intent(), description: "華曆"),
        ]
    }
}

struct TextEntry: TimelineEntry, ChineseTimeEntry {
    let date: Date
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout
    let relevance: TimelineEntryRelevance?
    
    init(configuration: TextProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        date = chineseCalendar.time
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        self.relevance = TimelineEntryRelevance(score: 5, duration: 144)
    }
}

struct TextEntryView: View {
    var entry: TextProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            LineDescription(chineseCalendar: entry.chineseCalendar)
                .containerBackground(Color.clear, for: .widget)
        case .accessoryRectangular:
            let chineseCalendar = entry.chineseCalendar
            CalendarBadge(dateString: chineseCalendar.dateString, timeString: chineseCalendar.hourString + chineseCalendar.shortQuarterString, color: applyGradient(gradient: entry.watchLayout.centerFontColor, startingAngle: 0), backGround: Color(cgColor: entry.watchLayout.innerColor))
                .containerBackground(Color(cgColor: entry.watchLayout.innerColor), for: .widget)
        default:
            EmptyView()
        }
    }
}

struct LineWidget: Widget {
    static let kind: String = "Date String"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: TextProvider.Intent.self, provider: TextProvider()) { entry in
            TextEntryView(entry: entry)
        }
        .containerBackgroundRemovable()
        .configurationDisplayName("華曆文字")
        .description("樸素寫就之華曆")
        .supportedFamilies([.accessoryInline])
    }
}

struct DateCardWidget: Widget {
    static let kind: String = "Date Card"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: TextProvider.Intent.self, provider: TextProvider()) { entry in
            TextEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable()
        .configurationDisplayName("華曆片")
        .description("寫有華曆日時之片")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview("Inline", as: .accessoryInline, using: TextProvider.Intent()) {
    LineWidget()
} timelineProvider: {
    TextProvider()
}

#Preview("Card", as: .accessoryRectangular, using: TextProvider.Intent()) {
    DateCardWidget()
} timelineProvider: {
    TextProvider()
}
