//
//  CountDown.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

struct CountDownProvider: ChinendarAppIntentTimelineProvider {
    typealias Entry = CountDownEntry
    typealias Intent = CountDownConfiguration
    let modelContext = DataSchema.context
    let locationManager = LocationManager()

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
}

private func find(in dates: [ChineseCalendar.NamedDate], at date: Date) -> (ChineseCalendar.NamedDate?, ChineseCalendar.NamedDate?) {
    if dates.count > 1 {
        let atDate = ChineseCalendar.NamedDate(name: "", date: date)
        let index = dates.insertionIndex(of: atDate, comparison: { $0.date < $1.date })
        if index > 0 && index < dates.count {
            let previous = dates[index - 1]
            let next = dates[index]
            if Date.now.distance(to: date) < 30 || previous.date.distance(to: date) < date.distance(to: next.date) {
                return (previous: previous, next: next)
            } else {
                return (previous: next, next: index+1 < dates.count ? dates[index + 1] : nil)
            }
        } else if index < dates.count {
            return (previous: nil, next: dates[index])
        } else {
            return (previous: dates[index - 1], next: nil)
        }
    } else {
        return (previous: nil, next: nil)
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
    let relevance: TimelineEntryRelevance?

    init(configuration: CountDownProvider.Intent, chineseCalendar: ChineseCalendar, watchLayout: WatchLayout) {
        self.configuration = configuration
        self.chineseCalendar = chineseCalendar
        self.watchLayout = watchLayout
        switch configuration.target {
        case .lunarPhases:
            self.date = chineseCalendar.startOfNextDay
            (previousDate, nextDate) = find(in: chineseCalendar.moonPhases, at: chineseCalendar.time)
            if let next = nextDate {
                color = if next.name == ChineseCalendar.moonPhases.newmoon {
                    watchLayout.eclipseIndicator
                } else {
                    watchLayout.fullmoonIndicator
                }
                barColor = if next.name == ChineseCalendar.moonPhases.newmoon { // New moon
                    watchLayout.secondRing.interpolate(at: chineseCalendar.eventInMonth.eclipse.first?.pos ?? 0.0)
                } else { // Full moon
                    watchLayout.secondRing.interpolate(at: chineseCalendar.eventInMonth.fullMoon.first?.pos ?? 0.5)
                }
                relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: next.date))
            } else {
                color = watchLayout.fullmoonIndicator
                barColor = CGColor(gray: 0, alpha: 0)
                relevance = TimelineEntryRelevance(score: 0)
            }

        case .solarTerms:
            self.date = chineseCalendar.startOfNextDay
            (previousDate, nextDate) = find(in: chineseCalendar.solarTerms, at: chineseCalendar.time)
            if let next = nextDate, let _ = previousDate {
                color = ChineseCalendar.evenSolarTermChinese.contains(next.name) ? watchLayout.evenStermIndicator : watchLayout.oddStermIndicator
                barColor = {
                    let yearStart = chineseCalendar.solarTerms[0].date
                    let yearEnd = chineseCalendar.solarTerms[24].date
                    return watchLayout.firstRing.interpolate(at: yearStart.distance(to: next.date) / yearStart.distance(to: yearEnd))
                }()
                relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: next.date))
            } else {
                color = watchLayout.evenStermIndicator
                barColor = CGColor(gray: 0, alpha: 0)
                relevance = TimelineEntryRelevance(score: 0)
            }

        case .moonriseSet:
            self.date = chineseCalendar.time + 1800 // Half Hour
            let current = chineseCalendar.getMoonTimes(for: .current)
            let previous = chineseCalendar.getMoonTimes(for: .previous)
            let next = chineseCalendar.getMoonTimes(for: .next)
            let moonriseAndSet = [previous.moonrise, previous.moonset, current.moonrise, current.moonset, next.moonrise, next.moonset].compactMap { $0 }
            (previousDate, nextDate) = find(in: moonriseAndSet, at: chineseCalendar.time)
            if let next = nextDate {
                color = if next.name == ChineseCalendar.moonTimeName.moonrise {
                    watchLayout.moonPositionIndicator.moonrise
                } else {
                    watchLayout.moonPositionIndicator.moonset
                }
                barColor = if next.name == ChineseCalendar.moonTimeName.moonrise { // Moonrise
                    watchLayout.secondRing.interpolate(at: chineseCalendar.sunMoonPositions.lunar.moonrise?.pos ?? 0.25)
                } else { // Moonset
                    watchLayout.secondRing.interpolate(at: chineseCalendar.sunMoonPositions.lunar.moonset?.pos ?? 0.75)
                }
                relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: next.date))
            } else {
                color = watchLayout.moonPositionIndicator.highMoon
                barColor = CGColor(gray: 0, alpha: 0)
                relevance = TimelineEntryRelevance(score: 0)
            }

        case .sunriseSet:
            self.date = chineseCalendar.time + 1800 // Half Hour
            let current = chineseCalendar.getSunTimes(for: .current)
            let previous = chineseCalendar.getSunTimes(for: .previous)
            let next = chineseCalendar.getSunTimes(for: .next)
            let sunriseAndSet = [previous.sunrise, previous.sunset, current.sunrise, current.sunset, next.sunrise, next.sunset].compactMap { $0 }
            (previousDate, nextDate) = find(in: sunriseAndSet, at: chineseCalendar.time)
            if let next = nextDate {
                color = if next.name == ChineseCalendar.dayTimeName.sunrise {
                    watchLayout.sunPositionIndicator.sunrise
                } else {
                    watchLayout.sunPositionIndicator.sunset
                }
                barColor = if next.name == ChineseCalendar.dayTimeName.sunrise { // Sunrise
                    watchLayout.thirdRing.interpolate(at: chineseCalendar.sunMoonPositions.solar.sunrise?.pos ?? 0.25)
                } else { // Sunset
                    watchLayout.thirdRing.interpolate(at: chineseCalendar.sunMoonPositions.solar.sunset?.pos ?? 0.75)
                }
                relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: next.date))
            } else {
                color = watchLayout.sunPositionIndicator.noon
                barColor = CGColor(gray: 0, alpha: 0)
                relevance = TimelineEntryRelevance(score: 0)
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
                        let name = String(next.name.replacingOccurrences(of: "　", with: ""))
                        RectanglePanel(icon: icon, name: Text(Locale.translation[name] ?? ""), color: entry.color, barColor: entry.barColor, start: previous.date, end: next.date)
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
                    RectanglePanel(icon: icon, name: Text(Locale.translation[next.name] ?? ""), color: entry.color, barColor: entry.barColor, start: previous.date, end: next.date)
                case .accessoryCorner:
                    Curve(icon: icon, barColor: entry.barColor,
                          start: previous.date, end: next.date)
                default:
                    EmptyView()
                }
            }

        case .sunriseSet:
            let noonTime = entry.chineseCalendar.getSunTimes(for: .current).noon
            if let next = entry.nextDate, let previous = entry.previousDate {
                let icon = IconType.sunrise(view: Sun(color: entry.color, rise: next.name == ChineseCalendar.dayTimeName.sunrise))

                switch family {
                case .accessoryRectangular:
                    RectanglePanel(icon: icon, name: Text(Locale.translation[next.name] ?? ""), color: entry.color, barColor: entry.barColor, start: previous.date, end: next.date)
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
                    RectanglePanel(icon: icon, name: sunDescription, color: entry.color, barColor: entry.barColor)
                case .accessoryCorner:
                    Curve(icon: icon, barColor: entry.barColor, start: nil, end: nil)
                default:
                    EmptyView()
                }
            }
        case .moonriseSet:
            let highMoonTime = entry.chineseCalendar.getMoonTimes(for: .current).highMoon
            if let next = entry.nextDate, let previous = entry.previousDate {
                let icon = IconType.moon(view: MoonPhase(angle: entry.chineseCalendar.currentDayInMonth, color: entry.color, rise: next.name == ChineseCalendar.moonTimeName.moonrise))

                switch family {
                case .accessoryRectangular:
                    RectanglePanel(icon: icon, name: Text(Locale.translation[next.name] ?? ""), color: entry.color, barColor: entry.barColor, start: previous.date, end: next.date)
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
                    RectanglePanel(icon: icon, name: moonDescription, color: entry.color, barColor: entry.barColor)
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
    static let kind: String = rectWidgetKind

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
