//
//  StatusState.swift
//  Chinendar
//
//  Created by Leo Liu on 11/27/23.
//

import Foundation

struct StatusState: Equatable {
    var statusBar: WatchLayout.StatusBar
    var config: CalendarConfigure
    var settings: WatchSetting

    init(watchLayout: WatchLayout, calendarConfigure: CalendarConfigure, watchSetting: WatchSetting) {
        config = calendarConfigure
        settings = watchSetting
        statusBar = watchLayout.statusBar
    }
}
