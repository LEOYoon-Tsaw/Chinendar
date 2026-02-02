//
//  watchApp.swift
//  Chinendar
//
//  Created by Leo Liu on 5/3/23.
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
    let monitorPhoneUpdates: Task<Void, Error> = Task {
        for try await response in await WatchConnectivityManager.shared.stream {
            for (kind, data) in response {
                try await ViewModel.shared.updateFrom(kind: kind, data: data)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(viewModel)
        }
    }
}

@Observable final class ViewModel: ViewModelType {
    static let shared = ViewModel()

    let modelContainer: ModelContainer
    let themeData: LocalTheme
    let configData: LocalConfig
    var settings = WatchSetting()
    var chineseCalendar = ChineseCalendar(compact: true)
    @ObservationIgnored let watchConnectivity = WatchConnectivityManager.shared
    @ObservationIgnored let locationManager = LocationManager.shared
    var gpsLocation: GeoLocation?
    var error: (any Error)?

    private init() {
        modelContainer = LocalSchema.container
        themeData = LocalTheme.load(context: modelContainer.mainContext)
        configData = LocalConfig.load(context: modelContainer.mainContext)
        self.setup()
    }

    func requestFromPhone() async {
        if watchLayout.syncFromPhone {
            do {
                try await watchConnectivity.request([.config, .layout])
            } catch {
                print("Error in requestFromPhone():\n\(error.localizedDescription)")
            }
        }
    }

    func updateFrom(kind: WCMessageKind, data: Data) throws {
        if watchLayout.syncFromPhone {
            switch kind {
            case .layout:
                var layout = try WatchLayout(fromData: data)
                layout.baseLayout.offsets = baseLayout.offsets
                watchLayout.baseLayout = layout.baseLayout
            case .config:
                let config = try CalendarConfigure(fromData: data)
                self.config = config
                updateChineseCalendar()
            }
        }
    }
}
