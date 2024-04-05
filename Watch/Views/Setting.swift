//
//  Setting.swift
//  Chinendar
//
//  Created by Leo Liu on 6/26/23.
//

import SwiftUI

struct Setting: View {
    @Environment(WatchLayout.self) var watchLayout
    @Environment(\.modelContext) var modelContext
    let range: ClosedRange<CGFloat> = 0.3...0.9
    let step: CGFloat = 0.1
    var dualWatch: Binding<Bool> {
        .init(get: { watchLayout.dualWatch }, set: { newValue in
            watchLayout.dualWatch = newValue
        })
    }
    var cornerRadius: Binding<CGFloat> {
        .init(get: { watchLayout.cornerRadiusRatio }, set: { newValue in
            watchLayout.cornerRadiusRatio = newValue
        })
    }
    
    var body: some View {
        List {
            Section {
                Stepper(value: cornerRadius, in: range, step: step) {
                    Text(String(format: "%.1f", cornerRadius.wrappedValue))
                        .font(.title.bold())
                        .fontDesign(.rounded)
                }
                .focusable(false)
            } header: {
                Text("圓角比例", comment: "Corner radius ratio")
            }
            
            Section {
                NavigationLink {
                    DateTimeAdjust()
                } label: {
                    Text("調時")
                }
                NavigationLink {
                    SwitchConfig()
                } label: {
                    Text("日曆墻")
                }
                Toggle(NSLocalizedString("分列日時", comment: "Split Date and Time"), isOn: dualWatch)
            } footer: {
                Text("更多設置請移步 iOS App，可於手機與手錶間自動同步", comment: "Hint for syncing between watch and phone")
            }
        }
        .navigationTitle(Text("設置", comment: "Settings View"))
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview("Setting") {
    let chineseCalendar = ChineseCalendar(compact: true)
    let locationManager = LocationManager()
    let watchLayout = WatchLayout()
    let calendarConfigure = CalendarConfigure()
    let watchSetting = WatchSetting()
    watchLayout.loadStatic()

    return NavigationStack {
        Setting()
    }
    .modelContainer(DataSchema.container)
    .environment(chineseCalendar)
    .environment(locationManager)
    .environment(watchLayout)
    .environment(calendarConfigure)
    .environment(watchSetting)
}
