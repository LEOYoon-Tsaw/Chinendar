//
//  Settings.swift
//  Chinendar
//
//  Created by Leo Liu on 11/13/23.
//

import SwiftUI
import StoreKit

struct Setting: View {
    @Environment(WatchLayout.self) var watchLayout
    @Environment(WatchSetting.self) var watchSetting
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) var requestReview
    @State private var selection: WatchSetting.Selection?
    @State private var selectedTab: WatchSetting.TabSelection = .spaceTime
    let spaceTimePages: [WatchSetting.Selection] = [.datetime, .location, .configs]
    let designPages: [WatchSetting.Selection] = [.ringColor, .decoration, .markColor,.layout, .themes]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationSplitView {
                List(selection: $selection) {
                    ForEach(spaceTimePages, id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
                .navigationTitle("時空")
                .task(id: selection) {
                    if selection == .none || !spaceTimePages.contains(selection!) {
                        selection = watchSetting.previousSelectionSpaceTime ?? .datetime
                    } else {
                        watchSetting.previousSelectionSpaceTime = selection
                    }
                }
            } detail: {
                switch selection {
                case .datetime:
                    NavigationStack {
                        Datetime()
                    }
                case .location:
                    NavigationStack {
                        Location()
                    }
                case .configs:
                    NavigationStack {
                        ConfigList()
                    }
                default:
                    EmptyView()
                }
            }
            .tag(WatchSetting.TabSelection.spaceTime)
            .tabItem {
                Label("時空", systemImage: "globe.desk")
            }
            .navigationSplitViewColumnWidth(ideal: 200)
            
            NavigationSplitView {
                List(selection: $selection) {
                    ForEach(designPages, id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
                .navigationTitle("設計")
                .task(id: selection) {
                    if selection == .none || !designPages.contains(selection!) {
                        selection = watchSetting.previousSelectionDesign ?? .ringColor
                    } else {
                        watchSetting.previousSelectionDesign = selection
                    }
                }
            } detail: {
                switch selection {
                case .ringColor:
                    NavigationStack {
                        RingSetting()
                    }
                case .decoration:
                    NavigationStack {
                        DecorationSetting()
                    }
                case .markColor:
                    NavigationStack {
                        ColorSetting()
                    }
                case .layout:
                    NavigationStack {
                        LayoutSetting()
                    }
                case .themes:
                    NavigationStack {
                        ThemesList()
                    }
                default:
                    EmptyView()
                }
            }
            .tag(WatchSetting.TabSelection.design)
            .tabItem {
                Label("設計", systemImage: "paintbrush")
            }
            .navigationSplitViewColumnWidth(ideal: 200)
            
            NavigationStack {
                Documentation()
            }
            .tag(WatchSetting.TabSelection.documentation)
            .tabItem {
                Label("註釋", systemImage: "doc.questionmark")
            }
        }
        .task {
            selectedTab = watchSetting.previousTabSelection ?? .spaceTime
        }
        .task(id: selectedTab) {
            watchSetting.previousTabSelection = selectedTab
        }
        .onDisappear {
            watchSetting.settingIsOpen = false
            if ThemeData.experienced() {
                requestReview()
            }
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
        }
        return sel
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
