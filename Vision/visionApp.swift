//
//  visionApp.swift
//  Chinendar
//
//  Created by Leo Liu on 11/5/23.
//

import SwiftUI

@main
struct Chinendar: App {
    let chineseCalendar = ChineseCalendar(time: .now)
    let locationManager = LocationManager.shared
    let watchLayout = WatchLayout.shared
    let watchSetting = WatchSetting.shared
    let timer = Timer.publish(every: ChineseCalendar.updateInterval, on: .main, in: .common).autoconnect()
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    private var statusState: StatusState {
        StatusState(locationManager: locationManager, watchLayout: watchLayout, watchSetting: watchSetting)
    }
    
    
    init() {
        let modelContext = ThemeData.container.mainContext
        watchLayout.loadDefault(context: modelContext)
        locationManager.requestLocation()
    }
    
    var body: some Scene {
        WindowGroup(id: "WatchFace") {
            WatchFace()
                .padding(15)
                .environment(\.chineseCalendar, chineseCalendar)
                .modelContainer(ThemeData.container)
                .task {
                    self.update()
                }
                .onReceive(timer) { _ in
                    self.update()
                }
                .ornament(attachmentAnchor: .scene(.bottom)) {
                    HStack(spacing: 0) {
                        if watchSetting.timeDisplay.count > 0 {
                            Text(watchSetting.timeDisplay)
                                .padding()
                        }
                        Button {
                            watchSetting.settingIsOpen.toggle()
                        } label: {
                            if watchSetting.timeDisplay.count > 0 {
                                Label("設置", systemImage: "gear")
                                    .labelStyle(.iconOnly)
                            } else {
                                Label("設置", systemImage: "gear")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                        .onChange(of: watchSetting.settingIsOpen) {
                            if watchSetting.settingIsOpen {
                                openWindow(id: "Settings")
                            } else {
                                dismissWindow(id: "Settings")
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .glassBackgroundEffect()
                    .alignmentGuide(VerticalAlignment.center) { _ in
                        15
                    }
                }
        }
        .defaultSize(width: watchLayout.watchSize.width + 30, height: watchLayout.watchSize.height + 30)
        .windowResizability(.contentSize)
        
        WindowGroup(id: "Settings") {
            Setting()
                .environment(\.chineseCalendar, chineseCalendar)
                .modelContainer(ThemeData.container)
                .onChange(of: statusState) {
                    watchSetting.timeDisplay = String(statusBar(from: chineseCalendar, options: watchLayout).reversed())
                }
        }
        .defaultSize(width: 700, height: 700)
    }
    
    func statusBar(from chineseCalendar: ChineseCalendar, options watchLayout: WatchLayout) -> String {
        var displayText = [String]()
        if watchLayout.statusBar.date {
            displayText.append(chineseCalendar.dateString)
        }
        if watchLayout.statusBar.holiday > 0 {
            let holidays = chineseCalendar.holidays
            displayText.append(contentsOf: holidays[..<min(holidays.count, watchLayout.statusBar.holiday)])
        }
        if watchLayout.statusBar.time {
            displayText.append(chineseCalendar.hourString + chineseCalendar.quarterString)
        }
        return displayText.joined(separator: watchLayout.statusBar.separator.symbol)
    }
    
    func update() {
        chineseCalendar.update(time: watchSetting.displayTime ?? Date.now,
                               timezone: watchSetting.timezone ?? Calendar.current.timeZone,
                               location: locationManager.location ?? watchLayout.location)
        watchSetting.timeDisplay = String(statusBar(from: chineseCalendar, options: watchLayout).reversed())
    }
}
