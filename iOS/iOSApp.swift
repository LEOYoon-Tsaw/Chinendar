//
//  iOSApp.swift
//  Chinendar
//
//  Created by Leo Liu on 4/17/23.
//

import SwiftUI
import SwiftData

@main
struct Chinendar: App {
    let viewModel = ViewModel.shared
    let modelContainer = DataSchema.container
    let refreshWatch: Task<Void, Never> = Task {
        while !Task.isCancelled {
            await ViewModel.shared.updateChineseCalendar()
            try? await Task.sleep(for: .seconds(ChineseCalendar.updateInterval))
        }
    }

    init() {
        viewModel.observationTokens.autoSendLayout = withContinuousObservation(options: .didSet) { [weak viewModel] _ in
            if let layoutData = try? viewModel?.watchLayout.encode() {
                Task.detached {
                    try? await WatchConnectivityManager.shared.respond([
                        .layout: layoutData
                    ])
                }
            }
        }

        viewModel.observationTokens.autoSendConfig = withContinuousObservation(options: .didSet) { [weak viewModel] _ in
            if let configData = try? viewModel?.config.encode() {
                Task.detached {
                    try? await WatchConnectivityManager.shared.respond([
                        .config: configData
                    ])
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchFace()
                .modelContainer(modelContainer)
                .environment(viewModel)
        }
    }
}

@Observable final class ViewModel: ViewModelType {
    static let shared = ViewModel()

    let observationTokens = ObservationTokens()
    let modelContainer: ModelContainer
    let themeData: LocalTheme
    let configData: LocalConfig
    var settings = WatchSetting()
    var chineseCalendar = ChineseCalendar()
    @ObservationIgnored let watchConnectivity = WatchConnectivityManager.shared
    @ObservationIgnored let locationManager = LocationManager.shared
    @ObservationIgnored var locatingTask: Task<Void, Error>?
    var gpsLocation: GeoLocation?
    var error: (any Error)?

    private init() {
        modelContainer = LocalSchema.container
        themeData = LocalTheme.load(context: modelContainer.mainContext)
        configData = LocalConfig.load(context: modelContainer.mainContext)
        self.setup()
    }
}

final class ObservationTokens: DefaultObservationTokens {
    var autoupdateChineseCalendar: ObservationTracking.Token?
    var autoSendLayout: ObservationTracking.Token?
    var autoSendConfig: ObservationTracking.Token?
}
