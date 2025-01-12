//
//  AppEntity.swift
//  Chinendar
//
//  Created by Leo Liu on 8/6/24.
//

import AppIntents

struct ConfigIntent: AppEntity {
    let id: String
    var name: String { id }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "SELECT_CALENDAR"
    static let defaultQuery = ConfigQuery()

    var displayRepresentation: DisplayRepresentation {
        if name != AppInfo.defaultName {
            DisplayRepresentation(title: "\(name)")
        } else {
            DisplayRepresentation("DEFAULT_NAME")
        }
    }

    struct ConfigQuery: EntityQuery {
        func entities(for identifiers: [String]) async throws -> [ConfigIntent] {
            try await suggestedEntities().filter { identifiers.contains($0.name) }
        }

        func suggestedEntities() async throws -> [ConfigIntent] {
            let allConfigs = try await DataModel.shared.allConfigNames().map { name in
                ConfigIntent(id: name)
            }
            if allConfigs.count > 0 {
                return allConfigs
            } else {
                return [ConfigIntent(id: AppInfo.defaultName)]
            }
        }

        func defaultResult() -> ConfigIntent? {
            let name = LocalData.configName ?? AppInfo.defaultName
            return ConfigIntent(id: name)
        }
    }
}

enum NextEventType: String, AppEnum {
    case solarTerms, lunarPhases, sunriseSet, moonriseSet, chineseHoliday

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "EVENT_TYPE")
    static let caseDisplayRepresentations: [NextEventType: DisplayRepresentation] = [
        .solarTerms: .init(title: "ET_ST"),
        .lunarPhases: .init(title: "ET_MP"),
        .chineseHoliday: .init(title: "ET_HOLIDAY"),
        .sunriseSet: .init(title: "SUNRISE_SET"),
        .moonriseSet: .init(title: "MOONRISE_SET")
    ]
}

struct AsyncModels {
    let chineseCalendar: ChineseCalendar
    let config: CalendarConfigure
    let layout: WatchLayout

    init(compact: Bool = true, calendarName: String? = nil) async {
        let prepareLocation = Task {
            try await LocationManager.shared.getLocation(wait: .seconds(5))
        }

        var layout = WatchLayout(baseLayout: BaseLayout())
        var config = CalendarConfigure()
        let defaultLayout = ThemeData.loadLocalDefault()
        let defaultConfig = if let calendarName {
            ConfigData.load(name: calendarName, context: DataModel.shared.modelExecutor.modelContext)
        } else {
            ConfigData.loadLocalDefault()
        }

        layout.update(from: defaultLayout)
        if let defaultConfig {
            config.update(from: defaultConfig.code, newName: defaultConfig.name)
        }

        prepareLocation.cancel()
        let location = await config.location(wait: .seconds(2))
        self.chineseCalendar = ChineseCalendar(timezone: config.effectiveTimezone, location: location, compact: compact, globalMonth: config.globalMonth, apparentTime: config.apparentTime, largeHour: config.largeHour)
        self.config = config
        self.layout = layout
    }
}

private func find(in dates: [ChineseCalendar.NamedDate], at date: Date) -> (ChineseCalendar.NamedDate?, ChineseCalendar.NamedDate?) {
    if dates.count > 1 {
        let dates = dates.sorted { $0.date < $1.date }
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

func next(_ eventType: NextEventType, in chineseCalendar: ChineseCalendar) -> (prev: ChineseCalendar.NamedDate?, next: ChineseCalendar.NamedDate?) {
    var prev: ChineseCalendar.NamedDate?
    var next: ChineseCalendar.NamedDate?
    switch eventType {
    case .lunarPhases:
        (prev, next) = find(in: chineseCalendar.moonPhases, at: chineseCalendar.time)

    case .solarTerms:
        (prev, next) = find(in: chineseCalendar.solarTerms, at: chineseCalendar.time)

    case .chineseHoliday:
        var previousYearCalendar = chineseCalendar
        previousYearCalendar.update(time: chineseCalendar.solarTerms[0].date - 1)
        var nextYearCalendar = chineseCalendar
        nextYearCalendar.update(time: chineseCalendar.solarTerms[24].date + 1)
        (prev, next) = find(in: [previousYearCalendar.lunarHolidays.last!] + chineseCalendar.lunarHolidays + [nextYearCalendar.lunarHolidays.first!], at: chineseCalendar.time)

    case .moonriseSet:
        var chineseCalendar = chineseCalendar
        let currentTimes = chineseCalendar.getMoonTimes(for: .current)
        let previousTimes = chineseCalendar.getMoonTimes(for: .previous)
        let nextTimes = chineseCalendar.getMoonTimes(for: .next)
        let moonriseAndSet = [previousTimes.moonrise, previousTimes.moonset, currentTimes.moonrise, currentTimes.moonset, nextTimes.moonrise, nextTimes.moonset].compactMap { $0 }
        (prev, next) = find(in: moonriseAndSet, at: chineseCalendar.time)

    case .sunriseSet:
        var chineseCalendar = chineseCalendar
        let currentTimes = chineseCalendar.getSunTimes(for: .current)
        let previousTimes = chineseCalendar.getSunTimes(for: .previous)
        let nextTimes = chineseCalendar.getSunTimes(for: .next)
        let sunriseAndSet = [previousTimes.sunrise, previousTimes.sunset, currentTimes.sunrise, currentTimes.sunset, nextTimes.sunrise, nextTimes.sunset].compactMap { $0 }
        (prev, next) = find(in: sunriseAndSet, at: chineseCalendar.time)
    }

    return (prev: prev, next: next)
}
