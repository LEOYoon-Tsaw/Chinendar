//
//  watchApp.swift
//  Chinendar
//
//  Created by Leo Liu on 5/3/23.
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
            ContentView()
                .modelContainer(DataSchema.container)
                .environment(viewModel)
                .task {
                    self.viewModel.updateChineseCalendar()
                }
                .onReceive(timer) { _ in
                    self.viewModel.updateChineseCalendar()
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
    var chineseCalendar = ChineseCalendar(compact: true)
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
