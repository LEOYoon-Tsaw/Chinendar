//
//  AppDelegate.swift
//  Chinese Time
//
//  Created by Leo Liu on 4/17/23.
//

import SwiftUI

@main
struct ChineseTimeiOSApp: App {
    let watchConnectivity = WatchConnectivityManager.shared
    let chineseCalendar = ChineseCalendar(time: .now)
    let locationManager = LocationManager.shared
    let watchLayout = WatchLayout.shared
    let watchSetting = WatchSetting.shared
    let timer = Timer.publish(every: ChineseCalendar.updateInterval, on: .main, in: .common).autoconnect()
    
    init() {
        let modelContext = ThemeData.container.mainContext
        watchLayout.loadDefault(context: modelContext)
        locationManager.requestLocation()
    }

    var body: some Scene {
        WindowGroup {
            WatchFace()
                .environment(\.chineseCalendar, chineseCalendar)
                .modelContainer(ThemeData.container)
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
        chineseCalendar.update(time: watchSetting.displayTime ?? Date.now,
                               timezone: watchSetting.timezone ?? Calendar.current.timeZone,
                               location: locationManager.location ?? watchLayout.location)
    }
}
