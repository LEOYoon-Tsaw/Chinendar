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

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "DATE_TIME_PRIORITY")
    static let caseDisplayRepresentations: [DisplayMode: DisplayRepresentation] = [
        .date: .init(title: "DATE_FIRST"),
        .time: .init(title: "TIME_FIRST")
    ]
}

struct DualWatchConfiguration: ChinendarWidgetConfigIntent {
    static let title: LocalizedStringResource = "WGT_SPLIT_WATCH"
    static let description = IntentDescription("WGT_SPLIT_WATCH_MSG")

    @Parameter(title: "SELECT_CALENDAR")
    var calendarConfig: ConfigIntent?

    @Parameter(title: "DISPLAY_MODE", default: .time)
    var mode: DisplayMode

    @Parameter(title: "BACK_GREYNESS", default: 0, controlStyle: .slider, inclusiveRange: (0, 1))
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
        let asyncModels = await AsyncLocalModels()

        var relevantIntents = [WidgetRelevanceAttribute<Entry.Intent>]()

        for date in asyncModels.chineseCalendar.nextHours(count: 6) {
            let config = Intent()
            config.mode = .time
            let relevantContext = RelevantContext.date(range: (date - 900)...(date + 600), kind: .informational)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in [asyncModels.chineseCalendar.startOfNextDay] {
            let config = Intent()
            config.mode = .date
            let relevantContext = RelevantContext.date(range: (date - 3600)...(date + 900), kind: .informational)
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
        GeometryReader { proxy in
            switch widgetFamily {
            case .systemSmall:
                let size = CGSize(width: proxy.size.width * 0.95, height: proxy.size.height * 0.95)
                Group {
                    switch entry.configuration.mode {
                    case .time:
                        TimeWatch(size: size, matchZeroRingGap: false, displaySubquarter: false, compact: true, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: 1.5)
                    case .date:
                        DateWatch(size: size, displaySolarTerms: false, compact: true, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: 1.5)
                    }
                }
                .containerBackground(backColor, for: .widget)
                .padding(.vertical, 0.5 * (proxy.size.height - size.height))
                .padding(.horizontal, 0.5 * (proxy.size.width - size.width))

            case .systemMedium, .systemExtraLarge:
#if os(visionOS)
                let isLarge = false
#else
                let isLarge = widgetFamily == .systemExtraLarge
#endif

                let size = CGSize(width: proxy.size.height * 0.95, height: proxy.size.height * 0.95)
                let gapSize = (proxy.size.width - proxy.size.height * 2) * 0.5
                HStack(spacing: gapSize) {
                    switch entry.configuration.mode {
                    case .time:
                        TimeWatch(size: size, matchZeroRingGap: isLarge, displaySubquarter: false, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                        DateWatch(size: size, displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                    case .date:
                        DateWatch(size: size, displaySolarTerms: isLarge, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                        TimeWatch(size: size, matchZeroRingGap: isLarge, displaySubquarter: false, compact: !isLarge, watchLayout: entry.watchLayout, markSize: 1.5, chineseCalendar: entry.chineseCalendar, highlightType: .alwaysOn, widthScale: isLarge ? 1.1 : 1.5)
                    }
                }
                .padding(.vertical, 0.5 * (proxy.size.height - size.height))
                .padding(.horizontal, 0.5 * (proxy.size.width - size.width * 2 - gapSize))
                .containerBackground(backColor, for: .widget)

            default:
                EmptyView()
            }
        }
    }
}

struct DualWatchWidget: Widget {
    static let kind: String = "Dual"
#if os(visionOS)
    static let supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium]
#else
    static let supportedFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemExtraLarge]
#endif

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: DualWatchProvider.Intent.self, provider: DualWatchProvider()) { entry in
            DualWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable()
        .configurationDisplayName("WGT_SPLIT_WATCH")
        .description("WGT_SPLIT_WATCH_MSG")
        .supportedFamilies(Self.supportedFamilies)
#if os(visionOS) || os(iOS)
        .supportedMountingStyles([.elevated, .recessed])
#endif
    }
}

#Preview("Small Date", as: .systemSmall, using: {
    let intent = DualWatchProvider.Intent()
    intent.calendarConfig = .ConfigQuery().defaultResult()
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
    intent.calendarConfig = .ConfigQuery().defaultResult()
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
    intent.calendarConfig = .ConfigQuery().defaultResult()
    intent.mode = .time
    intent.backAlpha = 0.2
    return intent
}(), widget: {
    DualWatchWidget()
}, timelineProvider: {
    DualWatchProvider()
})
