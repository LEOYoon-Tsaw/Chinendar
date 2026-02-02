//
//  visionApp.swift
//  Chinendar
//
//  Created by Leo Liu on 11/5/23.
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
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    init() {
        autoUpdateStatusBar()
    }

    var body: some Scene {
        WindowGroup(id: "WatchFace") {
            WatchFace()
                .padding(15)
                .modelContainer(modelContainer)
                .environment(viewModel)
                .ornament(attachmentAnchor: .scene(.bottom)) {
                    ornament
                }
        }
        .defaultSize(width: viewModel.baseLayout.offsets.watchSize.width + 30, height: viewModel.baseLayout.offsets.watchSize.height + 30)
        .windowResizability(.contentSize)

        WindowGroup(id: "Settings") {
            Setting()
                .modelContainer(modelContainer)
                .environment(viewModel)
        }
        .defaultSize(width: 900, height: 700)
    }

    var ornament: some View {
        HStack(spacing: 0) {
            if viewModel.settings.timeDisplay.count > 0 {
                Text(viewModel.settings.timeDisplay)
                    .padding()
                    .lineLimit(1)
            }
            Button {
                if viewModel.settings.settingIsOpen {
                    dismissWindow(id: "Settings")
                } else {
                    openWindow(id: "Settings")
                }
            } label: {
                if viewModel.settings.timeDisplay.count > 0 {
                    Label("SETTINGS", systemImage: "gear")
                        .labelStyle(.iconOnly)
                } else {
                    Label("SETTINGS", systemImage: "gear")
                        .labelStyle(.titleAndIcon)
                }
            }
            .buttonStyle(.borderless)
        }
        .glassBackgroundEffect()
        .alignmentGuide(VerticalAlignment.center) { _ in 15 }
    }

    func updateStatusBar() {
        let dateText = statusBarString(from: viewModel.chineseCalendar, options: viewModel.watchLayout)
        if viewModel.settings.timeDisplay != dateText {
            viewModel.settings.timeDisplay = dateText
        }
    }

    @MainActor
    func autoUpdateStatusBar() {
        withObservationTracking {
            updateStatusBar()
        } onChange: {
            Task {
                await self.autoUpdateStatusBar()
            }
        }
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
