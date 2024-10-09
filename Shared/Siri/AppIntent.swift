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
    static var title: LocalizedStringResource { "LAUNCH_CHINENDAR" }
    static var description: IntentDescription { .init("LAUNCH_CHINENDAR_MSG") }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "SELECT_CALENDAR")
    var calendarConfig: ConfigIntent?

    static var parameterSummary: some ParameterSummary {
        Summary("LAUNCH\(\.$calendarConfig)WITH_CALENDAR") {
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
    static var title: LocalizedStringResource { "CHINENDAR_DATE_LOOKUP" }
    static var description: IntentDescription { .init("CHINENDAR_DATE_LOOKUP_MSG") }

    @Parameter(title: "SELECT_CALENDAR")
    var calendarConfig: ConfigIntent?
    @Parameter(title: "DATE_TO_LOOKUP")
    var queryDate: Date

    static var parameterSummary: some ParameterSummary {
        Summary("LOOKUP\(\.$queryDate)WITH_CALENDAR\(\.$calendarConfig)") {
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

        return .result(value: calendarString, dialog: IntentDialog(full: "MONTH\(chineseCalendar.monthStringLocalized)DAY\(chineseCalendar.dayStringLocalized)HOLIDAY\(Locale.translate(chineseCalendar.holidays.first ?? ""))HOUR\(chineseCalendar.hourStringLocalized)QUARTER\(chineseCalendar.quarterStringLocalized)", supporting: "LOOKUP_RESULT_PROMPT", systemImageName: "calendar.badge.clock")) {
            Text(String(calendarString.reversed()))
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .padding()
        }
    }
}

struct NextEvent: AppIntent {
    static var title: LocalizedStringResource { "NEXT_EVENT" }
    static var description: IntentDescription { .init("NEXT_EVENT_MSG") }

    @Parameter(title: "SELECT_CALENDAR")
    var calendarConfig: ConfigIntent?
    @Parameter(title: "EVENT_TYPE")
    var nextEventType: NextEventType

    static var parameterSummary: some ParameterSummary {
        Summary("NEXT\(\.$nextEventType)IN_CALENDAR\(\.$calendarConfig)") {
            \.$calendarConfig
            \.$nextEventType
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Date?> & ProvidesDialog & ShowsSnippetView {
        let asyncModels = await AsyncModels(calendarName: calendarConfig?.name)
        let (_, nextDate) = next(nextEventType, in: asyncModels.chineseCalendar)

        let dialog = if let nextDate {
            IntentDialog(full: "NEXT_EVENT\(Locale.translate(nextDate.name))IS_ON:\(nextDate.date.description(with: .current))", supporting: "NEXT_EVENT_RESULT_FOR:\(nextEventType)", systemImageName: "clock")
        } else {
            IntentDialog(full: "NEXT_EVENT\(nextEventType)UNAVAILABLE", supporting: "NEXT_EVENT_RESULT_FOR:\(nextEventType)", systemImageName: "clock")
        }

        return .result(value: nextDate?.date, dialog: dialog) {
            if let nextDate {
                NextEventView(nextDate: nextDate)
                    .padding()
            } else {
                Text("NEXT_EVENT\(nextEventType)UNAVAILABLE")
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
