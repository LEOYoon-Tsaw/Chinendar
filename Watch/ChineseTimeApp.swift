//
//  ChineseTimeApp.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI

@main
struct ChineseTime_Watch_App: App {
    
    init() {
        DataContainer.shared.loadSave()
        let _ = WatchConnectivityManager.shared
        LocationManager.shared.manager.requestWhenInUseAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
