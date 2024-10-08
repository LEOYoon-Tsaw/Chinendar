//
//  ContentView.swift
//  Chinendar
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI
import WidgetKit

struct WatchFaceTab<Tab: View>: View {
    @Environment(ViewModel.self) var viewModel
    let proxy: GeometryProxy
    let tab: Tab

    init(proxy: GeometryProxy, @ViewBuilder content: () -> Tab) {
        self.proxy = proxy
        self.tab = content()
    }

    var body: some View {
        NavigationStack {
            TabView {
                tab
                Setting()
            }
        }
        .tabViewStyle(VerticalPageTabViewStyle(transitionStyle: .blur))
        .onAppear {
            viewModel.settings.size = proxy.size
        }
    }
}

struct ContentView: View {
    @Environment(ViewModel.self) var viewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        GeometryReader { proxy in
            if viewModel.watchLayout.dualWatch {
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
        .task(id: scenePhase) {
            switch scenePhase {
            case .active:
                await viewModel.watchConnectivity.requestLayout()
            case .inactive, .background:
                WidgetCenter.shared.reloadAllTimelines()
            @unknown default:
                break
            }
        }
    }
}

#Preview("Watch Face", traits: .modifier(SampleData())) {
    ContentView()
}
