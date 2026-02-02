//
//  CalendarRow.swift
//  Chinendar
//
//  Created by Leo Liu on 1/31/26.
//

import SwiftUI

struct CalendarRow: View {
    @Environment(ViewModel.self) private var viewModel
    let configData: ConfigData
    let showTime: Bool

    var chineseDate: Text {
        guard let config = configData.config else { return Text("") }
        let location = config.locationEnabled ? viewModel.gpsLocation ?? config.customLocation : config.customLocation
        let calendar = ChineseCalendar(time: viewModel.chineseCalendar.time,
                                       timezone: config.effectiveTimezone,
                                       location: location,
                                       globalMonth: config.globalMonth, apparentTime: config.apparentTime,
                                       largeHour: config.largeHour)
        return datetimeString(calendar: calendar, nativeLanguage: viewModel.baseLayout.nativeLanguage)
    }

#if os(watchOS)
    var body: some View {
        Button {
            viewModel.config ?= configData.config
        } label: {
            VStack {
                Text(configData.nonNilName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if showTime {
                    chineseDate
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: viewModel.baseLayout.nativeLanguage ? .leading : .trailing)
                }
            }
        }
    }
#else
    var body: some View {
        HStack {
            Text(configData.nonNilName)
            Spacer()
            if showTime {
                chineseDate
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
#endif

    func datetimeString(calendar: ChineseCalendar, nativeLanguage: Bool) -> Text {
        var holidays = calendar.holidays
        holidays = Array(holidays[..<min(holidays.count, 2)])
        if nativeLanguage {
            holidays = holidays.map(Locale.translate)
            if !holidays.isEmpty {
                let holidayString = holidays.joined(separator: String(localized: "HOLIDAY_SEPARATOR"))
                return Text("DAY:\(calendar.dateStringLocalized),HOLIDAY:\(holidayString),TIME:\(calendar.timeStringLocalized)")
            } else {
                return Text("DAY:\(calendar.dateStringLocalized),TIME:\(calendar.timeStringLocalized)")
            }
        } else {
            var displayText = [String]()
            displayText.append(calendar.dateString)
            displayText.append(contentsOf: holidays)
            displayText.append(calendar.timeString)
            return Text(String(displayText.joined(separator: " ").reversed()))
        }
    }
}
