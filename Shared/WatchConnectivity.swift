//
//  WatchConnectivity.swift
//  Chinendar
//
//  Created by Leo Liu on 5/5/23.
//

import WatchConnectivity

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    override private init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let newLayout = message["layout"] as? String {
#if os(watchOS)
            Task(priority: .background) {
                let watchLayout = WatchLayout.shared
                watchLayout.update(from: newLayout)
                LocationManager.shared.enabled = watchLayout.locationEnabled
                let modelContext = ThemeData.context
                watchLayout.saveDefault(context: modelContext)
                try? modelContext.save()
            }
#endif
        } else if let request = message["request"] as? String, request == "layout" {
#if os(iOS)
            let watchLayout = WatchLayout.shared
            if watchLayout.initialized {
                sendLayout(watchLayout.encode(includeOffset: false))
            }
#endif
        }
    }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
    
    func sendLayout(_ message: String) {
        guard WCSession.default.activationState == .activated else { return }
#if os(iOS)
        guard WCSession.default.isWatchAppInstalled else { return }
#else
        guard WCSession.default.isCompanionAppInstalled else { return }
#endif
        Task(priority: .background) {
            WCSession.default.sendMessage(["layout": message], replyHandler: nil) { error in
                print("Cannot send message: \(String(describing: error))")
            }
        }
    }
    
#if os(watchOS)
    func requestLayout() {
        Task(priority: .background) {
            WCSession.default.sendMessage(["request": "layout"], replyHandler: nil) { error in
                print("Cannot send message: \(String(describing: error))")
            }
        }
    }
#endif
}
