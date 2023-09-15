//
//  File.swift
//  Chinese Time
//
//  Created by Leo Liu on 8/29/23.
//

import SwiftUI

struct WatchLayoutKey: EnvironmentKey {
    static let defaultValue: WatchLayout = .shared
}

struct WatchSettingKey: EnvironmentKey {
    static let defaultValue: WatchSetting = .shared
}

struct LocationManagerKey: EnvironmentKey {
    static let defaultValue: LocationManager = .shared
}

struct ChineseCalendarKey: EnvironmentKey {
    static let defaultValue: ChineseCalendar = .init(time: .now)
}

extension EnvironmentValues {
    
    var watchLayout: WatchLayout {
        get { self[WatchLayoutKey.self] }
        set { self[WatchLayoutKey.self] = newValue }
    }
    
    var watchSetting: WatchSetting {
        get { self[WatchSettingKey.self] }
        set { self[WatchSettingKey.self] = newValue }
    }
    
    var locationManager: LocationManager {
        get { self[LocationManagerKey.self] }
        set { self[LocationManagerKey.self] = newValue }
    }
    
    var chineseCalendar: ChineseCalendar {
        get { self[ChineseCalendarKey.self] }
        set { self[ChineseCalendarKey.self] = newValue }
    }
}
