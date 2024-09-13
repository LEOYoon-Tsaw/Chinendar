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
            Section("時空") {
                NavigationLink {
                    Datetime()
                } label: {
                    Label("日時", systemImage: "clock")
                }
                NavigationLink {
                    Location()
                } label: {
                    Label("經緯度", systemImage: "location")
                }
                NavigationLink {
                    ConfigList()
                } label: {
                    Label("日曆墻", systemImage: "globe")
                }
            }

            Section("設計") {
                NavigationLink {
                    RingSetting()
                } label: {
                    Label("輪色", systemImage: "pencil.and.outline")
                }
                NavigationLink {
                    DecorationSetting()
                } label: {
                    Label("裝飾", systemImage: "paintpalette")
                }
                NavigationLink {
                    ColorSetting()
                } label: {
                    Label("色塊", systemImage: "wand.and.stars")
                }
                NavigationLink {
                    LayoutSetting()
                } label: {
                    Label("佈局", systemImage: "square.resize")
                }
                NavigationLink {
                    ThemesList()
                } label: {
                    Label("主題庫", systemImage: "archivebox")
                }
            }
            Section {
                NavigationLink {
                    Documentation()
                } label: {
                    Label("註釋", systemImage: "doc.questionmark")
                }
            }
        }
        .navigationTitle(Text("設置", comment: "Settings View"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
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
