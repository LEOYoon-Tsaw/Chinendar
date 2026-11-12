//
//  CountDown.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
import WidgetKit

struct CountDownConfiguration: ChinendarCountDownConfigIntent {
    static let title: LocalizedStringResource = "WGT_COUNTDOWN"
    static let description = IntentDescription("WGT_COUNTDOWN_MSG")

    @Parameter(title: "SELECT_CALENDAR")
    var calendarConfig: ConfigIntent?
    @Parameter(title: "SELECT_THEME")
    var calendarTheme: ThemeIntent?
    @Parameter(title: "EVENT_TYPE", default: .solarTerms)
    var target: NextEventType

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$target
            \.$calendarConfig
            \.$calendarTheme
        }
    }
}

struct CountDownProvider: ChinendarCountDownProvider {
    typealias Entry = CountDownEntry
    typealias Intent = CountDownConfiguration

    func nextEntryDates(chineseCalendar: ChineseCalendar, config: Intent, context: Context) -> [Date] {
        let allTimes = switch config.target {
        case .moonriseSet:
            nextMoonTimes(chineseCalendar: chineseCalendar)
        case .sunriseSet:
            nextSunTimes(chineseCalendar: chineseCalendar)
        case .lunarPhases:
            nextMoonPhase(chineseCalendar: chineseCalendar)
        case .solarTerms:
#if DEBUG
            chineseCalendar.solarTerms[..<24].map { $0.date }
#else
            nextSolarTerm(chineseCalendar: chineseCalendar)
#endif
        case .chineseHoliday:
#if DEBUG
            chineseCalendar.lunarHolidays.map { $0.date }
#else
            nextChineseHoliday(chineseCalendar: chineseCalendar)
#endif
        }
        return if allTimes.count > 0 {
            allTimes
        } else {
            [chineseCalendar.startOfNextDay]
        }
    }
}

struct CountDownEntry: TimelineEntry, ChinendarEntry {
    let date: Date
    let configuration: CountDownProvider.Intent
    let chineseCalendar: ChineseCalendar
    let previousDate: ChineseCalendar.NamedDate?
    let nextDate: ChineseCalendar.NamedDate?
    let color: Color
    let barColor: Color
    let backgroundColor: Color

    init(configuration: CountDownProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        let baseLayout = watchLayout.baseLayout
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar

        (previousDate, nextDate) = next(configuration.target, in: chineseCalendar)

        switch configuration.target {
        case .lunarPhases:
            self.date = chineseCalendar.startOfNextDay
            if let nextDate {
                color = if nextDate.name == ChineseCalendar.moonPhases.newmoon {
                    baseLayout.colors.monthlyIndicators.newMoon.color
                } else {
                    baseLayout.colors.monthlyIndicators.fullMoon.color
                }
                barColor = if nextDate.name == ChineseCalendar.moonPhases.newmoon { // New moon
                    Color(cgColor: baseLayout.colors.secondRing.interpolate(at: chineseCalendar.eventInMonth.eclipse.first?.pos ?? 0.0))
                } else { // Full moon
                    Color(cgColor: baseLayout.colors.secondRing.interpolate(at: chineseCalendar.eventInMonth.fullMoon.first?.pos ?? 0.5))
                }
            } else {
                color = baseLayout.colors.monthlyIndicators.fullMoon.color
                barColor = .clear
            }

        case .solarTerms:
            self.date = chineseCalendar.startOfNextDay
            if let nextDate, previousDate != nil {
                let yearStart = chineseCalendar.solarTerms[0].date
                let yearEnd = chineseCalendar.solarTerms[24].date
                color = ChineseCalendar.evenSolarTermChinese.contains(nextDate.name) ? baseLayout.colors.monthlyIndicators.evenSolarTerm.color : baseLayout.colors.monthlyIndicators.oddSolarTerm.color
                barColor = Color(cgColor: baseLayout.colors.firstRing.interpolate(at: yearStart.distance(to: nextDate.date) / yearStart.distance(to: yearEnd)))
            } else {
                color = baseLayout.colors.monthlyIndicators.evenSolarTerm.color
                barColor = .clear
            }

        case .chineseHoliday:
            self.date = chineseCalendar.startOfNextDay
            if let nextDate, previousDate != nil {
                let yearStart = chineseCalendar.solarTerms[0].date
                let yearEnd = chineseCalendar.solarTerms[24].date
                color = Color(cgColor: baseLayout.colors.firstRing.interpolate(at: yearStart.distance(to: nextDate.date) / yearStart.distance(to: yearEnd)))
                barColor = baseLayout.colors.firstRing.colors.first.map {Color(cgColor: $0)} ?? Color.clear
            } else {
                color = baseLayout.colors.firstRing.colors.first.map {Color(cgColor: $0)} ?? Color.white
                barColor = .clear
            }

        case .moonriseSet:
            var chineseCalendar = chineseCalendar
            self.date = chineseCalendar.time + 1800 // Half Hour
            if let nextDate {
                color = if nextDate.name == ChineseCalendar.moonTimeName.moonrise {
                    baseLayout.colors.moonPositionIndicator.moonrise.color
                } else {
                    baseLayout.colors.moonPositionIndicator.moonset.color
                }
                barColor = if nextDate.name == ChineseCalendar.moonTimeName.moonrise { // Moonrise
                    Color(cgColor: baseLayout.colors.secondRing.interpolate(at: chineseCalendar.sunMoonPositions.lunar.moonrise?.pos ?? 0.25))
                } else { // Moonset
                    Color(cgColor: baseLayout.colors.secondRing.interpolate(at: chineseCalendar.sunMoonPositions.lunar.moonset?.pos ?? 0.75))
                }
            } else {
                color = baseLayout.colors.moonPositionIndicator.highMoon.color
                barColor = .clear
            }

        case .sunriseSet:
            var chineseCalendar = chineseCalendar
            self.date = chineseCalendar.time + 1800 // Half Hour
            if let nextDate {
                color = if nextDate.name == ChineseCalendar.dayTimeName.sunrise {
                    baseLayout.colors.sunPositionIndicator.sunrise.color
                } else {
                    baseLayout.colors.sunPositionIndicator.sunset.color
                }
                barColor = if nextDate.name == ChineseCalendar.dayTimeName.sunrise { // Sunrise
                    Color(cgColor: baseLayout.colors.thirdRing.interpolate(at: chineseCalendar.sunMoonPositions.solar.sunrise?.pos ?? 0.25))
                } else { // Sunset
                    Color(cgColor: baseLayout.colors.thirdRing.interpolate(at: chineseCalendar.sunMoonPositions.solar.sunset?.pos ?? 0.75))
                }
            } else {
                color = baseLayout.colors.sunPositionIndicator.noon.color
                barColor = .clear
            }
        }

        if let nextDate {
            backgroundColor = EventIconResource(name: nextDate.name, category: configuration.target).backgroundColor
        } else {
            if let kind = astronomyKind(target: configuration.target, previousDate: previousDate, nextDate: nextDate, chineseCalendar: chineseCalendar) {
                backgroundColor = EventIconResource(name: kind, category: configuration.target).backgroundColor
            } else {
                backgroundColor = .clear
            }
        }
    }
}

struct CountDownEntryView: View {
    var entry: CountDownEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch entry.configuration.target {
        case .solarTerms, .lunarPhases, .chineseHoliday:
            if let next = entry.nextDate, let previous = entry.previousDate {
                let icon = IconType.globalEvent(view: GlobalEventIcon(name: next.name, category: entry.configuration.target))

                switch family {
                case .accessoryRectangular:
                    RectanglePanel(icon: icon, name: Text(Locale.translate(next.name)), color: entry.color, start: previous.date, end: next.date)
                case .accessoryCorner:
                    Curve(icon: icon, barColor: entry.barColor, start: previous.date, end: next.date)
                default:
                    EmptyView()
                }
            }

        case .sunriseSet, .moonriseSet:
            if let kind = astronomyKind(target: entry.configuration.target, previousDate: entry.previousDate, nextDate: entry.nextDate, chineseCalendar: entry.chineseCalendar) {
                let icon = IconType.localEvent(view: LocalEventIcon(name: kind, color: entry.color, phase: entry.configuration.target == .moonriseSet ? entry.chineseCalendar.currentDayInMonth : nil))
                if let next = entry.nextDate, let previous = entry.previousDate {
                    switch family {
                    case .accessoryRectangular:
                        RectanglePanel(icon: icon, name: Text(Locale.translate(next.name)), color: entry.color, start: previous.date, end: next.date)
                    case .accessoryCorner:
                        Curve(icon: icon, barColor: entry.barColor, start: previous.date, end: next.date)
                    default:
                        EmptyView()
                    }
                } else {
                    switch family {
                    case .accessoryRectangular:
                        let description = Locale.translate(kind)
                        RectanglePanel(icon: icon, name: Text(description), color: entry.color)
                    case .accessoryCorner:
                        Curve(icon: icon, barColor: entry.barColor, start: nil, end: nil)
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct RectWidget: Widget {
    static let kind: String = "Card"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: CountDownProvider.Intent.self, provider: CountDownProvider()) { entry in
            CountDownEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    entry.backgroundColor
                }
        }
        .containerBackgroundRemovable()
        .configurationDisplayName("WGT_COUNTDOWN")
        .description("WGT_COUNTDOWN_MSG")
        .supportedFamilies([.accessoryRectangular])
    }
}

#if DEBUG
#Preview("Lunar Phase", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.target = .lunarPhases
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}

#Preview("Solar Term", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.target = .solarTerms
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}

#Preview("Sunrise", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.target = .sunriseSet
    intent.calendarConfig = .preview
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}

#Preview("Moonrise", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.target = .moonriseSet
    intent.calendarConfig = .preview
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}

#Preview("Holidays", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.target = .chineseHoliday
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}
#endif
