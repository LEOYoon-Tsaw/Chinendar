//
//  StatusState.swift
//  Chinendar
//
//  Created by Leo Liu on 11/27/23.
//

import Foundation

class StatusState: Equatable {
    var location: GeoLocation?
    var date: Date?
    var timezone: TimeZone?
    var statusBar: WatchLayout.StatusBar
    var calendarSetting: Int

    init(locationManager: LocationManager, watchLayout: WatchLayout, calendarConfigure: CalendarConfigure, watchSetting: WatchSetting) {
        location = calendarConfigure.location(locationManager: locationManager)
        date = watchSetting.displayTime
        timezone = calendarConfigure.timezone
        statusBar = watchLayout.statusBar
        calendarSetting = (calendarConfigure.globalMonth ? 2 : 0) + (calendarConfigure.apparentTime ? 1 : 0)
    }

    static func == (lhs: StatusState, rhs: StatusState) -> Bool {
        return lhs.location == rhs.location &&
        lhs.date == rhs.date &&
        lhs.timezone == rhs.timezone &&
        lhs.statusBar == rhs.statusBar &&
        lhs.calendarSetting == rhs.calendarSetting
    }
}
