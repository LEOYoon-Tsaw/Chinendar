//
//  iOSApp.swift
//  Chinendar
//
//  Created by Leo Liu on 4/17/23.
//

import SwiftUI

@main
struct Chinendar: App {
    let chineseCalendar = ChineseCalendar()
    let locationManager = LocationManager()
    let watchLayout = WatchLayout()
    let calendarConfigure = CalendarConfigure()
    let watchSetting = WatchSetting()
    let watchConnectivity: WatchConnectivityManager
    let timer = Timer.publish(every: ChineseCalendar.updateInterval, on: .main, in: .common).autoconnect()

    init() {
        watchConnectivity = .init(watchLayout: watchLayout, calendarConfigure: calendarConfigure, locationManager: locationManager)
        watchLayout.watchConnectivity = watchConnectivity
        calendarConfigure.watchConnectivity = watchConnectivity
        watchLayout.loadDefault(context: DataSchema.container.mainContext)
        calendarConfigure.load(name: LocalData.read(context: LocalSchema.container.mainContext)?.configName, context: DataSchema.container.mainContext)
        locationManager.enabled = true
        watchLayout.autoSave()
        calendarConfigure.autoSave()
        calendarConfigure.autoSaveName()
    }

    var body: some Scene {
        WindowGroup {
            WatchFace()
                .modelContainer(DataSchema.container)
                .environment(chineseCalendar)
                .environment(locationManager)
                .environment(watchLayout)
                .environment(calendarConfigure)
                .environment(watchSetting)
                .task {
                    self.update()
                    await updateCountDownRelevantIntents(chineseCalendar: chineseCalendar.copy)
                }
                .onReceive(timer) { _ in
                    self.update()
                }
        }
    }

    func update() {
        chineseCalendar.update(time: watchSetting.effectiveTime,
                               timezone: calendarConfigure.effectiveTimezone,
                               location: calendarConfigure.location(locationManager: locationManager),
                               globalMonth: calendarConfigure.globalMonth,
                               apparentTime: calendarConfigure.apparentTime,
                               largeHour: calendarConfigure.largeHour)
    }
}
