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
    @Environment(WatchLayout.self) var watchLayout
    @Environment(CalendarConfigure.self) var calendarConfigure
    @Environment(WatchSetting.self) var watchSetting
    @Environment(ChineseCalendar.self) var chineseCalendar
    @Environment(LocationManager.self) var locationManager
    @State private var selection: WatchSetting.Selection? = .none
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) var requestReview

    private var statusState: StatusState {
        StatusState(locationManager: locationManager, watchLayout: watchLayout, calendarConfigure: calendarConfigure, watchSetting: watchSetting)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                Section("時空") {
                    ForEach([WatchSetting.Selection.datetime,
                             WatchSetting.Selection.location,
                             WatchSetting.Selection.configs], id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
                Section("設計") {
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
                selection = watchSetting.previousSelection ?? .datetime
            } else {
                watchSetting.previousSelection = selection
            }
            cleanColorPanel()
        }
        .onChange(of: statusState) {
            if let delegate = AppDelegate.instance {
                delegate.updateStatusBar(dateText: delegate.statusBar(from: chineseCalendar, options: watchLayout))
            }
        }
        .onAppear {
            if ThemeData.experienced() {
                requestReview()
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
            Label("日時", systemImage: "clock")
        case .location:
            Label("經緯度", systemImage: "location")
        case .configs:
            Label("日曆墻", systemImage: "globe")
        case .ringColor:
            Label("輪色", systemImage: "pencil.and.outline")
        case .decoration:
            Label("裝飾", systemImage: "paintpalette")
        case .markColor:
            Label("色塊", systemImage: "wand.and.stars")
        case .layout:
            Label("佈局", systemImage: "square.resize")
        case .themes:
            Label("主題庫", systemImage: "archivebox")
        case .documentation:
            Label("註釋", systemImage: "doc.questionmark")
        }
        return sel
    }

    @MainActor func cleanColorPanel() {
        NSColorPanel.shared.setTarget(nil)
        NSColorPanel.shared.setAction(nil)
        NSColorPanel.shared.close()
    }
}

#Preview("Settings") {
    let chineseCalendar = ChineseCalendar()
    let locationManager = LocationManager()
    let watchLayout = WatchLayout()
    let calendarConfigure = CalendarConfigure()
    let watchSetting = WatchSetting()
    watchLayout.loadStatic()

    return Setting()
        .modelContainer(DataSchema.container)
        .environment(chineseCalendar)
        .environment(locationManager)
        .environment(watchLayout)
        .environment(calendarConfigure)
        .environment(watchSetting)
}
