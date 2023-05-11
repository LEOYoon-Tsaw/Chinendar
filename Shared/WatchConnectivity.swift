//
//  WatchConnectivity.swift
//  Chinese Time
//
//  Created by Leo Liu on 5/5/23.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        if let newLayout = message["layout"] as? String {
#if os(watchOS)
            DispatchQueue.main.async {
                WatchLayout.shared.update(from: newLayout)
                DataContainer.shared.saveLayout(WatchLayout.shared.encode())
            }
#endif
        } else if let request = message["request"] as? String, request == "layout" {
#if os(iOS)
            let _ = self.sendLayout(WatchLayout.shared.encode(includeOffset: false))
#endif
        }
    }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        
    }
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
    
    func sendLayout(_ message: String) -> Bool {
        guard WCSession.default.activationState == .activated else { return false }
#if os(iOS)
        guard WCSession.default.isWatchAppInstalled else { return false }
#else
        guard WCSession.default.isCompanionAppInstalled else { return false }
#endif
        let backgroundQueue = DispatchQueue(label: "background_queue", qos: .background)
        backgroundQueue.async {
            WCSession.default.sendMessage(["layout" : message], replyHandler: nil) { error in
                print("Cannot send message: \(String(describing: error))")
            }
        }
        return true
    }
    
#if os(watchOS)
    func requestLayout() {
        let backgroundQueue = DispatchQueue(label: "background_queue", qos: .background)
        backgroundQueue.async {
            WCSession.default.sendMessage(["request" : "layout"], replyHandler: nil) { error in
                print("Cannot send message: \(String(describing: error))")
            }
        }
    }
#endif
}
