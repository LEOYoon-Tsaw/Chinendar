//
//  ContentView.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var locationManager = LocationManager.shared
    @StateObject var watchLayout = WatchLayout.shared

    let timer = Timer.publish(every: Watch.updateInterval, on: .main, in: .common).autoconnect()
    @State var cornerRadius: CGFloat = 0
    @State var adjustTime: Date?
    @State var adjustTimeTarget: Bool = true
    @State var size: CGSize = .zero
    @State var refresh = false
    @State var displayTime: Date?
    @State var dual: Bool = false

    var body: some View {
        return GeometryReader { proxy in
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if dual {
                            DualWatch(compact: true, refresh: refresh,
                                      watchLayout: watchLayout, displayTime: displayTime, timezone: Calendar.current.timeZone, realLocation: locationManager.location)
                                .frame(width: size.width, height: size.height)
                                .navigationTitle(NSLocalizedString("華曆", comment: "App Name"))
                                .navigationBarTitleDisplayMode(.inline)
                                .onReceive(timer) { _ in
                                    refresh.toggle()
                                }
                                .onChange(of: scenePhase) { newPhase in
                                    if newPhase == .active {
                                        WatchConnectivityManager.shared.requestLayout()
                                        WidgetCenter.shared.reloadAllTimelines()
                                    }
                                }
                                .onAppear {
                                    locationManager.requestLocation(completion: nil)
                                }
                        } else {
                            Watch(compact: true, refresh: refresh,
                                  watchLayout: watchLayout, displayTime: displayTime, timezone: Calendar.current.timeZone, realLocation: locationManager.location)
                                .frame(width: size.width, height: size.height)
                                .navigationTitle(NSLocalizedString("華曆", comment: "App Name"))
                                .navigationBarTitleDisplayMode(.inline)
                                .onReceive(timer) { _ in
                                    refresh.toggle()
                                }
                                .onChange(of: scenePhase) { newPhase in
                                    if newPhase == .active {
                                        WatchConnectivityManager.shared.requestLayout()
                                        WidgetCenter.shared.reloadAllTimelines()
                                    }
                                }
                                .onAppear {
                                    locationManager.requestLocation(completion: nil)
                                }
                        }
                        Spacer(minLength: 10)
                        VStack(spacing: 0) {
                            Text(NSLocalizedString("圓角比例", comment: "Corner radius ratio"))
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                Button(action: {
                                    cornerRadius = max(0.3, cornerRadius - 0.1)
                                    watchLayout.cornerRadiusRatio = cornerRadius
                                    refresh.toggle()
                                    DataContainer.shared.saveLayout(watchLayout.encode())
                                }) {
                                    Image(systemName: "minus")
                                        .font(Font.system(.title3, design: .rounded, weight: .black))
                                        .padding()
                                        .foregroundColor(.black)
                                        .background {
                                            Circle()
                                                .fill(Color.pink)
                                                .frame(width: 35, height: 35)
                                        }
                                }
                                .padding(.all, 0)
                                .buttonStyle(.borderless)
                                Text(String(format: "%.1f", cornerRadius))
                                    .onAppear {
                                        cornerRadius = watchLayout.cornerRadiusRatio
                                    }
                                    .font(Font.system(.title, design: .rounded, weight: .black))
                                    .padding()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                Button(action: {
                                    cornerRadius = min(0.9, cornerRadius + 0.1)
                                    watchLayout.cornerRadiusRatio = cornerRadius
                                    refresh.toggle()
                                    DataContainer.shared.saveLayout(watchLayout.encode())
                                }) {
                                    Image(systemName: "plus")
                                        .font(Font.system(.title3, design: .rounded, weight: .black))
                                        .padding()
                                        .foregroundColor(.black)
                                        .background {
                                            Circle()
                                                .fill(Color.pink)
                                                .frame(width: 35, height: 35)
                                        }
                                }
                                .padding(.all, 0)
                                .buttonStyle(.borderless)
                            }
                        }
                        NavigationLink(NSLocalizedString("調時", comment: "Change Time")) {
                            ScrollView {
                                VStack(spacing: 10) {
                                    Text(adjustTime?.formatted(date: .numeric, time: .omitted) ?? "")
                                        .font(Font.system(.title3, design: .rounded, weight: .bold))
                                        .frame(maxWidth: .infinity, minHeight: 25)
                                        .lineLimit(1)
                                        .padding()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.green, lineWidth: adjustTimeTarget ? 0 : 1)
                                                .padding(.all, 1)
                                        )
                                        .onTapGesture {
                                            adjustTimeTarget = false
                                        }
                                    Text(adjustTime?.formatted(date: .omitted, time: .shortened) ?? "")
                                        .font(Font.system(.title3, design: .rounded, weight: .bold))
                                        .frame(maxWidth: .infinity, minHeight: 25)
                                        .lineLimit(1)
                                        .padding()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.green, lineWidth: adjustTimeTarget ? 1 : 0)
                                                .padding(.all, 1)
                                        )
                                        .onTapGesture {
                                            adjustTimeTarget = true
                                        }
                                    HStack {
                                        Button(action: {
                                            adjustTime = adjustTime?.advanced(by: adjustTimeTarget ? -3600 : -3600 * 24)
                                            displayTime = adjustTime
                                        }) {
                                            Image(systemName: "minus")
                                                .font(Font.system(.title3, design: .rounded, weight: .black))
                                                .foregroundColor(.black)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(Color.pink)
                                        .buttonBorderShape(.capsule)
                                        Button(action: {
                                            adjustTime = adjustTime?.advanced(by: adjustTimeTarget ? 3600 : 3600 * 24)
                                            displayTime = adjustTime
                                        }) {
                                            Image(systemName: "plus")
                                                .font(Font.system(.title3, design: .rounded, weight: .black))
                                                .foregroundColor(.black)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(Color.pink)
                                        .buttonBorderShape(.capsule)
                                    }
                                    Button(action: {
                                        adjustTime = Date()
                                        displayTime = nil
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(Font.system(.title3, design: .rounded, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color.pink)
                                    .buttonBorderShape(.capsule)
                                }
                                .navigationTitle(NSLocalizedString("調時", comment: "Change Time"))
                                .onAppear {
                                    adjustTime = displayTime ?? Date()
                                }
                                .onDisappear {
                                    adjustTime = nil
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.pink)
                        Toggle(NSLocalizedString("分列日時", comment: "Split Date and Time"), isOn: $dual)
                            .onChange(of: dual) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "ChinsesTime.DualWatchDisplay")
                            }
                            .toggleStyle(.button)
                            .tint(.pink)
                        Text(NSLocalizedString("更多設置請移步 iOS App，可於手機與手錶間自動同步", comment: "Hint for syncing between watch and phone"))
                            .frame(maxWidth: .infinity)
                            .font(Font.footnote)
                            .foregroundColor(Color.secondary)
                    }
                }
            }
            .onAppear {
                dual = UserDefaults.standard.bool(forKey: "ChinsesTime.DualWatchDisplay")
                size = proxy.size
            }
        }
        .ignoresSafeArea(edges: [.bottom, .horizontal])
    }
}

struct ContentView_Previews: PreviewProvider {
    init() {
        DataContainer.shared.loadSave()
    }

    static var previews: some View {
        DualWatch(compact: true, refresh: false, watchLayout: WatchLayout.shared)
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 8 (41mm)"))
            .previewDisplayName("41mm")
        DualWatch(compact: true, refresh: false, watchLayout: WatchLayout.shared)
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 8 (45mm)"))
            .previewDisplayName("45mm")
        Watch(compact: true, refresh: false, watchLayout: WatchLayout.shared)
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Ultra (49mm)"))
            .previewDisplayName("49mm")
    }
}
