//
//  Dual.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
import WidgetKit

enum DisplayOrder: String, AppEnum {
    case dateFirst, timeFirst

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "日時之順序")
    static var caseDisplayRepresentations: [DisplayOrder : DisplayRepresentation] = [
        .dateFirst: .init(title: "日左時右"),
        .timeFirst: .init(title: "時左日右"),
    ]
}

struct MediumConfiguration: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "MediumIntent"
    static var title: LocalizedStringResource = "雙錶"
    static var description = IntentDescription("雙錶以同時展現日時，順序可選")

    @Parameter(title: "順序", default: .dateFirst)
    var order: DisplayOrder
    
    @Parameter(title: "背景灰度", default: 0, controlStyle: .slider, inclusiveRange: (0, 1))
    var backAlpha: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$order
            \.$backAlpha
        }
    }
}

struct MediumProvider: AppIntentTimelineProvider {
    typealias Entry = MediumEntry
    typealias Intent = MediumConfiguration
    let modelContext = ThemeData.context
    let locationManager = LocationManager.shared
    
    func placeholder(in context: Context) -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadStatic()
        let chineseCalendar = ChineseCalendar(time: .now, compact: context.family != .systemExtraLarge)
        return Entry(configuration: Intent(), chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()
        let chineseCalendar = ChineseCalendar(location: location, compact: context.family != .systemExtraLarge)
        return Entry(configuration: configuration, chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()

        let chineseCalendar = ChineseCalendar(location: location, compact: context.family != .systemExtraLarge)
        var chineseCalendars = [chineseCalendar.copy]
        for entryDate in chineseCalendar.nextQuarters(count: 10) {
            chineseCalendar.update(time: entryDate, location: location)
            chineseCalendars.append(chineseCalendar.copy)
        }
        let entries: [Entry] = await generateEntries(chineseCalendars: chineseCalendars, watchLayout: watchLayout, configuration: configuration)
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct MediumEntry: TimelineEntry, ChineseTimeEntry {
    let date: Date
    let configuration: MediumProvider.Intent
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout
    let relevance: TimelineEntryRelevance?
    
    init(configuration: MediumProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        date = chineseCalendar.time
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: chineseCalendar.nextQuarters(count: 1)[0]))
    }
}

struct MediumWidgetEntryView: View {
    var entry: MediumProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    init(entry: MediumProvider.Entry) {
        self.entry = entry
    }
    
    func backColor() -> Color {
        return Color.gray.opacity(entry.configuration.backAlpha)
    }

    var body: some View {
        let isLarge = widgetFamily == .systemExtraLarge

        GeometryReader { proxy in
            HStack(spacing: (proxy.size.width - proxy.size.height * 2) * 0.5) {
                switch entry.configuration.order {
                case .timeFirst:
                    TimeWatch(matchZeroRingGap: isLarge, displaySubquarter: false, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, widthScale: isLarge ? 1.1 : 1.5)
                    DateWatch(displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, widthScale: isLarge ? 1.1 : 1.5)
                case .dateFirst:
                    DateWatch(displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, widthScale: isLarge ? 1.1 : 1.5)
                    TimeWatch(matchZeroRingGap: isLarge, displaySubquarter: false, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, widthScale: isLarge ? 1.1 : 1.5)
                }
            }
            .padding(.horizontal, (proxy.size.width - proxy.size.height * 2) * 0.25)
        }
        .containerBackground(backColor(), for: .widget)
        .padding(5)
    }
}


struct MediumWidget: Widget {
    static let kind: String = "Medium"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: MediumProvider.Intent.self, provider: MediumProvider()) { entry in
            MediumWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable()
        .configurationDisplayName("雙錶")
        .description("雙錶以同時展現日時")
        .supportedFamilies([.systemMedium, .systemExtraLarge])
    }
}

#Preview("Medium", as: .systemMedium, using: {
    let intent = MediumProvider.Intent()
    intent.order = .dateFirst
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    MediumWidget()
}, timelineProvider: {
    MediumProvider()
})
