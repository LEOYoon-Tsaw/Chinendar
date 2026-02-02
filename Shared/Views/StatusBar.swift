//
//  StatusBar.swift
//  Chinendar
//
//  Created by Leo Liu on 1/30/26.
//

import Foundation

func statusBarString(from chineseCalendar: ChineseCalendar, options watchLayout: WatchLayout) -> String {
    var displayText = [String]()
    if watchLayout.statusBar.date {
        if watchLayout.baseLayout.nativeLanguage {
            displayText.append(String(localized: chineseCalendar.dateStringLocalized))
        } else {
            displayText.append(chineseCalendar.dateString)
        }
    }
    if watchLayout.statusBar.holiday > 0 {
        let holidays = chineseCalendar.holidays
        let displayHolidays = holidays[..<min(holidays.count, watchLayout.statusBar.holiday)]
        if watchLayout.baseLayout.nativeLanguage {
            displayText.append(contentsOf: displayHolidays.map(Locale.translate))
        } else {
            displayText.append(contentsOf: displayHolidays)
        }
    }
    if watchLayout.statusBar.time {
        if watchLayout.baseLayout.nativeLanguage {
            displayText.append(String(localized: chineseCalendar.timeStringLocalized))
        } else {
            displayText.append(chineseCalendar.timeString)
        }
    }

    if watchLayout.baseLayout.nativeLanguage {
        return displayText.joined(separator: Locale.translate(watchLayout.statusBar.separator.rawValue))
    } else {
        let displayDateTime = displayText.joined(separator: watchLayout.statusBar.separator.rawValue)
        return String(displayDateTime.reversed())
    }
}
