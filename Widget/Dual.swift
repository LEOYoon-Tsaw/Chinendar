//
//  Dual.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
import WidgetKit

enum DisplayMode: String, AppEnum {
    case date, time

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "日時選擇")
    static let caseDisplayRepresentations: [DisplayMode: DisplayRepresentation] = [
        .date: .init(title: "以日爲主"),
        .time: .init(title: "以時爲主")
    ]
}

struct DualWatchConfiguration: ChinendarWidgetConfigIntent {
    static let title: LocalizedStringResource = "雙錶"
    static let description = IntentDescription("日、時分列的雙生錶面")
    
    @Parameter(title: "選日曆")
    var calendarConfig: ConfigIntent?

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

struct DualWatchProvider: ChinendarAppIntentTimelineProvider {
    typealias Entry = DualWatchEntry
    typealias Intent = DualWatchConfiguration

    func nextEntryDates(chineseCalendar: ChineseCalendar, config: DualWatchConfiguration, context: Context) -> [Date] {
        return switch context.family {
        case .systemSmall:
            switch config.mode {
            case .time:
                chineseCalendar.nextQuarters(count: 15)
            case .date:
                chineseCalendar.nextHours(count: 15)
            }
        case .systemMedium, .systemExtraLarge:
            chineseCalendar.nextQuarters(count: 10)
        default:
            []
        }
    }
    
    func relevances() async -> WidgetRelevance<Intent> {
        let asyncModels = await AsyncModels()

        var relevantIntents = [WidgetRelevanceAttribute<Entry.Intent>]()

        for date in asyncModels.chineseCalendar.nextHours(count: 6) {
            let config = Intent()
            config.mode = .time
            let relevantContext = RelevantContext.date(from: date - 900, to: date + 600)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in [asyncModels.chineseCalendar.startOfNextDay] {
            let config = Intent()
            config.mode = .date
            let relevantContext = RelevantContext.date(from: date - 3600, to: date + 900)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }
        
        return WidgetRelevance(relevantIntents)
    }
}

struct DualWatchEntry: TimelineEntry, ChinendarEntry {
    let date: Date
    let configuration: DualWatchProvider.Intent
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout

    init(configuration: DualWatchProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        date = chineseCalendar.time
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
    }
}

struct DualWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: DualWatchProvider.Entry
    var backColor: Color {
        Color.gray.opacity(entry.configuration.backAlpha)
    }

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
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
            
        case .systemMedium, .systemExtraLarge:
            let isLarge = widgetFamily == .systemExtraLarge

            GeometryReader { proxy in
                HStack(spacing: (proxy.size.width - proxy.size.height * 2) * 0.5) {
                    switch entry.configuration.mode {
                    case .time:
                        TimeWatch(matchZeroRingGap: isLarge, displaySubquarter: false, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                        DateWatch(displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                    case .date:
                        DateWatch(displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                        TimeWatch(matchZeroRingGap: isLarge, displaySubquarter: false, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                    }
                }
                .padding(.horizontal, (proxy.size.width - proxy.size.height * 2) * 0.25)
            }
            .containerBackground(backColor, for: .widget)
            .padding(5)
            
        default:
            EmptyView()
        }
    }
}

struct DualWatchWidget: Widget {
    static let kind: String = "Dual"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: DualWatchProvider.Intent.self, provider: DualWatchProvider()) { entry in
            DualWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable()
        .configurationDisplayName("雙錶")
        .description("日、時分列的雙生錶面")
        .supportedFamilies([.systemSmall, .systemMedium, .systemExtraLarge])
    }
}

#Preview("Small Date", as: .systemSmall, using: {
    let intent = DualWatchProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.mode = .date
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    DualWatchWidget()
}, timelineProvider: {
    DualWatchProvider()
})

#Preview("Small Time", as: .systemSmall, using: {
    let intent = DualWatchProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.mode = .time
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    DualWatchWidget()
}, timelineProvider: {
    DualWatchProvider()
})

#Preview("Medium", as: .systemMedium, using: {
    let intent = DualWatchProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.mode = .time
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    DualWatchWidget()
}, timelineProvider: {
    DualWatchProvider()
})
