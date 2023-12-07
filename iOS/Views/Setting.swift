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
            Section(header: Text("數據", comment: "Data Source")) {
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
            
            Section(header: Text("樣式", comment: "Styles")) {
                NavigationLink{
                    RingSetting()
                } label: {
                    Label {
                        Text("輪色", comment: "Rings Color Setting")
                    } icon: {
                        Image(systemName: "pencil.and.outline")
                    }
                }
                NavigationLink {
                    ColorSetting()
                } label: {
                    Label {
                        Text("色塊", comment: "Mark Color settings")
                    } icon: {
                        Image(systemName: "wand.and.stars")
                    }
                }
                NavigationLink {
                    LayoutSetting()
                } label: {
                    Label {
                        Text("佈局", comment: "Layout settings section")
                    } icon: {
                        Image(systemName: "square.resize")
                    }
                }
            }
            Section(header: Text("其它", comment: "Miscellaneous")) {
                NavigationLink {
                    ThemesList()
                } label: {
                    Label {
                        Text("主題庫", comment: "manage saved themes")
                    } icon: {
                        Image(systemName: "archivebox")
                    }
                }
                NavigationLink {
                    Documentation()
                } label: {
                    Label {
                        Text("註釋", comment: "Documentation View")
                    } icon: {
                        Image(systemName: "doc.questionmark")
                    }
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
