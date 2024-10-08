//
//  Settings.swift
//  Chinendar
//
//  Created by Leo Liu on 11/13/23.
//

import SwiftUI

struct Setting: View {
    @Environment(ViewModel.self) var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var selection: WatchSetting.Selection?
    @State private var selectedTab: WatchSetting.TabSelection = .spaceTime
    let spaceTimePages: [WatchSetting.Selection] = [.datetime, .location, .configs]
    let designPages: [WatchSetting.Selection] = [.ringColor, .decoration, .markColor, .layout, .themes]

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationSplitView {
                List(selection: $selection) {
                    ForEach(spaceTimePages, id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
                .navigationTitle("LOC_TIME")
                .task(id: selection) {
                    if selection == .none || !spaceTimePages.contains(selection!) {
                        selection = viewModel.settings.previousSelectionSpaceTime ?? .datetime
                    } else {
                        viewModel.settings.previousSelectionSpaceTime = selection
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
                Label("LOC_TIME", systemImage: "globe.desk")
            }
            .navigationSplitViewColumnWidth(ideal: 200)

            NavigationSplitView {
                List(selection: $selection) {
                    ForEach(designPages, id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
                .navigationTitle("DESIGN")
                .task(id: selection) {
                    if selection == .none || !designPages.contains(selection!) {
                        selection = viewModel.settings.previousSelectionDesign ?? .ringColor
                    } else {
                        viewModel.settings.previousSelectionDesign = selection
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
                Label("DESIGN", systemImage: "paintbrush")
            }
            .navigationSplitViewColumnWidth(ideal: 200)

            NavigationStack {
                Documentation()
            }
            .tag(WatchSetting.TabSelection.documentation)
            .tabItem {
                Label("Q&A", systemImage: "doc.questionmark")
            }
        }
        .task {
            selectedTab = viewModel.settings.previousTabSelection ?? .spaceTime
        }
        .task(id: selectedTab) {
            viewModel.settings.previousTabSelection = selectedTab
        }
        .onDisappear {
            viewModel.settings.settingIsOpen = false
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
        }
        return sel
    }
}

#Preview("Settings", traits: .modifier(SampleData())) {
    Setting()
}
