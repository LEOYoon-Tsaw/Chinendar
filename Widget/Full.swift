//
//  Widget.swift
//  iOSWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

struct LargeConfiguration: ChinendarWidgetConfigIntent {
    static let title: LocalizedStringResource = "全錶"
    static let description = IntentDescription("完整錶面")

    @Parameter(title: "選日曆")
    var calendarConfig: ConfigIntent

    @Parameter(title: "背景灰度", default: 0, controlStyle: .slider, inclusiveRange: (0, 1))
    var backAlpha: Double

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$calendarConfig
            \.$backAlpha
        }
    }
}

struct LargeProvider: ChinendarAppIntentTimelineProvider {
    typealias Entry = LargeEntry
    typealias Intent = LargeConfiguration
    let modelContext = DataSchema.context
    let locationManager = LocationManager()

    func compactCalendar(context: Context) -> Bool {
        return context.family != .systemLarge
    }

    func nextEntryDates(chineseCalendar: ChineseCalendar, config: LargeConfiguration, context: Context) -> [Date] {
        return chineseCalendar.nextQuarters(count: 10)
    }
}

struct LargeEntry: TimelineEntry, ChinendarEntry {
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
        Watch(displaySubquarter: false, displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.0, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 0.8 : 1.0)
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
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    LargeWidget()
}, timelineProvider: {
    LargeProvider()
})
