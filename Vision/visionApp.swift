//
//  visionApp.swift
//  Chinendar
//
//  Created by Leo Liu on 11/5/23.
//

import SwiftUI

@main
struct Chinendar: App {
    let chineseCalendar = ChineseCalendar()
    let locationManager = LocationManager()
    let watchLayout = WatchLayout()
    let calendarConfigure = CalendarConfigure()
    let watchSetting = WatchSetting()
    let timer = Timer.publish(every: ChineseCalendar.updateInterval, on: .main, in: .common).autoconnect()
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    private var statusState: StatusState {
        StatusState(locationManager: locationManager, watchLayout: watchLayout, calendarConfigure: calendarConfigure, watchSetting: watchSetting)
    }
    
    init() {
        watchLayout.loadDefault(context: DataSchema.container.mainContext)
        calendarConfigure.load(name: LocalData.read(context: LocalSchema.container.mainContext)?.configName, context: DataSchema.container.mainContext)
        locationManager.enabled = true
        watchLayout.autoSave()
        calendarConfigure.autoSave()
        calendarConfigure.autoSaveName()
    }
    
    var body: some Scene {
        WindowGroup(id: "WatchFace") {
            WatchFace()
                .padding(15)
                .modelContainer(DataSchema.container)
                .environment(chineseCalendar)
                .environment(watchLayout)
                .environment(watchSetting)
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
                .modelContainer(DataSchema.container)
                .environment(chineseCalendar)
                .environment(locationManager)
                .environment(watchLayout)
                .environment(calendarConfigure)
                .environment(watchSetting)
                .onChange(of: statusState) {
                    watchSetting.timeDisplay = String(statusBar(from: chineseCalendar, options: watchLayout).reversed())
                }
        }
        .defaultSize(width: 900, height: 700)
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
        chineseCalendar.update(time: watchSetting.effectiveTime,
                               timezone: calendarConfigure.effectiveTimezone,
                               location: calendarConfigure.location(locationManager: locationManager),
                               globalMonth: calendarConfigure.globalMonth,
                               apparentTime: calendarConfigure.apparentTime,
                               largeHour: calendarConfigure.largeHour)
        watchSetting.timeDisplay = String(statusBar(from: chineseCalendar, options: watchLayout).reversed())
    }
}
