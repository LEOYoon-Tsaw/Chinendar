//
//  Relevance.swift
//  Chinendar
//
//  Created by Leo Liu on 6/28/23.
//

import AppIntents

enum EventType: String, AppEnum {
    case solarTerms, lunarPhases, sunriseSet, moonriseSet

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "時計掛件選項")
    static var caseDisplayRepresentations: [EventType : DisplayRepresentation] = [
        .solarTerms: .init(title: "節氣"),
        .lunarPhases: .init(title: "月相"),
        .sunriseSet: .init(title: "日躔"),
        .moonriseSet: .init(title: "月離"),
    ]
}

struct CountDownConfiguration: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "CurveIntent"
    static var title: LocalizedStringResource = "時計"
    static var description = IntentDescription("距離次事件之倒計時")

    @Parameter(title: "目的", default: .solarTerms)
    var target: EventType
    
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$target
        }
    }
}

let rectWidgetKind = "Card"

func updateCountDownRelevantIntents(chineseCalendar: ChineseCalendar) async {
    async let sunTimes = nextSunTimes(chineseCalendar: chineseCalendar)
    async let moonTimes = nextMoonTimes(chineseCalendar: chineseCalendar)
    async let solarTerms = nextSolarTerm(chineseCalendar: chineseCalendar)
    async let moonPhases = nextMoonPhase(chineseCalendar: chineseCalendar)
    
    var relevantIntents = [RelevantIntent]()
    
    for date in await sunTimes {
        let config = CountDownConfiguration()
        config.target = .sunriseSet
        let relevantContext = RelevantContext.date(from: date - 3600, to: date + 900)
        let relevantIntent = RelevantIntent(config, widgetKind: rectWidgetKind, relevance: relevantContext)
        relevantIntents.append(relevantIntent)
    }
    
    for date in await moonTimes {
        let config = CountDownConfiguration()
        config.target = .moonriseSet
        let relevantContext = RelevantContext.date(from: date - 3600, to: date + 900)
        let relevantIntent = RelevantIntent(config, widgetKind: rectWidgetKind, relevance: relevantContext)
        relevantIntents.append(relevantIntent)
    }
    
    for date in await solarTerms {
        let config = CountDownConfiguration()
        config.target = .solarTerms
        let solarTermDate = chineseCalendar.copy
        solarTermDate.update(time: date)
        let relevantContext = RelevantContext.date(from: solarTermDate.startOfDay, to: solarTermDate.startOfNextDay)
        let relevantIntent = RelevantIntent(config, widgetKind: rectWidgetKind, relevance: relevantContext)
        relevantIntents.append(relevantIntent)
    }
    
    for date in await moonPhases {
        let config = CountDownConfiguration()
        config.target = .lunarPhases
        let lunarPhaseDate = chineseCalendar.copy
        lunarPhaseDate.update(time: date)
        let relevantContext = RelevantContext.date(from: lunarPhaseDate.startOfDay, to: lunarPhaseDate.startOfNextDay)
        let relevantIntent = RelevantIntent(config, widgetKind: rectWidgetKind, relevance: relevantContext)
        relevantIntents.append(relevantIntent)
    }
    
    do {
        try await RelevantIntentManager.shared.updateRelevantIntents(relevantIntents)
    } catch {
        print(error.localizedDescription)
    }
}

func nextMoonTimes(chineseCalendar: ChineseCalendar) -> [Date] {
    let moonTimes = chineseCalendar.moonTimes.filter {
        ($0.name == ChineseCalendar.moonTimeName[0] || $0.name == ChineseCalendar.moonTimeName[2]) && ($0.date > chineseCalendar.time)
    }.map{ $0.date }
    return moonTimes
}

func nextSunTimes(chineseCalendar: ChineseCalendar) -> [Date] {
    let sunTimes = chineseCalendar.sunTimes.filter {
        ($0.name == ChineseCalendar.dayTimeName[1] || $0.name == ChineseCalendar.dayTimeName[3]) && ($0.date > chineseCalendar.time)
    }.map{ $0.date }
    return sunTimes
}

func nextSolarTerm(chineseCalendar: ChineseCalendar) -> [Date] {
    let nextSolarTerm = chineseCalendar.solarTerms.first {
        $0.date > chineseCalendar.time
    }
    if let next = nextSolarTerm?.date {
        return [next]
    } else {
        return []
    }
}

func nextMoonPhase(chineseCalendar: ChineseCalendar) -> [Date] {
    let nextLunarPhase = chineseCalendar.moonPhases.first {
        $0.date > chineseCalendar.time
    }
    if let next = nextLunarPhase?.date {
        return [next]
    } else {
        return []
    }
}
