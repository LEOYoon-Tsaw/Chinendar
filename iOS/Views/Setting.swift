//
//  Setting.swift
//  Chinendar
//
//  Created by Leo Liu on 6/25/23.
//

import SwiftUI

struct Setting: View {
    @State var locationManager = LocationManager.shared
    @Environment(\.chineseCalendar) var chineseCalendar
    @Environment(\.watchSetting) var watchSetting
    @Environment(\.watchLayout) var watchLayout

    var body: some View {
        List {
            Section("時空") {
                NavigationLink {
                    Datetime()
                } label: {
                    HStack {
                        Label {
                            Text("日時", comment: "Display time settings")
                        } icon: {
                            Image(systemName: "clock")
                        }
                        Spacer()
                            let timezone = watchSetting.timezone ?? Calendar.current.timeZone
                        Text("\((watchSetting.displayTime ?? chineseCalendar.time).formatted(date: .numeric, time: .shortened)) \(timezone.localizedName(for: .generic, locale: Locale.current) ?? "")")
                                .minimumScaleFactor(0.75)
                                .foregroundStyle(.secondary)
                                .frame(alignment: .leading)
                    }
                }

                NavigationLink {
                    Location()
                    
                } label: {
                    HStack {
                        Label {
                            Text("經緯度", comment: "Geo Location section")
                        } icon: {
                            Image(systemName: "location")
                        }
                        Spacer()
                        if let location = locationManager.location ?? watchLayout.location {
                            let (lat, lon) = coordinateDesp(coordinate: location)
                            Text("\(lat), \(lon)")
                                .privacySensitive()
                                .minimumScaleFactor(0.75)
                                .foregroundStyle(.secondary)
                                .frame(alignment: .leading)
                        }
                    }
                }
            }
            
            Section("設計") {
                NavigationLink{
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
                watchSetting.presentSetting = false
            }
            .fontWeight(.semibold)
        }
    }
}

#Preview("Settings") {
    NavigationStack {
        Setting()
    }
}
