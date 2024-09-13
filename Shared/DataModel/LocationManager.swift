//
//  Delegates.swift
//  MacWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import CoreLocation

struct GeoLocation: Equatable {
    let lat: Double
    let lon: Double

    func encode() -> String {
        return "lat: \(lat), lon: \(lon)"
    }

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }

    init?(from str: String?) {
        guard let str = str else { return nil }
        let regex = /(x|lat):\s*([\-0-9\.]+)\s*,\s*(y|lon):\s*([\-0-9\.]+)/
        let matches = try? regex.firstMatch(in: str)?.output
        if let matches, let lat = Double(matches.2), let lon = Double(matches.4) {
            self.lat = lat
            self.lon = lon
        } else {
            return nil
        }
    }
}

enum LocationError: Error {
    case authorizationDenied, authorizationDeniedGlobally, authorizationRestricted, locationUnavailable, updateError
}

actor LocationManager {
    static let shared = LocationManager()
    
    private var lastUpdateTime = Date.distantPast
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
    private var location: GeoLocation? {
        if let loc = lastUpdate?.location {
            GeoLocation(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        } else {
            nil
        }
    }
    
    private init () {}

    @discardableResult
    func getLocation(wait duration: Duration = .seconds(5)) async throws(LocationError) -> GeoLocation? {
        if lastUpdateTime.distance(to: .now) > 3600 {
            let updates = CLLocationUpdate.liveUpdates()
            let timeoutTask = Task {
                try await Task.sleep(for: duration)
                return location
            }
            defer {
                timeoutTask.cancel()
            }
            do {
                for try await update in updates {
                    if update.location != nil {
                        lastUpdate = update
                        return location
                    } else if update.authorizationDeniedGlobally {
                        throw LocationError.authorizationDeniedGlobally
                    } else if update.authorizationDenied {
                        throw LocationError.authorizationDenied
                    } else if update.authorizationRestricted {
                        throw LocationError.authorizationRestricted
                    } else if update.locationUnavailable {
                        throw LocationError.locationUnavailable
                    }
                }
            } catch let error as LocationError {
                throw error
            } catch {
                throw LocationError.updateError
            }
        }
        return location
    }
    
    func clearLocation() {
        lastUpdate = nil
    }
}
