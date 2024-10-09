//
//  visionApp.swift
//  Chinendar
//
//  Created by Leo Liu on 11/5/23.
//

import SwiftUI

@main
struct Chinendar: App {
    let viewModel = ViewModel.shared
    let timer = Timer.publish(every: ChineseCalendar.updateInterval, on: .main, in: .common).autoconnect()
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    private var statusState: StatusState {
        StatusState(watchLayout: viewModel.watchLayout, calendarConfigure: viewModel.config, watchSetting: viewModel.settings)
    }

    init() {
        viewModel.autoSaveLayout()
        viewModel.autoSaveConfig()
        viewModel.autoSaveConfigName()
    }

    var body: some Scene {
        WindowGroup(id: "WatchFace") {
            WatchFace()
                .padding(15)
                .modelContainer(DataSchema.container)
                .environment(viewModel)
                .task {
                    self.update()
                }
                .onReceive(timer) { _ in
                    self.update()
                }
                .ornament(attachmentAnchor: .scene(.bottom)) {
                    HStack(spacing: 0) {
                        if viewModel.settings.timeDisplay.count > 0 {
                            Text(viewModel.settings.timeDisplay)
                                .padding()
                        }
                        Button {
                            viewModel.settings.settingIsOpen.toggle()
                        } label: {
                            if viewModel.settings.timeDisplay.count > 0 {
                                Label("SETTINGS", systemImage: "gear")
                                    .labelStyle(.iconOnly)
                            } else {
                                Label("SETTINGS", systemImage: "gear")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                        .onChange(of: viewModel.settings.settingIsOpen) {
                            if viewModel.settings.settingIsOpen {
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
        .defaultSize(width: viewModel.baseLayout.watchSize.width + 30, height: viewModel.baseLayout.watchSize.height + 30)
        .windowResizability(.contentSize)

        WindowGroup(id: "Settings") {
            Setting()
                .modelContainer(DataSchema.container)
                .environment(viewModel)
                .onChange(of: statusState) {
                    viewModel.settings.timeDisplay = String(statusBar(from: viewModel.chineseCalendar, options: viewModel.watchLayout).reversed())
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
        viewModel.updateChineseCalendar()
        viewModel.settings.timeDisplay = String(statusBar(from: viewModel.chineseCalendar, options: viewModel.watchLayout).reversed())
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
    var gpsLocation: GeoLocation?

    private init() {
        self.setup()
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
