//
//  macApp.swift
//  Chinendar
//
//  Created by Leo Liu on 9/19/21.
//

import SwiftUI
import WidgetKit
import SwiftData

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
    var statusItem: NSStatusItem!
    let viewModel = ViewModel.shared
    let modelContainer = DataSchema.container
    var watchPanel: WatchPanel!
    private var _timer: Timer?
    var lastReloaded = Date.distantPast
    let notificationManager = NotificationManager.shared

    func applicationWillFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 0)
        statusItem.button?.action = #selector(self.toggleDisplay(sender:))
        statusItem.button?.sendAction(on: [.leftMouseDown])
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        watchPanel = {
            let watchFace = WatchFace()
                .modelContainer(modelContainer)
                .environment(viewModel)
            let setting = Setting()
                .frame(minWidth: 550, maxWidth: 700, minHeight: 350, maxHeight: 500)
                .modelContainer(modelContainer)
                .environment(viewModel)

            return WatchPanelHosting(watch: watchFace, setting: setting, statusItem: statusItem, viewModel: viewModel, isPresented: false)
        }()
        _timer = Timer.scheduledTimer(withTimeInterval: ChineseCalendar.updateInterval, repeats: true) { _ in
            Task { @MainActor in
                self.viewModel.updateChineseCalendar()
            }
        }
        autoUpdateStatusBar()
        Task {
            await notificationManager.clearNotifications()
            try await notificationManager.addNotifications(chineseCalendar: viewModel.chineseCalendar)
        }
    }

    func applicationWillResignActive(_ notification: Notification) {
        watchPanel.isPresented = false
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if lastReloaded.distance(to: .now) > 1800 { // Half Hour
            Task {
                try? viewModel.modelContainer.mainContext.save()
                WidgetCenter.shared.reloadAllTimelines()
                lastReloaded = .now
            }
        }
        _timer?.invalidate()
        _timer = nil
    }

    @objc func toggleDisplay(sender: NSStatusItem) {
        watchPanel.isPresented.toggle()
        if watchPanel.isPresented && lastReloaded.distance(to: .now) > 7200 { // 2 Hours
            Task {
                try? viewModel.modelContainer.mainContext.save()
                WidgetCenter.shared.reloadAllTimelines()
                lastReloaded = .now
            }
        }
    }

    func updateStatusBar() {
        if let button = statusItem.button {
            let dateText = statusBar(from: viewModel.chineseCalendar, options: viewModel.watchLayout)
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

    func autoUpdateStatusBar() {
        withObservationTracking {
            updateStatusBar()
        } onChange: {
            Task { @MainActor in
                self.autoUpdateStatusBar()
            }
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
        return displayText.joined(separator: watchLayout.statusBar.separator.rawValue)
    }
}

@Observable final class ViewModel: ViewModelType {
    static let shared = ViewModel()

    let modelContainer: ModelContainer
    let themeData: LocalTheme
    let configData: LocalConfig
    var settings = WatchSetting()
    var chineseCalendar = ChineseCalendar()
    @ObservationIgnored let locationManager = LocationManager.shared
    var gpsLocation: GeoLocation?
    var error: (any Error)?

    private init() {
        modelContainer = LocalSchema.container
        themeData = LocalTheme.load(context: modelContainer.mainContext)
        configData = LocalConfig.load(context: modelContainer.mainContext)
        self.setup()
    }
}
