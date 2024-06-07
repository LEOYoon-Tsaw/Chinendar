//
//  ContentView.swift
//  Chinendar
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI
import WidgetKit

struct WatchFaceTab<Tab: View>: View {
    @Environment(WatchSetting.self) var watchSetting
    let proxy: GeometryProxy
    let tab: Tab

    init(proxy: GeometryProxy, @ViewBuilder content: () -> Tab) {
        self.proxy = proxy
        self.tab = content()
    }

    var body: some View {
        TabView {
            tab
            NavigationStack {
                Setting()
            }
        }
        .tabViewStyle(VerticalPageTabViewStyle(transitionStyle: .blur))
        .onAppear {
            watchSetting.size = proxy.size
        }
    }
}

struct ContentView: View {
    @Environment(WatchLayout.self) var watchLayout
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(WatchConnectivityManager.self) var watchConnectivityManager

    var body: some View {
        GeometryReader { proxy in
            if watchLayout.dualWatch {
                WatchFaceTab(proxy: proxy) {
                    WatchFaceDate()
                        .ignoresSafeArea()
                    WatchFaceTime()
                        .ignoresSafeArea()
                }
            } else {
                WatchFaceTab(proxy: proxy) {
                    WatchFaceFull()
                        .ignoresSafeArea()
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                watchConnectivityManager.requestLayout()
            case .inactive, .background:
                WidgetCenter.shared.reloadAllTimelines()
            @unknown default:
                break
            }
        }
    }
}

#Preview("Watch Face") {
    let chineseCalendar = ChineseCalendar(compact: true)
    let locationManager = LocationManager()
    let watchLayout = WatchLayout()
    let calendarConfigure = CalendarConfigure()
    let watchSetting = WatchSetting()
    watchLayout.loadStatic()
    let watchConnectivity = WatchConnectivityManager(watchLayout: watchLayout, calendarConfigure: calendarConfigure, locationManager: locationManager)

    return ContentView()
    .modelContainer(DataSchema.container)
    .environment(chineseCalendar)
    .environment(locationManager)
    .environment(watchLayout)
    .environment(calendarConfigure)
    .environment(watchSetting)
    .environment(watchConnectivity)
}
