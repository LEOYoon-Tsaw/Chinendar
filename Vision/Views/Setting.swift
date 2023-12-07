//
//  Settings.swift
//  Chinendar
//
//  Created by Leo Liu on 11/13/23.
//

import SwiftUI

struct Setting: View {
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            NavigationStack {
                Datetime()
            }
                .tabItem {
                    Label("日時", systemImage: "clock")
                }
            NavigationStack {
                Location()
            }
                .tabItem {
                    Label("經緯度", systemImage: "location")
                }
            NavigationStack {
                RingSetting()
            }
                .tabItem {
                    Label("輪色", systemImage: "pencil.and.outline")
                }
            NavigationStack {
                ColorSetting()
            }
                .tabItem {
                    Label("色塊", systemImage: "wand.and.stars")
                }
            NavigationStack {
                LayoutSetting()
            }
                .tabItem {
                    Label("佈局", systemImage: "square.resize")
                }
            NavigationStack {
                ThemesList()
            }
                .tabItem {
                    Label("主題庫", systemImage: "archivebox")
                }
            NavigationStack {
                Documentation()
            }
                .tabItem {
                    Label("註釋", systemImage: "doc.questionmark")
                }
        }
        .onDisappear {
            watchLayout.saveDefault(context: modelContext)
        }
    }
}

#Preview("Settings") {
    let watchLayout = WatchLayout.shared
    let watchSetting = WatchSetting.shared
    
    return Setting()
        .environment(watchLayout)
        .environment(watchSetting)
}
