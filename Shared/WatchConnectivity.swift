//
//  WatchConnectivity.swift
//  Chinendar
//
//  Created by Leo Liu on 5/5/23.
//

import WatchConnectivity

final class WatchConnectivityManager<T: ViewModelType>: NSObject, WCSessionDelegate, Sendable {
    private let getViewModel: @Sendable () -> T
    
    init(viewModel: @autoclosure @escaping @Sendable () -> T) {
        self.getViewModel = viewModel
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
#if os(watchOS)
        if let message = message as? [String: String] {
            Task { @MainActor in
                let viewModel = getViewModel()
                if let newLayout = message["layout"] {
                    viewModel.updateLayout(from: newLayout, updateSize: false)
                }
                if let newConfig = message["config"] {
                    viewModel.updateConfig(from: newConfig, newName: nil)
                    ChinendarShortcut.updateAppShortcutParameters()
                    if viewModel.config.locationEnabled {
                        try await viewModel.locationManager.getLocation(wait: .seconds(5))
                    } else {
                        await viewModel.locationManager.clearLocation()
                    }
                }
            }
        }

#elseif os(iOS)
        if let request = message["request"] as? String {
            let requests = request.split(separator: /,/, omittingEmptySubsequences: true).map { String($0) }
            Task { @MainActor in
                let viewModel = getViewModel()
                var response = [String: String]()
                if requests.contains("layout") {
                    if viewModel.layoutInitialized {
                        response["layout"] = viewModel.layoutString(includeOffset: false, includeColor: true)
                    }
                }
                if requests.contains("config") {
                    if viewModel.configInitialized {
                        response["config"] = viewModel.configString(withName: true)
                    }
                }
                await send(messages: response)
            }
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
    
    func send(messages: [String: String]) async {
        guard WCSession.default.activationState == .activated else { return }
#if os(iOS)
        guard WCSession.default.isWatchAppInstalled else { return }
#else
        guard WCSession.default.isCompanionAppInstalled else { return }
#endif
        WCSession.default.sendMessage(messages, replyHandler: nil) { error in
            print("Cannot send message: \(String(describing: error))")
        }
    }
    
#if os(watchOS)
    func requestLayout() async {
        WCSession.default.sendMessage(["request": "layout,config"], replyHandler: nil) { error in
            print("Cannot send message: \(String(describing: error))")
        }
    }
#endif
}
