//
//  Event.swift
//  Chinendar
//
//  Created by Leo Liu on 11/1/26.
//

import AppIntents
import SwiftUI
import WidgetKit

struct NavigateEventIntent: AppIntent {
    static let title: LocalizedStringResource = "NAV_EVENT_INTENT"
    static let supportedModes: IntentModes = .background

    @Parameter(title: "FORWARD")
    var forward: Bool
    @Parameter(title: "EVENT_TYPE")
    var nextEventType: NextEventType

    init() {}

    init(forward: Bool, type: NextEventType) {
        self.forward = forward
        self.nextEventType = type
    }

    func perform() async throws -> some IntentResult {
        try await LocalDataModel.shared.updateEventWidgetStatus(type: nextEventType, forward: forward)
        return .result()
    }
}

struct EventConfiguration: ChinendarCountDownConfigIntent {
    static let title: LocalizedStringResource = "WGT_COUNTDOWN"
    static let description = IntentDescription("WGT_COUNTDOWN_MSG")

    @Parameter(title: "SELECT_CALENDAR")
    var calendarConfig: ConfigIntent?
    @Parameter(title: "SELECT_THEME")
    var calendarTheme: ThemeIntent?
    @Parameter(title: "CHINENDAR_DISPLAY_IN_NATIVE", default: nil)
    var nativeLanguage: Bool?
    @Parameter(title: "EVENT_TYPE", default: .solarTerms)
    var target: NextEventType

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$target
            \.$nativeLanguage
            \.$calendarConfig
            \.$calendarTheme
        }
    }
}

struct EventProvider: ChinendarCountDownProvider {
    typealias Entry = EventEntry
    typealias Intent = EventConfiguration

    func timeline(for configuration: Entry.Intent, in context: Context) async -> Timeline<Entry> {
        let asyncModel = await AsyncLocalModels(compact: compactCalendar(context: context), config: configuration.calendarConfig?.config, theme: configuration.calendarTheme?.theme)
        let status = await LocalDataModel.shared.getEventWidgetStatus(type: configuration.target)

        var chineseCalendar = asyncModel.chineseCalendar
        var entries: [Entry] = []
        if let shiftedEntry = navigationEntry(chineseCalendar: asyncModel.chineseCalendar, layout: asyncModel.layout, config: configuration, status: status) {
            // Resume the real calendar at expiry, even when the selected event is far away.
            chineseCalendar.update(time: status.expirationDate)
            entries.append(shiftedEntry)
        }

        let entryDates = nextEntryDates(chineseCalendar: chineseCalendar, config: configuration, context: context).filter { $0 > chineseCalendar.time }
        await entries.append(contentsOf: generateEntries(baseChineseCalendar: chineseCalendar, timeline: entryDates, watchLayout: asyncModel.layout, configuration: configuration))
        return Timeline(entries: entries, policy: .atEnd)
    }

    func nextEntryDates(chineseCalendar: ChineseCalendar, config: Entry.Intent, context: Context) -> [Date] {
        let allTimes = switch config.target {
        case .moonriseSet:
            nextMoonTimes(chineseCalendar: chineseCalendar)
        case .sunriseSet:
            nextSunTimes(chineseCalendar: chineseCalendar)
        case .lunarPhases, .solarTerms, .chineseHoliday:
            [next(config.target, in: chineseCalendar, chronological: true).next?.date].compactMap { $0 }
        }
        return if allTimes.count > 0 {
            allTimes
        } else {
            [chineseCalendar.startOfNextDay]
        }
    }

    private func navigationEntry(chineseCalendar: ChineseCalendar, layout: WatchLayout, config: Entry.Intent, status: NextEventStatus) -> Entry? {
        guard status.isActive(at: chineseCalendar.time), let anchorTime = status.anchorTime else { return nil }
        var selectedCalendar = chineseCalendar
        selectedCalendar.update(time: anchorTime)
        var step = status.step
        let direction = step.signum()
        while step != 0 {
            let (previousDate, nextDate) = next(config.target, in: selectedCalendar, chronological: true)
            guard let event = direction > 0 ? nextDate : previousDate else { break }
            selectedCalendar.update(time: event.date + TimeInterval(direction))
            step -= direction
        }
        return Entry(configuration: config, chineseCalendar: selectedCalendar, watchLayout: layout, date: chineseCalendar.time, offset: status.step)
    }
}

struct EventEntry: TimelineEntry, ChinendarEntry {
    let date: Date
    let configuration: EventProvider.Intent
    let chineseCalendar: ChineseCalendar
    let previousDate: ChineseCalendar.NamedDate?
    let nextDate: ChineseCalendar.NamedDate?
    let backgroundColor: Color
    let description: String
    let offset: Int
    let color: Color?

    static private let formatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = Locale.current
        return formatter
    }()

    init(configuration: EventProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        self.init(configuration: configuration, chineseCalendar: chineseCalendar, watchLayout: watchLayout, date: chineseCalendar.time, offset: 0)
    }

    init(configuration: EventProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout, date: Date, offset: Int) {
        let baseLayout = watchLayout.baseLayout
        self.date = date
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.offset = offset
        let nativeLanguage = configuration.nativeLanguage ?? baseLayout.nativeLanguage

        (previousDate, nextDate) = next(configuration.target, in: chineseCalendar, chronological: true)

        switch configuration.target {
        case .solarTerms:
            if let event = nextDate?.name {
                let type: LocalizedStringResource
                let index: Int
                if let idx = ChineseCalendar.oddSolarTermChinese.firstIndex(of: event) {
                    type = "ODD_ST_SIMP"
                    index = (2 * idx + 4) % 24
                } else if let idx = ChineseCalendar.evenSolarTermChinese.firstIndex(of: event) {
                    type = "EVEN_ST_SIMP"
                    index = (2 * idx + 3) % 24
                } else {
                    type = ""
                    index = -1
                }
                let season: [LocalizedStringResource] = ["WINTER", "SPRING", "SUMMER", "AUTUMN"]
                let ordinal = Self.formatter.string(from: NSNumber(integerLiteral: (index % 6) + 1)) ?? String((index % 6) + 1)
                description = String(localized: "ST_TYPE\(type)SEASON\(season[index / 6])NUM\(ordinal)")
            } else {
                description = ""
            }
            color = nil
        case .lunarPhases, .chineseHoliday:
            if let eventTime = nextDate?.date {
                var eventCalendar = chineseCalendar
                eventCalendar.update(time: eventTime)
                description = if nativeLanguage {
                    String(localized: eventCalendar.dateStringLocalized)
                } else {
                    eventCalendar.dateString
                }
            } else {
                description = ""
            }
            color = nil
        case .sunriseSet:
            if let nextDate {
                var eventCalendar = chineseCalendar
                eventCalendar.update(time: nextDate.date)
                description = if nativeLanguage {
                    String(localized: "DAY:\(eventCalendar.dateStringLocalized),TIME:\(eventCalendar.timeStringLocalized)")
                } else {
                    "\(eventCalendar.dateString) \(eventCalendar.timeString)"
                }
                color = if nextDate.name == ChineseCalendar.dayTimeName.sunrise {
                    baseLayout.colors.sunPositionIndicator.sunrise.color
                } else {
                    baseLayout.colors.sunPositionIndicator.sunset.color
                }
            } else {
                description = ""
                color = nil
            }
        case .moonriseSet:
            if let nextDate {
                var eventCalendar = chineseCalendar
                eventCalendar.update(time: nextDate.date)
                description = if nativeLanguage {
                    String(localized: "DAY:\(eventCalendar.dateStringLocalized),TIME:\(eventCalendar.timeStringLocalized)")
                } else {
                    "\(eventCalendar.dateString) \(eventCalendar.timeString)"
                }
                color = if nextDate.name == ChineseCalendar.moonTimeName.moonrise {
                    baseLayout.colors.moonPositionIndicator.moonrise.color
                } else {
                    baseLayout.colors.sunPositionIndicator.sunset.color
                }
            } else {
                description = ""
                color = nil
            }
        }

        if let nextDate {
            backgroundColor = EventIconResource(name: nextDate.name, category: configuration.target).backgroundColor
        } else {
            backgroundColor = .clear
        }
    }
}

struct EventEntryView: View {
    var entry: EventEntry

    var body: some View {
        switch entry.configuration.target {
        case .solarTerms, .lunarPhases, .chineseHoliday:
            if let next = entry.nextDate, let previous = entry.previousDate {
                let icon = IconType.globalEvent(view: GlobalEventIcon(name: next.name, category: entry.configuration.target))
                EventCardView(icon: icon, name: Text(Locale.translate(next.name)), desc: entry.description, offset: entry.offset, backColor: entry.backgroundColor, start: previous.date, end: next.date, type: entry.configuration.target)
            }

        case .sunriseSet, .moonriseSet:
            if let kind = astronomyKind(target: entry.configuration.target, previousDate: entry.previousDate, nextDate: entry.nextDate, chineseCalendar: entry.chineseCalendar) {
                let icon = IconType.localEvent(view: LocalEventIcon(name: kind, color: entry.color ?? .black, phase: entry.configuration.target == .moonriseSet ? entry.chineseCalendar.currentDayInMonth : nil))
                let description = if let next = entry.nextDate {
                    Locale.translate(next.name)
                } else {
                    Locale.translate(kind)
                }
                EventCardView(icon: icon, name: Text(description), desc: entry.description, offset: entry.offset, backColor: entry.backgroundColor, start: entry.previousDate?.date, end: entry.nextDate?.date, type: entry.configuration.target)
            }
        }
    }
}

struct EventCardView: View {
    let icon: IconType
    let name: Text
    let desc: String
    let offset: Int
    let backColor: Color
    let start: Date?
    let end: Date?
    let type: NextEventType
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                if widgetRenderingMode == .fullColor {
                    backColor
                } else {
                    Color.white.opacity(0.2)
                }
                switch icon {
                case .globalEvent(view: let view):
                    view
                case .localEvent(view: let view):
                    view
                }
            }
            .scaledToFit()
            .clipShape(.circle)
            .widgetAccentable()
            .padding(.vertical)

            Spacer(minLength: 20)

            VStack(alignment: .leading) {
                name
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .minimumScaleFactor(0.5)
                Spacer()
                    .frame(maxHeight: 6)
                if !desc.isEmpty {
                    Text(desc)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fontDesign(.rounded)
                        .minimumScaleFactor(0.5)
                }
                if start != nil, let end {
                    Text(end.formatted(.relative(presentation: .numeric, unitsStyle: .wide)))
                        .fontDesign(.rounded)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(.secondary)
                } else {
                    Text("UNKNOWN_TIME")
                        .fontDesign(.rounded)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button(intent: NavigateEventIntent(forward: false, type: type)) {
                            Label("PREV_IN_EVENT", systemImage: "chevron.backward")
                        }
                    if offset != 0 {
                        Spacer(minLength: 0)
                        Text(String("\(offset > 0 ? "+" : "-")\(abs(offset))"))
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer(minLength: 0)
                    Button(intent: NavigateEventIntent(forward: true, type: type)) {
                            Label("NEXT_IN_EVENT", systemImage: "chevron.forward")
                            .labelStyle(TrailingIconLabelStyle())
                        }
                }
                .tint(.accentColor)
            }
            .frame(maxWidth: .infinity)
            .widgetAccentable()
        }
        .containerBackground(.background, for: .widget)
    }
}

struct EventWidget: Widget {
    static let kind: String = "Event"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: EventProvider.Intent.self, provider: EventProvider()) { entry in
            EventEntryView(entry: entry)
        }
        .containerBackgroundRemovable()
        .configurationDisplayName("WGT_COUNTDOWN_LARGE")
        .description("WGT_COUNTDOWN_LARGE_MSG")
        .supportedFamilies([.systemMedium])
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

#if DEBUG
#Preview("Lunar Phase", as: .systemMedium, using: {
    let intent = EventProvider.Intent()
    intent.target = .lunarPhases
    return intent
}()) {
    EventWidget()
} timelineProvider: {
    EventProvider()
}

#Preview("Solar Term", as: .systemMedium, using: {
    let intent = EventProvider.Intent()
    intent.target = .solarTerms
    return intent
}()) {
    EventWidget()
} timelineProvider: {
    EventProvider()
}

#Preview("Sunrise", as: .systemMedium, using: {
    let intent = EventProvider.Intent()
    intent.target = .sunriseSet
    intent.calendarConfig = .preview
    return intent
}()) {
    EventWidget()
} timelineProvider: {
    EventProvider()
}

#Preview("Moonrise", as: .systemMedium, using: {
    let intent = EventProvider.Intent()
    intent.target = .moonriseSet
    intent.calendarConfig = .preview
    return intent
}()) {
    EventWidget()
} timelineProvider: {
    EventProvider()
}

#Preview("Holidays", as: .systemMedium, using: {
    let intent = EventProvider.Intent()
    intent.target = .chineseHoliday
    return intent
}()) {
    EventWidget()
} timelineProvider: {
    EventProvider()
}
#endif
