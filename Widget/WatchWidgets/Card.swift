//
//  Card.swift
//  Chinendar
//
//  Created by Leo Liu on 1/21/24.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

struct CardConfiguration: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "TextCardIntent"
    static var title: LocalizedStringResource = "文字片"
    static var description = IntentDescription("華曆文字片")
}

struct CardProvider: ChinendarAppIntentTimelineProvider {
    typealias Intent = CardConfiguration
    typealias Entry = CardEntry
    let modelContext = ThemeData.context
    let locationManager = LocationManager.shared
    
    func nextEntryDates(chineseCalendar: ChineseCalendar, config: CardConfiguration, context: Context) -> [Date] {
        return chineseCalendar.nextQuarters(count: 12)
    }
    
    func recommendations() -> [AppIntentRecommendation<Intent>] {
        return [
            AppIntentRecommendation(intent: Intent(), description: "華曆"),
        ]
    }
}

struct CardEntry: TimelineEntry, ChinendarEntry {
    let date: Date
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout
    let relevance: TimelineEntryRelevance?
    
    init(configuration: CardProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        self.date = chineseCalendar.time
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        self.relevance = TimelineEntryRelevance(score: 5, duration: 144)
    }
}

struct CardEntryView: View {
    var entry: CardProvider.Entry

    var body: some View {
        let chineseCalendar = entry.chineseCalendar
        CalendarBadge(dateString: chineseCalendar.dateString, timeString: chineseCalendar.hourString + chineseCalendar.shortQuarterString, color: applyGradient(gradient: entry.watchLayout.centerFontColor, startingAngle: 0), backGround: Color(cgColor: entry.watchLayout.innerColor))
            .containerBackground(Color(cgColor: entry.watchLayout.innerColor), for: .widget)
    }
}

struct DateCardWidget: Widget {
    static let kind: String = "Date Card"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: CardProvider.Intent.self, provider: CardProvider()) { entry in
            CardEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable()
        .configurationDisplayName("華曆片")
        .description("寫有華曆日時之片")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview("Card", as: .accessoryRectangular, using: CardProvider.Intent()) {
    DateCardWidget()
} timelineProvider: {
    CardProvider()
}
