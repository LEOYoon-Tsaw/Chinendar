//
//  macApp.swift
//  Chinendar
//
//  Created by Leo Liu on 9/19/21.
//

import SwiftUI
@preconcurrency import WidgetKit

@main
struct Chinendar: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            Welcome()
                .frame(minWidth: 300, idealWidth: 350, maxWidth: 400, minHeight: 400, idealHeight: 600, maxHeight: 700, alignment: .center)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var instance: AppDelegate?
    var statusItem: NSStatusItem!
    let watchSetting = WatchSetting.shared
    let watchLayout = WatchLayout.shared
    let modelContainer = ThemeData.container
    let locationManager = LocationManager.shared
    let chineseCalendar = ChineseCalendar(time: .now)
    var watchPanel: WatchPanel!
    private var _timer: Timer?
    var lastReloaded = Date.distantPast
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 0)
        statusItem.button?.action = #selector(self.toggleDisplay(sender:))
        statusItem.button?.sendAction(on: [.leftMouseDown])
        watchLayout.loadDefault(context: modelContainer.mainContext)
        locationManager.requestLocation()
        AppDelegate.instance = self
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        update()
        watchPanel = {
            let watchFace = WatchFace()
                .environment(\.chineseCalendar, chineseCalendar)
                .modelContainer(modelContainer)
            let setting = Setting()
                .frame(minWidth: 550, maxWidth: 700, minHeight: 350, maxHeight: 500)
                .environment(\.chineseCalendar, chineseCalendar)
                .modelContainer(modelContainer)
            
            return WatchPanelHosting(watch: watchFace, setting: setting, statusItem: statusItem, isPresented: false)
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
        watchLayout.saveDefault(context: modelContainer.mainContext)
        try? modelContainer.mainContext.save()
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
        chineseCalendar.update(time: watchSetting.displayTime ?? Date.now,
                               timezone: watchSetting.timezone ?? Calendar.current.timeZone,
                               location: locationManager.location ?? watchLayout.location)
        updateStatusBar(dateText: statusBar(from: chineseCalendar, options: watchLayout))
    }
}
