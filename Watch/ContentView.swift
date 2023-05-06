//
//  ContentView.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var watchFace: WatchFace
    @Environment(\.scenePhase) var scenePhase
    let locationManager = LocationManager()
    let timer = Timer.publish(every: WatchFace.updateInterval, on: .main, in: .common).autoconnect()
    @State var cornerRadius: CGFloat = 0
    @State var displayTime: Date?
    @State var adjustTimeTarget: Bool = true

    var body: some View {
        if watchFace.realLocation == nil {
            locationManager.requestLocation()
        }
        watchFace.update()
        return NavigationStack() {
            ScrollView {
                VStack(spacing: 10) {
                    ZStack {
                        watchFace.body
                            .frame(width: watchFace.screenFrame.width, height: watchFace.screenFrame.height)
                            .position(x: watchFace.screenFrame.midX, y: watchFace.screenFrame.midY)
                            .navigationTitle(NSLocalizedString("華曆", comment: "App Name"))
                            .navigationBarTitleDisplayMode(.inline)
                            .onReceive(timer) { input in
                                watchFace.update(forceRefresh: false)
                            }
                            .onChange(of: scenePhase) { newPhase in
                                if newPhase == .active {
                                    WatchConnectivityManager.shared.requestLayout()
                                }
                            }
                    }
                    Spacer(minLength: 10)
                    VStack(spacing: 0) {
                        Text(NSLocalizedString("圓角比例", comment: "Corner radius ratio"))
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Image(systemName: "minus")
                                .font(Font.system(.title3, design: .rounded, weight: .black))
                                .padding()
                                .foregroundColor(.black)
                                .background {
                                    Circle()
                                        .fill(Color.pink)
                                        .frame(width: 35, height: 35)
                                }
                                .onTapGesture() {
                                    cornerRadius = max(0.3, cornerRadius - 0.1)
                                    watchFace.watchLayout.cornerRadiusRatio = cornerRadius
                                    watchFace.update(forceRefresh: true)
                                    let _ = DataContainer.shared.saveLayout()
                                }
                            Text(String(format: "%.1f", cornerRadius))
                                .onAppear() {
                                    cornerRadius = watchFace.watchLayout.cornerRadiusRatio
                                }
                                .font(Font.system(.title, design: .rounded, weight: .black))
                                .padding()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            Image(systemName: "plus")
                                .font(Font.system(.title3, design: .rounded, weight: .black))
                                .padding()
                                .foregroundColor(.black)
                                .background {
                                    Circle()
                                        .fill(Color.pink)
                                        .frame(width: 35, height: 35)
                                }
                                .onTapGesture() {
                                    cornerRadius = min(0.9, cornerRadius + 0.1)
                                    watchFace.watchLayout.cornerRadiusRatio = cornerRadius
                                    watchFace.update(forceRefresh: true)
                                    let _ = DataContainer.shared.saveLayout()
                                }
                        }
                    }
                    NavigationLink(NSLocalizedString("調時", comment: "Change Time")) {
                        ScrollView {
                            VStack(spacing: 10) {
                                Text(displayTime?.formatted(date: .numeric, time: .omitted) ?? "")
                                    .font(Font.system(.title3, design: .rounded, weight: .bold))
                                    .frame(maxWidth: .infinity, minHeight: 25)
                                    .lineLimit(1)
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.green, lineWidth: adjustTimeTarget ? 0 : 1)
                                    )
                                    .onTapGesture {
                                        adjustTimeTarget = false
                                    }
                                Text(displayTime?.formatted(date: .omitted, time: .shortened) ?? "")
                                    .font(Font.system(.title3, design: .rounded, weight: .bold))
                                    .frame(maxWidth: .infinity, minHeight: 25)
                                    .lineLimit(1)
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.green, lineWidth: adjustTimeTarget ? 1 : 0)
                                    )
                                    .onTapGesture {
                                        adjustTimeTarget = true
                                    }
                                HStack {
                                    Button(action: {
                                        displayTime = displayTime?.advanced(by: adjustTimeTarget ? -3600 : -3600 * 24)
                                        watchFace.displayTime = displayTime
                                    }) {
                                        Image(systemName: "minus")
                                            .font(Font.system(.title3, design: .rounded, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color.pink)
                                    .buttonBorderShape(.capsule)
                                    Button(action: {
                                        displayTime = displayTime?.advanced(by: adjustTimeTarget ? 3600 : 3600 * 24)
                                        watchFace.displayTime = displayTime
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
                                    displayTime = Date()
                                    watchFace.displayTime = nil
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
                            .onAppear() {
                                displayTime = watchFace.displayTime ?? Date()
                            }
                            .onDisappear() {
                                displayTime = nil
                                watchFace.update(forceRefresh: false)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.pink)
                    Text(NSLocalizedString("更多設置請移步 iOS App，可於手機與手錶間自動同步", comment: "Hint for syncing between watch and phone"))
                        .frame(maxWidth: .infinity)
                        .font(Font.footnote)
                        .foregroundColor(Color.secondary)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    init() {
        DataContainer.shared.loadSave()
        let _ = WatchConnectivityManager.shared
    }
    
    static var previews: some View {
        let screen: CGRect = {
            var size = WKInterfaceDevice.current().screenBounds
            size.size.height -= getStatusBarHeight(frameHeight: size.height)
            return size
        }()
        ContentView(watchFace: WatchFace(frame: screen, compact: true))
    }
}
