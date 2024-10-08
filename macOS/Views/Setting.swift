//
//  Setting.swift
//  Chinendar
//
//  Created by Leo Liu on 6/30/23.
//

import SwiftUI
import WidgetKit
import StoreKit

struct Setting: View {
    @Environment(ViewModel.self) var viewModel
    @State private var selection: WatchSetting.Selection? = .none
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) var requestReview

    private var statusState: StatusState {
        StatusState(watchLayout: viewModel.watchLayout, calendarConfigure: viewModel.config, watchSetting: viewModel.settings)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                Section("LOC_TIME") {
                    ForEach([WatchSetting.Selection.datetime,
                             WatchSetting.Selection.location,
                             WatchSetting.Selection.configs], id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
                Section("DESIGN") {
                    ForEach([WatchSetting.Selection.ringColor,
                             WatchSetting.Selection.decoration,
                             WatchSetting.Selection.markColor,
                             WatchSetting.Selection.layout,
                             WatchSetting.Selection.themes], id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
                Section {
                    ForEach([WatchSetting.Selection.documentation], id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
            }
        } detail: {
            switch selection {
            case .datetime:
                Datetime()
            case .location:
                Location()
            case .configs:
                ConfigList()
            case .ringColor:
                RingSetting()
            case .decoration:
                DecorationSetting()
            case .markColor:
                ColorSetting()
            case .layout:
                LayoutSetting()
            case .themes:
                ThemesList()
            case .documentation:
                Documentation()
            case .none:
                EmptyView()
            }
        }
        .animation(.easeInOut, value: columnVisibility)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    if columnVisibility != .detailOnly {
                        columnVisibility = .detailOnly
                    } else {
                        columnVisibility = .all
                    }
                } label: {
                    Image(systemName: "sidebar.leading")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task(id: selection) {
            if selection == .none {
                selection = viewModel.settings.previousSelection ?? .datetime
            } else {
                viewModel.settings.previousSelection = selection
            }
            cleanColorPanel()
        }
        .task {
            if ThemeData.experienced() {
                requestReview()
            }
        }
        .onChange(of: statusState) {
            if let delegate = AppDelegate.instance {
                delegate.updateStatusBar(dateText: delegate.statusBar(from: viewModel.chineseCalendar, options: viewModel.watchLayout))
            }
        }
        .onDisappear {
            selection = .none
            WidgetCenter.shared.reloadAllTimelines()
            AppDelegate.instance?.lastReloaded = .now
            cleanColorPanel()
        }
    }

    func buildView(selection: WatchSetting.Selection) -> some View {
        let sel = switch selection {
        case .datetime:
            Label("DATETIME", systemImage: "clock")
        case .location:
            Label("LAT&LON", systemImage: "location")
        case .configs:
            Label("CALENDAR_LIST", systemImage: "globe")
        case .ringColor:
            Label("RING_COLORS", systemImage: "pencil.and.outline")
        case .decoration:
            Label("ADDON_COLORS", systemImage: "paintpalette")
        case .markColor:
            Label("COLOR_MARKS", systemImage: "wand.and.stars")
        case .layout:
            Label("LAYOUTS", systemImage: "square.resize")
        case .themes:
            Label("THEME_LIST", systemImage: "archivebox")
        case .documentation:
            Label("Q&A", systemImage: "doc.questionmark")
        }
        return sel
    }

    @MainActor func cleanColorPanel() {
        NSColorPanel.shared.setTarget(nil)
        NSColorPanel.shared.setAction(nil)
        NSColorPanel.shared.close()
    }
}

#Preview("Settings", traits: .modifier(SampleData())) {
    Setting()
}
