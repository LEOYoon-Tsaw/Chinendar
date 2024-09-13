//
//  CountDown.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
import WidgetKit

enum EventType: String, AppEnum {
    case solarTerms, lunarPhases, sunriseSet, moonriseSet

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "時計掛件選項")
    static let caseDisplayRepresentations: [EventType: DisplayRepresentation] = [
        .solarTerms: .init(title: "太陽節氣"),
        .lunarPhases: .init(title: "月相"),
        .sunriseSet: .init(title: "日躔"),
        .moonriseSet: .init(title: "月離")
    ]
}

struct CountDownConfiguration: ChinendarWidgetConfigIntent {
    static let title: LocalizedStringResource = "時計"
    static let description = IntentDescription("距離次事件之倒計時")

    @Parameter(title: "選日曆")
    var calendarConfig: ConfigIntent?
    @Parameter(title: "目的", default: .solarTerms)
    var target: EventType

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$calendarConfig
            \.$target
        }
    }
}

struct CountDownProvider: ChinendarAppIntentTimelineProvider {
    typealias Entry = CountDownEntry
    typealias Intent = CountDownConfiguration

    func nextEntryDates(chineseCalendar: ChineseCalendar, config: CountDownConfiguration, context: Context) -> [Date] {
        let allTimes = switch config.target {
        case .moonriseSet:
            nextMoonTimes(chineseCalendar: chineseCalendar)
        case .sunriseSet:
            nextSunTimes(chineseCalendar: chineseCalendar)
        case .lunarPhases:
            nextMoonPhase(chineseCalendar: chineseCalendar)
        case .solarTerms:
            nextSolarTerm(chineseCalendar: chineseCalendar)
        }
        return if allTimes.count > 0 {
            allTimes
        } else {
            [chineseCalendar.startOfNextDay]
        }
    }

    func recommendations() -> [AppIntentRecommendation<Intent>] {
        let solarTerms = { let intent = Intent(); intent.target = .solarTerms; return intent }()
        let lunarPhases = { let intent = Intent(); intent.target = .lunarPhases; return intent }()
        let sunriseSet = { let intent = Intent(); intent.target = .sunriseSet; return intent }()
        let moonriseSet = { let intent = Intent(); intent.target = .moonriseSet; return intent }()

        return [
            AppIntentRecommendation(intent: solarTerms, description: "次節氣"),
            AppIntentRecommendation(intent: lunarPhases, description: "次月相"),
            AppIntentRecommendation(intent: sunriseSet, description: "日出入"),
            AppIntentRecommendation(intent: moonriseSet, description: "月出入")
        ]
    }
    
    func relevances() async -> WidgetRelevance<Intent> {
        let asyncModels = await AsyncModels()
        
        async let sunTimes = nextSunTimes(chineseCalendar: asyncModels.chineseCalendar)
        async let moonTimes = nextMoonTimes(chineseCalendar: asyncModels.chineseCalendar)
        async let solarTerms = nextSolarTerm(chineseCalendar: asyncModels.chineseCalendar)
        async let moonPhases = nextMoonPhase(chineseCalendar: asyncModels.chineseCalendar)

        var relevantIntents = [WidgetRelevanceAttribute<Entry.Intent>]()

        for date in await sunTimes {
            let config = Intent()
            config.target = .sunriseSet
            let relevantContext = RelevantContext.date(from: date - 3600, to: date + 900)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in await moonTimes {
            let config = Intent()
            config.target = .moonriseSet
            let relevantContext = RelevantContext.date(from: date - 3600, to: date + 900)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in await solarTerms {
            let config = Intent()
            config.target = .solarTerms
            var solarTermDate = asyncModels.chineseCalendar
            solarTermDate.update(time: date)
            let relevantContext = RelevantContext.date(from: solarTermDate.startOfDay, to: solarTermDate.startOfNextDay)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }

        for date in await moonPhases {
            let config = Intent()
            config.target = .lunarPhases
            var lunarPhaseDate = asyncModels.chineseCalendar
            lunarPhaseDate.update(time: date)
            let relevantContext = RelevantContext.date(from: lunarPhaseDate.startOfDay, to: lunarPhaseDate.startOfNextDay)
            let relevantIntent = WidgetRelevanceAttribute(configuration: config, context: relevantContext)
            relevantIntents.append(relevantIntent)
        }
        
        return WidgetRelevance(relevantIntents)
    }
}

struct CountDownEntry: TimelineEntry, ChinendarEntry {
    let date: Date
    let configuration: CountDownProvider.Intent
    let chineseCalendar: ChineseCalendar
    let watchLayout: WatchLayout
    let previousDate: ChineseCalendar.NamedDate?
    let nextDate: ChineseCalendar.NamedDate?
    let color: CGColor
    let barColor: CGColor

    init(configuration: CountDownProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        let baseLayout = watchLayout.baseLayout
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        
        switch configuration.target {
        case .lunarPhases:
            self.date = chineseCalendar.startOfNextDay
            (previousDate, nextDate) = find(in: chineseCalendar.moonPhases, at: chineseCalendar.time)
            if let nextDate {
                color = if nextDate.name == ChineseCalendar.moonPhases.newmoon {
                    baseLayout.eclipseIndicator
                } else {
                    baseLayout.fullmoonIndicator
                }
                barColor = if nextDate.name == ChineseCalendar.moonPhases.newmoon { // New moon
                    baseLayout.secondRing.interpolate(at: chineseCalendar.eventInMonth.eclipse.first?.pos ?? 0.0)
                } else { // Full moon
                    baseLayout.secondRing.interpolate(at: chineseCalendar.eventInMonth.fullMoon.first?.pos ?? 0.5)
                }
            } else {
                color = baseLayout.fullmoonIndicator
                barColor = CGColor(gray: 0, alpha: 0)
            }

        case .solarTerms:
            self.date = chineseCalendar.startOfNextDay
            (previousDate, nextDate) = find(in: chineseCalendar.solarTerms, at: chineseCalendar.time)
            if let nextDate, let _ = previousDate {
                color = ChineseCalendar.evenSolarTermChinese.contains(nextDate.name) ? baseLayout.evenStermIndicator : baseLayout.oddStermIndicator
                barColor = {
                    let yearStart = chineseCalendar.solarTerms[0].date
                    let yearEnd = chineseCalendar.solarTerms[24].date
                    return baseLayout.firstRing.interpolate(at: yearStart.distance(to: nextDate.date) / yearStart.distance(to: yearEnd))
                }()
            } else {
                color = baseLayout.evenStermIndicator
                barColor = CGColor(gray: 0, alpha: 0)
            }

        case .moonriseSet:
            var chineseCalendar = chineseCalendar
            self.date = chineseCalendar.time + 1800 // Half Hour
            let current = chineseCalendar.getMoonTimes(for: .current)
            let previous = chineseCalendar.getMoonTimes(for: .previous)
            let next = chineseCalendar.getMoonTimes(for: .next)
            let moonriseAndSet = [previous.moonrise, previous.moonset, current.moonrise, current.moonset, next.moonrise, next.moonset].compactMap { $0 }
            (previousDate, nextDate) = find(in: moonriseAndSet, at: chineseCalendar.time)
            if let nextDate {
                color = if nextDate.name == ChineseCalendar.moonTimeName.moonrise {
                    baseLayout.moonPositionIndicator.moonrise
                } else {
                    baseLayout.moonPositionIndicator.moonset
                }
                barColor = if nextDate.name == ChineseCalendar.moonTimeName.moonrise { // Moonrise
                    baseLayout.secondRing.interpolate(at: chineseCalendar.sunMoonPositions.lunar.moonrise?.pos ?? 0.25)
                } else { // Moonset
                    baseLayout.secondRing.interpolate(at: chineseCalendar.sunMoonPositions.lunar.moonset?.pos ?? 0.75)
                }
            } else {
                color = baseLayout.moonPositionIndicator.highMoon
                barColor = CGColor(gray: 0, alpha: 0)
            }

        case .sunriseSet:
            var chineseCalendar = chineseCalendar
            self.date = chineseCalendar.time + 1800 // Half Hour
            let current = chineseCalendar.getSunTimes(for: .current)
            let previous = chineseCalendar.getSunTimes(for: .previous)
            let next = chineseCalendar.getSunTimes(for: .next)
            let sunriseAndSet = [previous.sunrise, previous.sunset, current.sunrise, current.sunset, next.sunrise, next.sunset].compactMap { $0 }
            (previousDate, nextDate) = find(in: sunriseAndSet, at: chineseCalendar.time)
            if let nextDate {
                color = if nextDate.name == ChineseCalendar.dayTimeName.sunrise {
                    baseLayout.sunPositionIndicator.sunrise
                } else {
                    baseLayout.sunPositionIndicator.sunset
                }
                barColor = if nextDate.name == ChineseCalendar.dayTimeName.sunrise { // Sunrise
                    baseLayout.thirdRing.interpolate(at: chineseCalendar.sunMoonPositions.solar.sunrise?.pos ?? 0.25)
                } else { // Sunset
                    baseLayout.thirdRing.interpolate(at: chineseCalendar.sunMoonPositions.solar.sunset?.pos ?? 0.75)
                }
            } else {
                color = baseLayout.sunPositionIndicator.noon
                barColor = CGColor(gray: 0, alpha: 0)
            }
        }
    }
}

struct CountDownEntryView: View {
    var entry: CountDownEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch entry.configuration.target {
        case .solarTerms:
            if let next = entry.nextDate, let previous = entry.previousDate {
                let index = findSolarTerm(next.name)
                if index >= 0 {
                    let icon = IconType.solarTerm(view: SolarTerm(angle: CGFloat(index) / 24.0, color: entry.color))

                    switch family {
                    case .accessoryRectangular:
                        RectanglePanel(icon: icon, name: Text(Locale.translate(next.name)), color: entry.color, start: previous.date, end: next.date)
                    case .accessoryCorner:
                        Curve(icon: icon, barColor: entry.barColor, start: previous.date, end: next.date)
                    default:
                        EmptyView()
                    }
                }
            }
        case .lunarPhases:
            if let next = entry.nextDate, let previous = entry.previousDate {
                let icon = IconType.moon(view: MoonPhase(angle: next.name == ChineseCalendar.moonPhases.newmoon ? 0.05 : 0.5, color: entry.color))

                switch family {
                case .accessoryRectangular:
                    RectanglePanel(icon: icon, name: Text(Locale.translate(next.name)), color: entry.color, start: previous.date, end: next.date)
                case .accessoryCorner:
                    Curve(icon: icon, barColor: entry.barColor,
                          start: previous.date, end: next.date)
                default:
                    EmptyView()
                }
            }

        case .sunriseSet:
            var chineseCalendar = entry.chineseCalendar
            let noonTime = chineseCalendar.getSunTimes(for: .current).noon
            if let next = entry.nextDate, let previous = entry.previousDate {
                let icon = IconType.sunrise(view: Sun(color: entry.color, rise: next.name == ChineseCalendar.dayTimeName.sunrise))

                switch family {
                case .accessoryRectangular:
                    RectanglePanel(icon: icon, name: Text(Locale.translate(next.name)), color: entry.color, start: previous.date, end: next.date)
                case .accessoryCorner:
                    Curve(icon: icon, barColor: entry.barColor, start: previous.date, end: next.date)
                default:
                    EmptyView()
                }

            } else {
                let icon = IconType.sunrise(view: Sun(color: entry.color, rise: nil))

                switch family {
                case .accessoryRectangular:
                    let sunDescription = if entry.chineseCalendar.location != nil {
                        if noonTime != nil {
                            Text("永日", comment: "Sun never set")
                        } else {
                            Text("永夜", comment: "Sun never rise")
                        }
                    } else {
                        Text("太陽", comment: "Sun can not be located")
                    }
                    RectanglePanel(icon: icon, name: sunDescription, color: entry.color)
                case .accessoryCorner:
                    Curve(icon: icon, barColor: entry.barColor, start: nil, end: nil)
                default:
                    EmptyView()
                }
            }
        case .moonriseSet:
            var chineseCalendar = entry.chineseCalendar
            let highMoonTime = chineseCalendar.getMoonTimes(for: .current).highMoon
            if let next = entry.nextDate, let previous = entry.previousDate {
                let icon = IconType.moon(view: MoonPhase(angle: entry.chineseCalendar.currentDayInMonth, color: entry.color, rise: next.name == ChineseCalendar.moonTimeName.moonrise))

                switch family {
                case .accessoryRectangular:
                    RectanglePanel(icon: icon, name: Text(Locale.translate(next.name)), color: entry.color, start: previous.date, end: next.date)
                case .accessoryCorner:
                    Curve(icon: icon, barColor: entry.barColor,
                          start: previous.date, end: next.date)
                default:
                    EmptyView()
                }
            } else {
                let icon = IconType.moon(view: MoonPhase(angle: entry.chineseCalendar.currentDayInMonth, color: entry.color, rise: nil))

                switch family {
                case .accessoryRectangular:
                    let moonDescription = if entry.chineseCalendar.location != nil {
                        if highMoonTime != nil {
                            Text("永月", comment: "Moon never set")
                        } else {
                            Text("永無月", comment: "Moon never rise")
                        }
                    } else {
                        Text("太陰", comment: "Moon can not be located")
                    }
                    RectanglePanel(icon: icon, name: moonDescription, color: entry.color)
                case .accessoryCorner:
                    Curve(icon: icon, barColor: entry.barColor,
                          start: nil, end: nil)
                default:
                    EmptyView()
                }
            }
        }
    }

    private func findSolarTerm(_ solarTerm: String) -> Int {
        if let even = ChineseCalendar.evenSolarTermChinese.firstIndex(of: solarTerm) {
            return even * 2
        } else if let odd = ChineseCalendar.oddSolarTermChinese.firstIndex(of: solarTerm) {
            return odd * 2 + 1
        } else {
            return -1
        }
    }
}

struct RectWidget: Widget {
    static let kind: String = "Card"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: CountDownProvider.Intent.self, provider: CountDownProvider()) { entry in
            CountDownEntryView(entry: entry)
                .containerBackground(Material.ultraThin, for: .widget)
        }
        .containerBackgroundRemovable()
        .configurationDisplayName("時計片")
        .description("距離次事件之倒計時片")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview("Lunar Phase", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.target = .lunarPhases
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}

#Preview("Solar Term", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.target = .solarTerms
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}

#Preview("Sunrise", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.target = .sunriseSet
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}

#Preview("Moonrise", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.calendarConfig = .init(id: AppInfo.defaultName)
    intent.target = .moonriseSet
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}
