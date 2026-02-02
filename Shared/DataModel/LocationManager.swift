//
//  LocationManager.swift
//  Chinendar
//
//  Created by Leo Liu on 5/9/23.
//

import CoreLocation

struct GeoLocation: Equatable, Codable {
    let lat: Double
    let lon: Double
}

private extension CLLocation {
    var geoLocation: GeoLocation {
        GeoLocation(lat: coordinate.latitude, lon: coordinate.longitude)
    }
}

enum LocationError: Error {
    case authorizationDenied, authorizationDeniedGlobally, authorizationRestricted, authorizationUndetermined, locationUnavailable, updateTimeout
}

actor LocationManager {
    static let shared = LocationManager()

    private var lastUpdateTime = Date.distantPast
    private var lastError: LocationError?
    private var _lastUpdate: CLLocationUpdate?
    private var lastUpdate: CLLocationUpdate? {
        get {
            _lastUpdate
        } set {
            _lastUpdate = newValue
            if let newValue, newValue.location != nil {
                lastUpdateTime = .now
            } else {
                lastUpdateTime = .distantPast
            }
        }
    }

    private init () {}

    private func setError(_ error: LocationError?) {
        self.lastError = error
    }

    func locationStream(maxWait duration: Duration = .seconds(5)) -> AsyncThrowingStream<GeoLocation, Error> {
        return AsyncThrowingStream { continuation in

            if let loc = lastUpdate?.location, lastUpdateTime.distance(to: .now) <= 3600 {
                continuation.yield(loc.geoLocation)
                continuation.finish()
            }

            var timeoutTask = Task {
                try await Task.sleep(for: duration)
                continuation.finish(throwing: lastError ?? .updateTimeout)
            }

            let updatingLocationTask = Task {
                let updates = CLLocationUpdate.liveUpdates()
                setError(nil)
                for try await update in updates {
                    if let loc = update.location {
                        lastUpdate = update
                        continuation.yield(loc.geoLocation)
                        continuation.finish()
                    } else if update.authorizationDeniedGlobally {
                        continuation.finish(throwing: LocationError.authorizationDeniedGlobally)
                    } else if update.authorizationDenied {
                        continuation.finish(throwing: LocationError.authorizationDenied)
                    } else if update.authorizationRestricted {
                        continuation.finish(throwing: LocationError.authorizationRestricted)
                    } else if update.locationUnavailable {
                        lastError = .locationUnavailable
                    } else if update.authorizationRequestInProgress {
                        timeoutTask.cancel()
                        let authorizationTask = Task { @MainActor in
                            let authorizationStream = AuthorizationStream()
                            let authTimeout = Task {
                                try await Task.sleep(for: .seconds(10))
                                continuation.finish(throwing: LocationError.authorizationUndetermined)
                            }
                            return await withTaskCancellationHandler {
                                for await status in authorizationStream.stream {
                                    if status != .notDetermined {
                                        authTimeout.cancel()
                                        return status
                                    }
                                }
                                return .notDetermined
                            } onCancel: {
                                authTimeout.cancel()
                            }
                        }
                        await withTaskCancellationHandler {
                            _ = await authorizationTask.value
                            timeoutTask = Task {
                                try await Task.sleep(for: duration)
                                continuation.finish(throwing: lastError ?? .updateTimeout)
                            }
                        } onCancel: {
                            authorizationTask.cancel()
                        }
                    }
                }
            }

            continuation.onTermination = { _ in
                updatingLocationTask.cancel()
            }
        }
    }

    func clearLocation() {
        lastUpdate = nil
    }
}

@MainActor
private final class AuthorizationStream: NSObject, @MainActor CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: AsyncStream<CLAuthorizationStatus>.Continuation?

    var stream: AsyncStream<CLAuthorizationStatus> {
        AsyncStream { [weak self] continuation in
            guard let manager = self?.manager else {
                continuation.finish()
                return
            }
            if manager.authorizationStatus != .notDetermined {
                continuation.yield(manager.authorizationStatus)
                continuation.finish()
            } else {
                manager.delegate = self
                manager.requestWhenInUseAuthorization()
                self?.continuation = continuation
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        continuation?.yield(manager.authorizationStatus)
        if manager.authorizationStatus != .notDetermined {
            continuation?.finish()
        }
    }
}
