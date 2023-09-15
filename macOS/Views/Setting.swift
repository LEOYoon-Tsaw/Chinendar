//
//  SwiftUIView.swift
//  Chinese Time
//
//  Created by Leo Liu on 6/30/23.
//

import SwiftUI
import WidgetKit

struct Setting: View {
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
    @State private var selection: WatchSetting.Selection? = .none
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                Section(header: Text("數據", comment: "Data Source")) {
                    ForEach([WatchSetting.Selection.datetime, WatchSetting.Selection.location], id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
                Section(header: Text("樣式", comment: "Styles")) {
                    ForEach([WatchSetting.Selection.ringColor, WatchSetting.Selection.markColor, WatchSetting.Selection.layout], id: \.self) { selection in
                        buildView(selection: selection)
                    }
                }
                Section(header: Text("其它", comment: "Miscellaneous")) {
                    ForEach([WatchSetting.Selection.themes, WatchSetting.Selection.documentation], id: \.self) { selection in
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
            case .ringColor:
                RingSetting()
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
        .onChange(of: selection) { _, _ in
            cleanColorPanel()
        }
        .onAppear {
            selection = watchSetting.previousSelection ?? .datetime
        }
        .onDisappear {
            watchSetting.previousSelection = selection
            selection = .none
            watchLayout.saveDefault(context: modelContext)
            WidgetCenter.shared.reloadAllTimelines()
            AppDelegate.instance?.lastReloaded = .now
            cleanColorPanel()
        }
    }
    
    func buildView(selection: WatchSetting.Selection) -> some View {
        let sel = switch selection {
        case .datetime:
            Label {
                Text("日時", comment: "Display time settings")
            } icon: {
                Image(systemName: "clock")
            }
        case .location:
            Label {
                Text("經緯度", comment: "Geo Location section")
            } icon: {
                Image(systemName: "location")
            }
        case .ringColor:
            Label {
                Text("輪色", comment: "Rings Color Setting")
            } icon: {
                Image(systemName: "pencil.and.outline")
            }
        case .markColor:
            Label {
                Text("色塊", comment: "Mark Color settings")
            } icon: {
                Image(systemName: "wand.and.stars")
            }
        case .layout:
            Label {
                Text("佈局", comment: "Layout settings section")
            } icon: {
                Image(systemName: "square.resize")
            }
        case .themes:
            Label {
                Text("主題庫", comment: "manage saved themes")
            } icon: {
                Image(systemName: "archivebox")
            }
        case .documentation:
            Label {
                Text("註釋", comment: "Documentation View")
            } icon: {
                Image(systemName: "doc.questionmark")
            }
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
    Setting()
}
