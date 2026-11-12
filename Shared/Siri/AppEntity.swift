//
//  AppEntity.swift
//  Chinendar
//
//  Created by Leo Liu on 8/6/24.
//

import AppIntents
import SwiftData

struct OpenApp: AppIntent {
    static let title = LocalizedStringResource("LAUNCH_CHINENDAR")
    static let description = IntentDescription("LAUNCH_CHINENDAR_MSG")
    static let openAppWhenRun = true

    @Parameter(title: "SELECT_CALENDAR")
    var calendarConfig: ConfigIntent?

    static var parameterSummary: some ParameterSummary {
        Summary("LAUNCH_CHINENDAR") {
            \.$calendarConfig
        }
    }

    func perform() async throws -> some IntentResult {
        if let calendarConfig {
            try await LocalDataModel.shared.updateConfig(config: calendarConfig.config)
        }
        return .result()
    }
}

#if os(iOS) || os(macOS) || os(watchOS)
extension OpenApp: ControlConfigurationIntent {}
#endif

struct ConfigIntent: AppEntity {
    let id: String
    let name: String
    let config: CalendarConfigure

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "SELECT_CALENDAR"
    static let defaultQuery = ConfigQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    struct ConfigQuery: EntityQuery {
        func entities(for identifiers: [String]) async throws -> [ConfigIntent] {
            var results = try await DataModel.shared.getAllConfigIntent(ids: identifiers)
            let localConfig = await LocalDataModel.shared.getLocalConfigIntent()
            if identifiers.contains(localConfig.id) {
                results.append(localConfig)
            }
            return results
        }

        func suggestedEntities() async throws -> [ConfigIntent] {
            let sharedConfigs = try await DataModel.shared.getAllConfigIntent()
            let localConfig = await LocalDataModel.shared.getLocalConfigIntent()
            return [localConfig] + sharedConfigs
        }

        func defaultResult() async -> ConfigIntent? {
            await LocalDataModel.shared.getLocalConfigIntent()
        }
    }
}

struct ThemeIntent: AppEntity {
    let id: String
    let name: String
    let theme: WatchLayout

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "SELECT_THEME"
    static let defaultQuery = ThemeQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    struct ThemeQuery: EntityQuery {
        func entities(for identifiers: [String]) async throws -> [ThemeIntent] {
            var results = try await DataModel.shared.getAllThemeIntent(ids: identifiers)
            let localTheme = await LocalDataModel.shared.getLocalThemeIntent()
            if identifiers.contains(localTheme.id) {
                results.append(localTheme)
            }
            return results
        }

        func suggestedEntities() async throws -> [ThemeIntent] {
            let sharedThemes = try await DataModel.shared.getAllThemeIntent()
            let localTheme = await LocalDataModel.shared.getLocalThemeIntent()
            return [localTheme] + sharedThemes
        }

        func defaultResult() async -> ThemeIntent? {
            await LocalDataModel.shared.getLocalThemeIntent()
        }
    }
}

enum NextEventType: String, AppEnum, Codable {
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

private func find(in dates: [ChineseCalendar.NamedDate], at date: Date, chronological: Bool) -> (ChineseCalendar.NamedDate?, ChineseCalendar.NamedDate?) {
    if dates.count > 1 {
        let dates = dates.sorted { $0.date < $1.date }
        let atDate = ChineseCalendar.NamedDate(name: "", date: date)
        let index = dates.insertionIndex(of: atDate, comparison: { $0.date < $1.date })
        if index > 0 && index < dates.count {
            let previous = dates[index - 1]
            let next = dates[index]
            if chronological || Date.now.distance(to: date) < 30 || previous.date.distance(to: date) < date.distance(to: next.date) {
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

func next(_ eventType: NextEventType, in chineseCalendar: ChineseCalendar, chronological: Bool = false) -> (prev: ChineseCalendar.NamedDate?, next: ChineseCalendar.NamedDate?) {
    var prev: ChineseCalendar.NamedDate?
    var next: ChineseCalendar.NamedDate?
    switch eventType {
    case .lunarPhases:
        (prev, next) = find(in: chineseCalendar.moonPhases, at: chineseCalendar.time, chronological: chronological)

    case .solarTerms:
        (prev, next) = find(in: chineseCalendar.solarTerms, at: chineseCalendar.time, chronological: chronological)

    case .chineseHoliday:
        var holidays = [ChineseCalendar.NamedDate]()
        for time in [chineseCalendar.solarTerms[0].date - 180 * 86400, chineseCalendar.solarTerms[12].date, chineseCalendar.solarTerms[24].date + 180 * 86400] {
            var calendar = chineseCalendar
            calendar.update(time: time)
            holidays.append(contentsOf: calendar.lunarHolidays)
        }
        (prev, next) = find(in: holidays, at: chineseCalendar.time, chronological: chronological)

    case .moonriseSet:
        var chineseCalendar = chineseCalendar
        let currentTimes = chineseCalendar.getMoonTimes(for: .current)
        let previousTimes = chineseCalendar.getMoonTimes(for: .previous)
        let nextTimes = chineseCalendar.getMoonTimes(for: .next)
        let moonriseAndSet = [previousTimes.moonrise, previousTimes.moonset, currentTimes.moonrise, currentTimes.moonset, nextTimes.moonrise, nextTimes.moonset].compactMap { $0 }
        (prev, next) = find(in: moonriseAndSet, at: chineseCalendar.time, chronological: chronological)

    case .sunriseSet:
        var chineseCalendar = chineseCalendar
        let currentTimes = chineseCalendar.getSunTimes(for: .current)
        let previousTimes = chineseCalendar.getSunTimes(for: .previous)
        let nextTimes = chineseCalendar.getSunTimes(for: .next)
        let sunriseAndSet = [previousTimes.sunrise, previousTimes.sunset, currentTimes.sunrise, currentTimes.sunset, nextTimes.sunrise, nextTimes.sunset].compactMap { $0 }
        (prev, next) = find(in: sunriseAndSet, at: chineseCalendar.time, chronological: chronological)
    }

    return (prev: prev, next: next)
}
