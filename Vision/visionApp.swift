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
        .defaultWindowPlacement { root, context in
            let size = root.sizeThatFits(.init(.init(width: 900, height: 700)))
            for window in context.windows where window.id == "WatchFace" {
                return .init(.trailing(window), size: size)
            }
            return .init(size: size)
        }
        .restorationBehavior(.disabled)
    }

    var ornament: some View {
        HStack(spacing: 0) {
            let dateText = statusBarString(from: viewModel.chineseCalendar, options: viewModel.watchLayout)
            if dateText.count > 0 {
                Text(dateText)
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
                let label = Label("SETTINGS", systemImage: "gear")
                if dateText.isEmpty {
                    label
                        .labelStyle(.titleAndIcon)
                } else {
                    label
                        .labelStyle(.iconOnly)
                }
            }
            .buttonStyle(.borderless)
        }
        .glassBackgroundEffect()
        .alignmentGuide(VerticalAlignment.center) { _ in 15 }
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
