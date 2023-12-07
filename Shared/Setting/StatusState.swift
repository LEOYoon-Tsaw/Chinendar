//
//  StatusState.swift
//  Chinendar
//
//  Created by Leo Liu on 11/27/23.
//

import Foundation

class StatusState: Equatable {
    var location: CGPoint?
    var date: Date?
    var timezone: TimeZone?
    var statusBar: WatchLayout.StatusBar
    var calendarSetting: Int
    
    init(locationManager: LocationManager, watchLayout: WatchLayout, watchSetting: WatchSetting) {
        location = locationManager.location ?? watchLayout.location
        date = watchSetting.displayTime
        timezone = watchSetting.timezone
        statusBar = watchLayout.statusBar
        calendarSetting = (watchLayout.globalMonth ? 2 : 0) + (watchLayout.apparentTime ? 1 : 0)
    }

    static func == (lhs: StatusState, rhs: StatusState) -> Bool {
        return lhs.location == rhs.location &&
        lhs.date == rhs.date &&
        lhs.timezone == rhs.timezone &&
        lhs.statusBar == rhs.statusBar &&
        lhs.calendarSetting == rhs.calendarSetting
    }
}
