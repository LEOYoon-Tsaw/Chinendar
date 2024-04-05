//
//  macApp.swift
//  Chinendar
//
//  Created by Leo Liu on 9/19/21.
//

import SwiftUI
import WidgetKit

@main
struct Chinendar: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            Welcome()
                .frame(minWidth: 300, idealWidth: 350, maxWidth: 400, minHeight: 400, idealHeight: 600, maxHeight: 700, alignment: .center)
                .environment(appDelegate.watchLayout)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var instance: AppDelegate?
    var statusItem: NSStatusItem!
    let chineseCalendar = ChineseCalendar()
    let locationManager = LocationManager()
    let watchLayout = WatchLayout()
    let calendarConfigure = CalendarConfigure()
    let watchSetting = WatchSetting()
    let dataContainer = DataSchema.container
    var watchPanel: WatchPanel!
    private var _timer: Timer?
    var lastReloaded = Date.distantPast
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 0)
        statusItem.button?.action = #selector(self.toggleDisplay(sender:))
        statusItem.button?.sendAction(on: [.leftMouseDown])
        watchLayout.loadDefault(context: dataContainer.mainContext)
        calendarConfigure.load(name: LocalData.read(context: LocalSchema.container.mainContext)?.configName, context: dataContainer.mainContext)
        locationManager.enabled = true
        watchLayout.autoSave()
        calendarConfigure.autoSave()
        calendarConfigure.autoSaveName()
        AppDelegate.instance = self
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        update()
        watchPanel = {
            let watchFace = WatchFace()
                .modelContainer(dataContainer)
                .environment(chineseCalendar)
                .environment(watchLayout)
            let setting = Setting()
                .frame(minWidth: 550, maxWidth: 700, minHeight: 350, maxHeight: 500)
                .modelContainer(dataContainer)
                .environment(chineseCalendar)
                .environment(locationManager)
                .environment(watchLayout)
                .environment(calendarConfigure)
                .environment(watchSetting)
            
            return WatchPanelHosting(watch: watchFace, setting: setting, statusItem: statusItem, watchLayout: watchLayout, isPresented: false)
        }()
        _timer = Timer.scheduledTimer(withTimeInterval: ChineseCalendar.updateInterval, repeats: true) { _ in
            Task { @MainActor in
                self.update()
            }
        }
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        watchPanel.isPresented = false
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        if lastReloaded.distance(to: .now) > 1800 { // Half Hour
            WidgetCenter.shared.reloadAllTimelines()
        }
        _timer?.invalidate()
        _timer = nil
        statusItem = nil
    }
    
    @objc func toggleDisplay(sender: NSStatusItem) {
        watchPanel.isPresented.toggle()
        if watchPanel.isPresented && lastReloaded.distance(to: .now) > 7200 { // 2 Hours
            WidgetCenter.shared.reloadAllTimelines()
            lastReloaded = .now
        }
    }
    
    func updateStatusBar(dateText: String) {
        if let button = statusItem.button {
            if dateText.count > 0 {
                button.image = nil
                button.title = String(dateText.reversed())
            } else {
                button.title = ""
                let image = NSImage(resource: .image)
                image.size = NSMakeSize(NSStatusBar.system.thickness, NSStatusBar.system.thickness)
                button.image = image
            }
            statusItem.length = button.intrinsicContentSize.width
        }
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
        updateStatusBar(dateText: statusBar(from: chineseCalendar, options: watchLayout))
    }
}
