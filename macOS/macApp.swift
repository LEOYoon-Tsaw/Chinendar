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
                .environment(appDelegate.viewModel)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var instance: AppDelegate?
    var statusItem: NSStatusItem!
    let viewModel = ViewModel.shared
    let dataContainer = DataSchema.container
    var watchPanel: WatchPanel!
    private var _timer: Timer?
    var lastReloaded = Date.distantPast

    func applicationWillFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 0)
        statusItem.button?.action = #selector(self.toggleDisplay(sender:))
        statusItem.button?.sendAction(on: [.leftMouseDown])
        viewModel.autoSaveLayout()
        viewModel.autoSaveConfig()
        viewModel.autoSaveConfigName()
        AppDelegate.instance = self
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        update()
        watchPanel = {
            let watchFace = WatchFace()
                .modelContainer(dataContainer)
                .environment(viewModel)
            let setting = Setting()
                .frame(minWidth: 550, maxWidth: 700, minHeight: 350, maxHeight: 500)
                .modelContainer(dataContainer)
                .environment(viewModel)

            return WatchPanelHosting(watch: watchFace, setting: setting, statusItem: statusItem, baseLayout: viewModel.baseLayout, isPresented: false)
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
                let image = NSImage(resource: .appChinendar)
                button.image = image.withSymbolConfiguration(.init(pointSize: NSFont.systemFontSize, weight: .black, scale: .large))
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
        viewModel.updateChineseCalendar()
        updateStatusBar(dateText: statusBar(from: viewModel.chineseCalendar, options: viewModel.watchLayout))
    }
}

@Observable final class ViewModel: ViewModelType {
    static let shared = ViewModel()
    
    typealias Base = BaseLayout
    
    var watchLayout = WatchLayout(baseLayout: BaseLayout())
    var config = CalendarConfigure()
    var settings = WatchSetting()
    var chineseCalendar = ChineseCalendar()
    @ObservationIgnored let locationManager = LocationManager.shared
    private var _location: GeoLocation?
    
    private init() {
        self.setup()
    }
    
    var location: GeoLocation? {
        Task(priority: .userInitiated) {
            let gpsLoc = try await locationManager.getLocation(wait: .seconds(1))
            if gpsLoc != _location {
                _location = gpsLoc
            }
        }
        if config.locationEnabled {
            return _location ?? config.customLocation
        } else {
            return config.customLocation
        }
    }
    
    var gpsLocationAvailable: Bool {
        _location != nil && config.locationEnabled
    }
    
    func clearLocation() {
        _location = nil
        Task(priority: .userInitiated) {
            await locationManager.clearLocation()
        }
    }
    
    func autoSaveLayout() {
        withObservationTracking {
            _ = self.layoutString()
        } onChange: {
            Task { @MainActor in
                ThemeData.saveDefault(layout: self.layoutString())
                self.autoSaveLayout()
            }
        }
    }
    
    func autoSaveConfig() {
        withObservationTracking {
            _ = self.configString(withName: true)
        } onChange: {
            Task { @MainActor in
                let config = self.configString()
                ConfigData.save(name: self.config.name, config: config)
                self.autoSaveConfig()
            }
        }
    }
    
    func autoSaveConfigName() {
        withObservationTracking {
            _ = self.config.name
        } onChange: {
            Task { @MainActor in
                LocalData.update(configName: self.config.name)
                self.autoSaveConfigName()
            }
        }
    }
}
