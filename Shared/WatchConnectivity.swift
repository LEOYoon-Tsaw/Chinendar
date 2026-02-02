//
//  WatchConnectivity.swift
//  Chinendar
//
//  Created by Leo Liu on 5/5/23.
//

import WatchConnectivity

enum WCMessageKind: String, CaseIterable {
    case layout, config
}

actor WatchConnectivityManager {
    static let shared = WatchConnectivityManager()
    private let session = WCSession.default
    private let delegate: WatchConnectivityDelegate

    private init() {
        delegate = .init(session: session)
    }

#if os(watchOS)
    var stream: AsyncThrowingStream<[WCMessageKind: Data], Error> {
        delegate.stream
    }

    func request(_ requests: [WCMessageKind]) async throws {
        try await send(requests: requests)
    }

    private func send(requests: [WCMessageKind]) async throws {
        guard session.activationState == .activated else { return }
        guard session.isCompanionAppInstalled else { return }

        let message = [WatchConnectivityDelegate.requestKey: requests.map(\.rawValue)]
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            session.sendMessage(message, replyHandler: nil) { error in
                continuation.resume(throwing: error)
            }
        }
    }
#else
    func respond(_ messages: [WCMessageKind: Data]) async throws {
        try await send(messages: messages)
    }

    private func send(messages: [WCMessageKind: Data]) async throws {
        guard session.activationState == .activated else { return }
        guard session.isWatchAppInstalled else { return }

        var responses: [String: Data] = [:]
        for (key, value) in messages {
            responses[key.rawValue] = value
        }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            session.sendMessage(responses, replyHandler: nil) { error in
                continuation.resume(throwing: error)
            }
        }
    }
#endif
}

private final class WatchConnectivityDelegate: NSObject, WCSessionDelegate {
    static let requestKey = "request"

    init(session: WCSession) {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
#if os(watchOS)
    var continuation: AsyncThrowingStream<[WCMessageKind: Data], Error>.Continuation?

    var stream: AsyncThrowingStream<[WCMessageKind: Data], Error> {
        AsyncThrowingStream { [weak self] continuation in
            self?.continuation = continuation
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            session.sendMessage([Self.requestKey: WCMessageKind.allCases.map(\.rawValue)], replyHandler: nil)
        }
    }
#endif

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
#if os(watchOS)
        guard let message = message as? [String: Data] else { return }
        var response: [WCMessageKind: Data] = [:]
        for (key, value) in message {
            if let kind = WCMessageKind(rawValue: key) {
                response[kind] = value
            }
        }
        continuation?.yield(response)
#else
        guard let requestStrings = message[Self.requestKey] as? [String] else { return }
        let requests = requestStrings.compactMap(WCMessageKind.init(rawValue:))
        guard !requests.isEmpty else { return }
        Task { @MainActor in
            let viewModel = ViewModel.shared
            var response = [WCMessageKind: Data]()
            for request in requests {
                switch request {
                case .layout:
                    if viewModel.layoutInitialized {
                        response[.layout] = try viewModel.watchLayout.encode()
                    }
                case .config:
                    if viewModel.configInitialized {
                        response[.config] = try viewModel.config.encode()
                    }
                }
            }
            try await WatchConnectivityManager.shared.respond(response)
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
}
