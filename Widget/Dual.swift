//
//  Dual.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

enum DisplayOrder: String, AppEnum {
    case dateFirst, timeFirst

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "日時之順序")
    static let caseDisplayRepresentations: [DisplayOrder : DisplayRepresentation] = [
        .dateFirst: .init(title: "日左時右"),
        .timeFirst: .init(title: "時左日右"),
    ]
}

struct MediumConfiguration: ChinendarWidgetConfigIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "MediumIntent"
    static let title: LocalizedStringResource = "雙錶"
    static let description = IntentDescription("雙錶以同時展現日時，順序可選")

    @Parameter(title: "選日曆")
    var calendarConfig: ConfigIntent
    
    @Parameter(title: "順序", default: .dateFirst)
    var order: DisplayOrder
    
    @Parameter(title: "背景灰度", default: 0, controlStyle: .slider, inclusiveRange: (0, 1))
    var backAlpha: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$calendarConfig
            \.$order
            \.$backAlpha
        }
    }
}

struct MediumProvider: ChinendarAppIntentTimelineProvider {
    typealias Entry = MediumEntry
    typealias Intent = MediumConfiguration
    let modelContext = DataSchema.context
    let locationManager = LocationManager()
    
    func compactCalendar(context: Context) -> Bool {
        return context.family != .systemExtraLarge
    }
    
    func nextEntryDates(chineseCalendar: ChineseCalendar, config: MediumConfiguration, context: Context) -> [Date] {
        return chineseCalendar.nextQuarters(count: 10)
    }
}

struct MediumEntry: TimelineEntry, ChinendarEntry {
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
                    TimeWatch(matchZeroRingGap: isLarge, displaySubquarter: false, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                    DateWatch(displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                case .dateFirst:
                    DateWatch(displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                    TimeWatch(matchZeroRingGap: isLarge, displaySubquarter: false, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
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
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.order = .dateFirst
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    MediumWidget()
}, timelineProvider: {
    MediumProvider()
})
