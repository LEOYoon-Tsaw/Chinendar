//
//  ContentView.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI
import WidgetKit

struct WatchFaceTab<Tab: View>: View {
    @Environment(\.watchSetting) var watchSetting
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
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext

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
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                WatchConnectivityManager.shared.requestLayout()
            case .inactive, .background:
                WidgetCenter.shared.reloadAllTimelines()
            @unknown default:
                break
            }
        }
    }
}

#Preview("Watch Face") {
    ContentView()
        .environment(\.chineseCalendar, .init(time: .now, compact: true))
        .modelContainer(ThemeData.container)
}
