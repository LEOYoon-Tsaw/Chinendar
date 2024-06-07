//
//  WatchWidget.swift
//  WatchWidget
//
//  Created by Leo Liu on 5/10/23.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

enum TextWidgetSeparator: String, AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "讀號選項")
    case space = " ", dot = "・", none = ""
    static let caseDisplayRepresentations: [TextWidgetSeparator: DisplayRepresentation] = [
        .none: .init(title: "無"),
        .dot: .init(title: "・"),
        .space: .init(title: "空格")
    ]
}

enum TextWidgetTime: String, AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "讀號選項")
    case none, hour, hourAndQuarter
    static let caseDisplayRepresentations: [TextWidgetTime: DisplayRepresentation] = [
        .none: .init(title: "無"),
        .hour: .init(title: "僅時"),
        .hourAndQuarter: .init(title: "時刻")
    ]
}

struct TextConfiguration: ChinendarWidgetConfigIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "SingleLineIntent"
    static let title: LocalizedStringResource = "文字"
    static let description = IntentDescription("簡單華曆文字")

    @Parameter(title: "選日曆")
    var calendarConfig: ConfigIntent
    @Parameter(title: "日", default: true)
    var date: Bool
    @Parameter(title: "時", default: .hour)
    var time: TextWidgetTime
    @Parameter(title: "節日", default: 1, controlStyle: .stepper, inclusiveRange: (0, 2))
    var holidays: Int
    @Parameter(title: "讀號", default: .dot)
    var separator: TextWidgetSeparator

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$calendarConfig
            \.$date
            \.$time
            \.$holidays
            \.$separator
        }
    }
}

struct TextProvider: ChinendarAppIntentTimelineProvider {
    typealias Intent = TextConfiguration
    typealias Entry = TextEntry
    let modelContext = DataSchema.context
    let locationManager = LocationManager()

    func nextEntryDates(chineseCalendar: ChineseCalendar, config: TextConfiguration, context: Context) -> [Date] {
        switch config.time {
        case .hour, .none:
            return chineseCalendar.nextHours(count: 12)
        case .hourAndQuarter:
            return chineseCalendar.nextQuarters(count: 12)
        }
    }

    func recommendations() -> [AppIntentRecommendation<Intent>] {
        let datetimeHoliday = Intent()
        let datetime = Intent()
        datetime.holidays = 0
        datetime.time = .hourAndQuarter
        let dateholiday = Intent()
        dateholiday.time = .none
        return [
            AppIntentRecommendation(intent: datetimeHoliday, description: "日時、節日"),
            AppIntentRecommendation(intent: datetime, description: "日時"),
            AppIntentRecommendation(intent: dateholiday, description: "日、節日")
        ]
    }
}

struct TextEntry: TimelineEntry, ChinendarEntry {
    let date: Date
    let displayDate: Bool
    let displayTime: TextWidgetTime
    let DisplayHolidays: Int
    let separator: String
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout
    let relevance: TimelineEntryRelevance?

    init(configuration: TextProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        self.date = chineseCalendar.time
        self.displayDate = configuration.date
        self.displayTime = configuration.time
        self.DisplayHolidays = configuration.holidays
        self.separator = configuration.separator.rawValue
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        self.relevance = TimelineEntryRelevance(score: 5, duration: 144)
    }
}

struct TextEntryView: View {
    var entry: TextProvider.Entry

    var body: some View {
        LineDescription(chineseCalendar: entry.chineseCalendar, displayDate: entry.displayDate, displayTime: entry.displayTime, displayHolidays: entry.DisplayHolidays, separator: entry.separator)
            .containerBackground(Color.clear, for: .widget)
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

#Preview("Inline", as: .accessoryInline, using: {
    let intent = TextProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    return intent
}()) {
    LineWidget()
} timelineProvider: {
    TextProvider()
}
