//
//  Setting.swift
//  Chinendar
//
//  Created by Leo Liu on 6/25/23.
//

import SwiftUI

struct Setting: View {
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        List {
            Section("LOC_TIME") {
                NavigationLink {
                    Datetime()
                } label: {
                    Label("DATETIME", systemImage: "clock")
                }
                NavigationLink {
                    Location()
                } label: {
                    Label("LAT&LON", systemImage: "location")
                }
                NavigationLink {
                    ConfigList()
                } label: {
                    Label("CALENDAR_LIST", systemImage: "globe")
                }
            }

            Section("DESIGN") {
                NavigationLink {
                    RingSetting()
                } label: {
                    Label("RING_COLORS", systemImage: "pencil.and.outline")
                }
                NavigationLink {
                    DecorationSetting()
                } label: {
                    Label("ADDON_COLORS", systemImage: "paintpalette")
                }
                NavigationLink {
                    ColorSetting()
                } label: {
                    Label("COLOR_MARKS", systemImage: "wand.and.stars")
                }
                NavigationLink {
                    LayoutSetting()
                } label: {
                    Label("LAYOUTS", systemImage: "square.resize")
                }
                NavigationLink {
                    ThemesList()
                } label: {
                    Label("THEME_LIST", systemImage: "archivebox")
                }
            }
            Section {
                NavigationLink {
                    Documentation()
                } label: {
                    Label("Q&A", systemImage: "doc.questionmark")
                }
            }
        }
        .navigationTitle("SETTINGS")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Button("DONE") {
                viewModel.settings.presentSetting = false
            }
            .fontWeight(.semibold)
        }
    }
}

#Preview("Settings", traits: .modifier(SampleData())) {
    NavigationStack {
        Setting()
    }
}
