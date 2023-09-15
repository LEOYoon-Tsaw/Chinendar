//
//  ChineseTimeApp.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI

@main
struct ChineseTimeWatchApp: App {
    let watchConnectivity = WatchConnectivityManager.shared
    let watchLayout = WatchLayout.shared
    let watchSetting = WatchSetting.shared
    let locationManager = LocationManager.shared
    let chineseCalendar = ChineseCalendar(time: .now, compact: true)
    let timer = Timer.publish(every: ChineseCalendar.updateInterval, on: .main, in: .common).autoconnect()
    
    init() {
        let modelContext = ThemeData.container.mainContext
        watchLayout.loadDefault(context: modelContext)
        locationManager.requestLocation()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(ThemeData.container)
                .environment(\.chineseCalendar, chineseCalendar)
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
                               location: locationManager.location ?? watchLayout.location)
    }
}
