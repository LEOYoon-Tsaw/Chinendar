//
//  Widget.swift
//  iOSWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

struct LargeConfiguration: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "LargeIntent"
    static var title: LocalizedStringResource = "全錶"
    static var description = IntentDescription("完整錶面")
    
    @Parameter(title: "背景灰度", default: 0, controlStyle: .slider, inclusiveRange: (0, 1))
    var backAlpha: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$backAlpha
        }
    }
}

struct LargeProvider: AppIntentTimelineProvider {
    typealias Entry = LargeEntry
    typealias Intent = LargeConfiguration
    let modelContext = ThemeData.context
    let locationManager = LocationManager.shared
    
    func placeholder(in context: Context) -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadStatic()
        let chineseCalendar = ChineseCalendar(time: .now, compact: context.family != .systemLarge)
        return Entry(configuration: Intent(), chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()
        let chineseCalendar = ChineseCalendar(location: location, compact: context.family != .systemLarge)
        return Entry(configuration: configuration, chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()
        
        let chineseCalendar = ChineseCalendar(location: location, compact: context.family != .systemLarge)
        var chineseCalendars = [chineseCalendar.copy]
        for entryDate in chineseCalendar.nextQuarters(count: 10) {
            chineseCalendar.update(time: entryDate, location: location)
            chineseCalendars.append(chineseCalendar.copy)
        }
        let entries: [Entry] = await generateEntries(chineseCalendars: chineseCalendars, watchLayout: watchLayout, configuration: configuration)
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct LargeEntry: TimelineEntry, ChineseTimeEntry {
    let date: Date
    let configuration: LargeProvider.Intent
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout
    let relevance: TimelineEntryRelevance?
    
    init(configuration: LargeProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        date = chineseCalendar.time
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: chineseCalendar.nextQuarters(count: 1)[0]))
    }
}

struct LargeWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: LargeProvider.Entry

    init(entry: LargeProvider.Entry) {
        self.entry = entry
    }
    
    func backColor() -> Color {
        return Color.gray.opacity(entry.configuration.backAlpha)
    }

    var body: some View {
        let isLarge = widgetFamily == .systemLarge
        Watch(displaySubquarter: false, displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.0, chineseCalendar: entry.chineseCalendar, widthScale: isLarge ? 0.8 : 1.0)
            .containerBackground(backColor(), for: .widget)
            .padding(5)
    }
}

struct LargeWidget: Widget {
    static let kind: String = "Large"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: LargeProvider.Intent.self, provider: LargeProvider()) { entry in
            LargeWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable()
        .configurationDisplayName("全錶")
        .description("完整華曆錶")
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}

#Preview("Large", as: .systemLarge, using: {
    let intent = LargeProvider.Intent()
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    LargeWidget()
}, timelineProvider: {
    LargeProvider()
})
