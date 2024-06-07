//
//  WatchConnectivity.swift
//  Chinendar
//
//  Created by Leo Liu on 5/5/23.
//

import WatchConnectivity
import Observation

@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    @ObservationIgnored let watchLayout: WatchLayout
    @ObservationIgnored let calendarConfigure: CalendarConfigure
    @ObservationIgnored let locationManager: LocationManager

    init(watchLayout: WatchLayout, calendarConfigure: CalendarConfigure, locationManager: LocationManager) {
        self.watchLayout = watchLayout
        self.calendarConfigure = calendarConfigure
        self.locationManager = locationManager
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
#if os(watchOS)
        if let newLayout = message["layout"] as? String {
            Task(priority: .background) {
                watchLayout.update(from: newLayout)
            }
        }
        if let newConfig = message["config"] as? String {
            Task(priority: .background) {
                calendarConfigure.update(from: newConfig)
                locationManager.enabled = true
            }
        }
#elseif os(iOS)
        if let request = message["request"] as? String {
            let requests = request.split(separator: /,/, omittingEmptySubsequences: true)
            var response = [String: String]()
            if requests.contains("layout") {
                if watchLayout.initialized {
                    response["layout"] = watchLayout.encode(includeOffset: false)
                }
            }
            if requests.contains("config") {
                if calendarConfigure.initialized {
                    response["config"] = calendarConfigure.encode(withName: true)
                }
            }
            send(messages: response)
        }
#endif
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

    func send(messages: [String: String]) {
        guard WCSession.default.activationState == .activated else { return }
#if os(iOS)
        guard WCSession.default.isWatchAppInstalled else { return }
#else
        guard WCSession.default.isCompanionAppInstalled else { return }
#endif
        Task(priority: .background) {
            WCSession.default.sendMessage(messages, replyHandler: nil) { error in
                print("Cannot send message: \(String(describing: error))")
            }
        }
    }

#if os(watchOS)
    func requestLayout() {
        Task(priority: .background) {
            WCSession.default.sendMessage(["request": "layout,config"], replyHandler: nil) { error in
                print("Cannot send message: \(String(describing: error))")
            }
        }
    }
#endif
}
