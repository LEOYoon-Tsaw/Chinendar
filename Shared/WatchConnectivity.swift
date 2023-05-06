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
                if let watchFace = WatchFace.currentInstance {
                    watchFace.watchLayout.update(from: newLayout)
                    watchFace.update(forceRefresh: true)
                }
                DataContainer.shared.saveLayout(newLayout)
            }
#endif
        } else if let request = message["request"] as? String, request == "layout" {
#if os(iOS)
            DispatchQueue.main.async {
                if let watchFace = WatchFaceView.currentInstance {
                    let _ = self.sendLayout(watchFace.watchLayout.encode(includeOffset: false))
                }
            }
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
        WCSession.default.sendMessage(["layout" : message], replyHandler: nil) { error in
            print("Cannot send message: \(String(describing: error))")
        }
        return true
    }
    
#if os(watchOS)
    func requestLayout() {
        WCSession.default.sendMessage(["request" : "layout"], replyHandler: nil) { error in
            print("Cannot send message: \(String(describing: error))")
        }
    }
#endif
}
