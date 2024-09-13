//
//  AppIntent.swift
//  Chinendar
//
//  Created by Leo Liu on 8/6/24.
//

import AppIntents
import SwiftUI
import Foundation

struct OpenApp: AppIntent {
    static var title: LocalizedStringResource { "打開華曆" }
    static var description: IntentDescription { .init("打開華曆查看當前日時") }
    static var openAppWhenRun: Bool { true }
    
    @Parameter(title: "日曆名")
    var calendarConfig: ConfigIntent?
    
    static var parameterSummary: some ParameterSummary {
        Summary("打開\(\.$calendarConfig)日曆") {
            \.$calendarConfig
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        if let configName = calendarConfig?.name {
            let config = ConfigData.load(name: configName, context: DataSchema.container.mainContext)
            if let configCode = config?.code {
                ViewModel.shared.updateConfig(from: configCode)
                ViewModel.shared.updateChineseCalendar()
            }
        }
        return .result()
    }
}

struct ChinendarDate: AppIntent {
    static var title: LocalizedStringResource { "查詢華曆日期" }
    static var description: IntentDescription { .init("查詢此日期對應的華曆日期") }
    
    @Parameter(title: "日曆名")
    var calendarConfig: ConfigIntent?
    @Parameter(title: "待查日期")
    var queryDate: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("以\(\.$calendarConfig)日曆轉換\(\.$queryDate)") {
            \.$calendarConfig
        }
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
        let asyncModels = await AsyncModels(calendarName: calendarConfig?.name)
        var chineseCalendar = asyncModels.chineseCalendar
        chineseCalendar.update(time: queryDate)
        let calendarString = if chineseCalendar.holidays.count > 0 {
            "\(chineseCalendar.dateString) \(chineseCalendar.holidays.joined(separator: " ")) \(chineseCalendar.timeString)"
        } else {
            "\(chineseCalendar.dateString) \(chineseCalendar.timeString)"
        }
        
        return .result(value: calendarString, dialog: IntentDialog(full: "\(chineseCalendar.monthStringLocalized)\(chineseCalendar.dayStringLocalized)\(Locale.translate(chineseCalendar.holidays.first ?? ""))，\(chineseCalendar.hourStringLocalized)\(chineseCalendar.quarterStringLocalized)", supporting: "這是您查詢的華曆日時：", systemImageName: "calendar.badge.clock")) {
            Text(calendarString)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .padding()
        }
    }
}

struct NextEvent: AppIntent {
    static var title: LocalizedStringResource { "下一時刻" }
    static var description: IntentDescription { .init("查詢某一類型的下一個時刻") }
    
    @Parameter(title: "日曆名")
    var calendarConfig: ConfigIntent?
    @Parameter(title: "下一時刻類型")
    var nextEventType: NextEventType
    
    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$calendarConfig)日曆中的下一個\(\.$nextEventType)") {
            \.$calendarConfig
            \.$nextEventType
        }
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<Date?> & ProvidesDialog & ShowsSnippetView {
        let asyncModels = await AsyncModels(calendarName: calendarConfig?.name)
        var nextDate: ChineseCalendar.NamedDate? = nil
        
        switch nextEventType {
        case .lunarPhases:
            let (_, nextOne) = find(in: asyncModels.chineseCalendar.moonPhases, at: asyncModels.chineseCalendar.time)
            nextDate ?= nextOne

        case .solarTerms:
            let (_, nextOne) = find(in: asyncModels.chineseCalendar.solarTerms, at: asyncModels.chineseCalendar.time)
            nextDate ?= nextOne

        case .moonriseSet:
            var chineseCalendar = asyncModels.chineseCalendar
            let current = chineseCalendar.getMoonTimes(for: .current)
            let previous = chineseCalendar.getMoonTimes(for: .previous)
            let next = chineseCalendar.getMoonTimes(for: .next)
            let moonriseAndSet = [previous.moonrise, previous.moonset, current.moonrise, current.moonset, next.moonrise, next.moonset].compactMap { $0 }
            let (_, nextOne) = find(in: moonriseAndSet, at: chineseCalendar.time)
            nextDate ?= nextOne

        case .sunriseSet:
            var chineseCalendar = asyncModels.chineseCalendar
            let current = chineseCalendar.getSunTimes(for: .current)
            let previous = chineseCalendar.getSunTimes(for: .previous)
            let next = chineseCalendar.getSunTimes(for: .next)
            let sunriseAndSet = [previous.sunrise, previous.sunset, current.sunrise, current.sunset, next.sunrise, next.sunset].compactMap { $0 }
            let (_, nextOne) = find(in: sunriseAndSet, at: chineseCalendar.time)
            nextDate ?= nextOne
        }
        
        let dialog = if let nextDate {
            IntentDialog(full: "下一個\(Locale.translate(nextDate.name))時刻是：\(nextDate.date.description(with: .current))", supporting: "這是\(nextEventType)的查詢結果：", systemImageName: "clock")
        } else {
            IntentDialog(full: "下一個\(nextEventType)時刻不存在。", supporting: "這是\(nextEventType)的查詢結果：", systemImageName: "clock")
        }
        
        return .result(value: nextDate?.date, dialog: dialog) {
            if let nextDate {
                NextEventView(nextDate: nextDate)
                    .padding()
            } else {
                Text("下一個\(nextEventType)時刻不存在")
                    .font(.title)
                    .padding()
            }
        }
    }
}

struct NextEventView: View {
    let nextDate: ChineseCalendar.NamedDate
    
    var body: some View {
        VStack(spacing: 5) {
            Text(Locale.translate(nextDate.name))
                .lineLimit(1)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
            Text(nextDate.date.formatted(date: .abbreviated, time: .shortened))
                .lineLimit(1)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
        }
        .foregroundStyle(.primary)
    }
}

#Preview {
    let nextDate = ChineseCalendar.NamedDate(name: "大暑", date: Date.now + 23048)
    NextEventView(nextDate: nextDate)
}
