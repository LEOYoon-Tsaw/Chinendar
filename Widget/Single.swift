//
//  Single.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
import WidgetKit

enum DisplayMode: String, AppEnum {
    case date, time

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "日時之擇一")
    static var caseDisplayRepresentations: [DisplayMode : DisplayRepresentation] = [
        .date: .init(title: "日"),
        .time: .init(title: "時"),
    ]
}

struct SmallConfiguration: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "SmallIntent"
    static var title: LocalizedStringResource = "簡錶"
    static var description = IntentDescription("簡化之錶以展現日時之一")

    @Parameter(title: "型制", default: .time)
    var mode: DisplayMode
    
    @Parameter(title: "背景灰度", default: 0, controlStyle: .slider, inclusiveRange: (0, 1))
    var backAlpha: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$mode
            \.$backAlpha
        }
    }
}

struct SmallProvider: AppIntentTimelineProvider {
    typealias Entry = SmallEntry
    typealias Intent = SmallConfiguration
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
        return Entry(configuration: configuration, chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()

        let chineseCalendar = ChineseCalendar(location: location, compact: true)
        let entryDates = switch configuration.mode {
        case .time:
            chineseCalendar.nextQuarters(count: 15)
        case .date:
            chineseCalendar.nextHours(count: 15)
        }
        var chineseCalendars = [chineseCalendar.copy]
        for entryDate in entryDates {
            chineseCalendar.update(time: entryDate, location: location)
            chineseCalendars.append(chineseCalendar.copy)
        }
        let entries: [Entry] = await generateEntries(chineseCalendars: chineseCalendars, watchLayout: watchLayout, configuration: configuration)
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SmallEntry: TimelineEntry, ChineseTimeEntry {
    let date: Date
    let configuration: SmallProvider.Intent
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout
    let relevance: TimelineEntryRelevance?
    
    init(configuration: SmallProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        date = chineseCalendar.time
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        switch configuration.mode {
        case .time:
            relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: chineseCalendar.nextQuarters(count: 1)[0]))
        case .date:
            relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: chineseCalendar.nextHours(count: 1)[0]))
        }
    }
}

struct SmallWidgetEntryView: View {
    var entry: SmallProvider.Entry
    var backColor: Color {
        Color.gray.opacity(entry.configuration.backAlpha)
    }
    
    var body: some View {
        switch entry.configuration.mode {
        case .time:
            TimeWatch(matchZeroRingGap: false, displaySubquarter: false, compact: true, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, widthScale: 1.5)
                .containerBackground(backColor, for: .widget)
                .padding(5)
        case .date:
            DateWatch(displaySolarTerms: false, compact: true, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, widthScale: 1.5)
                .containerBackground(backColor, for: .widget)
                .padding(5)
        }
    }
}

struct SmallWidget: Widget {
    static let kind: String = "Small"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: SmallProvider.Intent.self, provider: SmallProvider()) { entry in
            SmallWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable()
        .configurationDisplayName("簡錶")
        .description("簡化之錶以展現日時之一")
        .supportedFamilies([.systemSmall])
    }
}


#Preview("Small Date", as: .systemSmall, using: {
    let intent = SmallProvider.Intent()
    intent.mode = .date
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    SmallWidget()
}, timelineProvider: {
    SmallProvider()
})

#Preview("Small Time", as: .systemSmall, using: {
    let intent = SmallProvider.Intent()
    intent.mode = .time
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    SmallWidget()
}, timelineProvider: {
    SmallProvider()
})
