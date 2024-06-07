//
//  Single.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

enum DisplayMode: String, AppEnum {
    case date, time

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "日時之擇一")
    static let caseDisplayRepresentations: [DisplayMode: DisplayRepresentation] = [
        .date: .init(title: "日"),
        .time: .init(title: "時")
    ]
}

struct SmallConfiguration: ChinendarWidgetConfigIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "SmallIntent"
    static let title: LocalizedStringResource = "簡錶"
    static let description = IntentDescription("簡化之錶以展現日時之一")

    @Parameter(title: "選日曆")
    var calendarConfig: ConfigIntent

    @Parameter(title: "型制", default: .time)
    var mode: DisplayMode

    @Parameter(title: "背景灰度", default: 0, controlStyle: .slider, inclusiveRange: (0, 1))
    var backAlpha: Double

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$calendarConfig
            \.$mode
            \.$backAlpha
        }
    }
}

struct SmallProvider: ChinendarAppIntentTimelineProvider {
    typealias Entry = SmallEntry
    typealias Intent = SmallConfiguration
    let modelContext = DataSchema.context
    let locationManager = LocationManager()

    func nextEntryDates(chineseCalendar: ChineseCalendar, config: SmallConfiguration, context: Context) -> [Date] {
        return switch config.mode {
        case .time:
            chineseCalendar.nextQuarters(count: 15)
        case .date:
            chineseCalendar.nextHours(count: 15)
        }
    }
}

struct SmallEntry: TimelineEntry, ChinendarEntry {
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
            TimeWatch(matchZeroRingGap: false, displaySubquarter: false, compact: true, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: 1.5)
                .containerBackground(backColor, for: .widget)
                .padding(5)
        case .date:
            DateWatch(displaySolarTerms: false, compact: true, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: 1.5)
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
    intent.calendarConfig = .init(id: AppInfo.defaultName)
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
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.mode = .time
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    SmallWidget()
}, timelineProvider: {
    SmallProvider()
})
