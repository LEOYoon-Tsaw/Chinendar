//
//  iOSApp.swift
//  Chinendar
//
//  Created by Leo Liu on 4/17/23.
//

import SwiftUI

@main
struct Chinendar: App {
    let viewModel = ViewModel.shared
    let timer = Timer.publish(every: ChineseCalendar.updateInterval, on: .main, in: .common).autoconnect()

    init() {
        viewModel.autoSaveLayout()
        viewModel.autoSaveConfig()
        viewModel.autoSaveConfigName()
    }

    var body: some Scene {
        WindowGroup {
            WatchFace()
                .modelContainer(DataSchema.container)
                .environment(viewModel)
                .task {
                    viewModel.updateChineseCalendar()
                }
                .onReceive(timer) { _ in
                    viewModel.updateChineseCalendar()
                }
        }
    }
}

@Observable final class ViewModel: ViewModelType {
    static let shared = ViewModel()

    typealias Base = BaseLayout

    var watchLayout = WatchLayout(baseLayout: BaseLayout())
    var config = CalendarConfigure()
    var settings = WatchSetting()
    var chineseCalendar = ChineseCalendar()
    @ObservationIgnored lazy var watchConnectivity = WatchConnectivityManager(viewModel: self)
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
                let layout = self.layoutString()
                ThemeData.saveDefault(layout: self.layoutString())
                await self.watchConnectivity.send(messages: ["layout": layout])
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
                await self.watchConnectivity.send(messages: ["config": config])
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
