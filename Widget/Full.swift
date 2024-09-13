//
//  Full.swift
//  iOSWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import AppIntents
import SwiftUI
import WidgetKit

struct FullWatchConfiguration: ChinendarWidgetConfigIntent {
    static let title: LocalizedStringResource = "全錶"
    static let description = IntentDescription("完整華曆錶")

    @Parameter(title: "選日曆")
    var calendarConfig: ConfigIntent?

    @Parameter(title: "背景灰度", default: 0, controlStyle: .slider, inclusiveRange: (0, 1))
    var backAlpha: Double

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$calendarConfig
            \.$backAlpha
        }
    }
}

struct FullWatchProvider: ChinendarAppIntentTimelineProvider {
    typealias Entry = FullWatchEntry
    typealias Intent = FullWatchConfiguration

    func compactCalendar(context: Context) -> Bool {
        return context.family != .systemLarge
    }

    func nextEntryDates(chineseCalendar: ChineseCalendar, config: FullWatchConfiguration, context: Context) -> [Date] {
        return chineseCalendar.nextQuarters(count: 10)
    }
    
    func relevances() async -> WidgetRelevance<Intent> {
        let asyncModels = await AsyncModels()

        var relevantIntents = [WidgetRelevanceAttribute<Entry.Intent>]()

        for date in asyncModels.chineseCalendar.nextHours(count: 5) {
            let config = Intent()
            let relevantContext = RelevantContext.date(from: date - 900, to: date + 600)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }
        
        return WidgetRelevance(relevantIntents)
    }
}

struct FullWatchEntry: TimelineEntry, ChinendarEntry {
    let date: Date
    let configuration: FullWatchProvider.Intent
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout

    init(configuration: FullWatchProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        date = chineseCalendar.time
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
    }
}

struct FullWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: FullWatchProvider.Entry
    var backColor: Color {
        Color.gray.opacity(entry.configuration.backAlpha)
    }

    var body: some View {
        let isLarge = widgetFamily == .systemLarge
        Watch(displaySubquarter: false, displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.0, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 0.8 : 1.0)
            .containerBackground(backColor, for: .widget)
            .padding(5)
    }
}

struct FullWatchWidget: Widget {
    static let kind: String = "Large"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: FullWatchProvider.Intent.self, provider: FullWatchProvider()) { entry in
            FullWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable()
        .configurationDisplayName("全錶")
        .description("完整華曆錶")
        .supportedFamilies([.systemSmall, .systemLarge])
    }
}

#Preview("Small", as: .systemSmall, using: {
    let intent = FullWatchProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    FullWatchWidget()
}, timelineProvider: {
    FullWatchProvider()
})

#Preview("Large", as: .systemLarge, using: {
    let intent = FullWatchProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    FullWatchWidget()
}, timelineProvider: {
    FullWatchProvider()
})
