//
//  CountDown.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents
import SwiftUI
@preconcurrency import WidgetKit

struct CountDownProvider: AppIntentTimelineProvider {
    typealias Entry = CountDownEntry
    typealias Intent = CountDownConfiguration
    let modelContext = ThemeData.context
    let locationManager = LocationManager.shared
    
    func placeholder(in context: Context) -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadStatic()
        let chineseCalendar = ChineseCalendar(time: .now, compact: true)
        return Entry(configuration: Intent(), chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()
        let chineseCalendar = ChineseCalendar(location: location, compact: true)
        return Entry(configuration: configuration, chineseCalendar: chineseCalendar, watchLayout: watchLayout)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let watchLayout = WatchLayout.shared
        watchLayout.loadDefault(context: modelContext, local: true)
        let location = await locationManager.getLocation()

        let chineseCalendar = ChineseCalendar(location: location, compact: true)
        let originalChineseCalendar = chineseCalendar.copy
        
        let allTimes = switch configuration.target {
        case .moonriseSet:
            nextMoonTimes(chineseCalendar: chineseCalendar)
        case .sunriseSet:
            nextSunTimes(chineseCalendar: chineseCalendar)
        case .lunarPhases:
            nextMoonPhase(chineseCalendar: chineseCalendar)
        case .solarTerms:
            nextSolarTerm(chineseCalendar: chineseCalendar)
        }
        let entryDates = if allTimes.count > 0 {
            allTimes
        } else {
            [chineseCalendar.startOfNextDay]
        }
        
        var chineseCalendars = [chineseCalendar.copy]
        for entryDate in entryDates {
            chineseCalendar.update(time: entryDate, location: location)
            chineseCalendars.append(chineseCalendar.copy)
        }
        let entries: [Entry] = await generateEntries(chineseCalendars: chineseCalendars, watchLayout: watchLayout, configuration: configuration)
#if os(watchOS)
        if context.family == .accessoryRectangular {
            await updateCountDownRelevantIntents(chineseCalendar: originalChineseCalendar)
        }
#endif
        return Timeline(entries: entries, policy: .atEnd)
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

struct CountDownEntry: TimelineEntry, ChineseTimeEntry {
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
                color = next.name == ChineseCalendar.moonPhases[0] ? watchLayout.eclipseIndicator : watchLayout.fullmoonIndicator
                barColor = if next.name == ChineseCalendar.moonPhases[0] { // New moon
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
            let moonriseAndSet = chineseCalendar.moonTimes.filter { $0.name == ChineseCalendar.moonTimeName[0] || $0.name == ChineseCalendar.moonTimeName[2] }
            (previousDate, nextDate) = find(in: moonriseAndSet, at: chineseCalendar.time)
            if let next = nextDate {
                color = next.name == ChineseCalendar.moonTimeName[0] ? watchLayout.moonPositionIndicator[0] : watchLayout.moonPositionIndicator[2]
                barColor = if next.name == ChineseCalendar.moonTimeName[0] { // Moonrise
                    watchLayout.secondRing.interpolate(at: chineseCalendar.sunMoonPositions.lunar[0]?.pos ?? chineseCalendar.sunMoonPositions.lunar[3]?.pos ?? 0.25)
                } else { // Moonset
                    watchLayout.secondRing.interpolate(at: chineseCalendar.sunMoonPositions.lunar[2]?.pos ?? chineseCalendar.sunMoonPositions.lunar[5]?.pos ?? 0.75)
                }
                relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: next.date))
            } else {
                color = watchLayout.moonPositionIndicator[1]
                barColor = CGColor(gray: 0, alpha: 0)
                relevance = TimelineEntryRelevance(score: 0)
            }
            
        case .sunriseSet:
            self.date = chineseCalendar.time + 1800 // Half Hour
            let sunriseAndSet = chineseCalendar.sunTimes.filter { $0.name == ChineseCalendar.dayTimeName[1] || $0.name == ChineseCalendar.dayTimeName[3] }
            (previousDate, nextDate) = find(in: sunriseAndSet, at: chineseCalendar.time)
            if let next = nextDate {
                color = next.name == ChineseCalendar.dayTimeName[1] ? watchLayout.sunPositionIndicator[1] : watchLayout.sunPositionIndicator[3]
                barColor = if next.name == ChineseCalendar.dayTimeName[1] { // Sunrise
                    watchLayout.thirdRing.interpolate(at: chineseCalendar.sunMoonPositions.solar[1]?.pos ?? 0.25)
                } else { // Sunset
                    watchLayout.thirdRing.interpolate(at: chineseCalendar.sunMoonPositions.solar[3]?.pos ?? 0.75)
                }
                relevance = TimelineEntryRelevance(score: 10, duration: date.distance(to: next.date))
            } else {
                color = watchLayout.sunPositionIndicator[2]
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
                let icon = IconType.moon(view: MoonPhase(angle: next.name == ChineseCalendar.moonPhases[0] ? 0.05 : 0.5, color: entry.color))
                
                switch family {
                case .accessoryRectangular:
                    RectanglePanel(icon: icon, name: Text(Locale.translation[next.name]! ?? ""), color: entry.color, barColor: entry.barColor, start: previous.date, end: next.date)
                case .accessoryCorner:
                    Curve(icon: icon, barColor: entry.barColor,
                          start: previous.date, end: next.date)
                default:
                    EmptyView()
                }
            }
            
        case .sunriseSet:
            let noonTimes = entry.chineseCalendar.sunTimes.filter { $0.name == ChineseCalendar.dayTimeName[2]}
            if let next = entry.nextDate, let previous = entry.previousDate {
                let icon = IconType.sunrise(view: Sun(color: entry.color, rise: next.name == ChineseCalendar.dayTimeName[1]))
                
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
                        if noonTimes.count > 0 {
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
            let moonNoonTimes = entry.chineseCalendar.moonTimes.filter { $0.name == ChineseCalendar.moonTimeName[1]}
            if let next = entry.nextDate, let previous = entry.previousDate {
                let icon = IconType.moon(view: MoonPhase(angle: entry.chineseCalendar.currentDayInMonth, color: entry.color, rise: next.name == ChineseCalendar.moonTimeName[0]))
                
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
                        if moonNoonTimes.count > 0 {
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
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}

#Preview("Moonrise", as: .accessoryRectangular, using: {
    let intent = CountDownProvider.Intent()
    intent.target = .moonriseSet
    return intent
}()) {
    RectWidget()
} timelineProvider: {
    CountDownProvider()
}
