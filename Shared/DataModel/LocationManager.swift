//
//  Delegates.swift
//  MacWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import CoreLocation
import Observation

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
        if let matches = matches, let lat = Double(matches.2), let lon = Double(matches.4) {
            self.lat = lat
            self.lon = lon
        } else {
            return nil
        }
    }
}

@Observable final class LocationManager: NSObject, CLLocationManagerDelegate {

    private var _location: GeoLocation?
    private(set) var location: GeoLocation? {
        get {
            _location
        } set {
            _location = newValue
            if newValue == nil {
                lastUpdated = Date.distantPast
            } else {
                lastUpdated = Date.now
            }
        }
    }

    @ObservationIgnored let manager = CLLocationManager()
    @ObservationIgnored private var lastUpdated = Date.distantPast
    @ObservationIgnored private var continuation: CheckedContinuation<GeoLocation?, Never>?

    var enabled: Bool {
        get {
            switch manager.authorizationStatus {
#if os(macOS)
            case .authorized, .authorizedAlways: // Location services are available.
                return true
#else
            case .authorizedWhenInUse, .authorizedAlways: // Location services are available.
                return true
#endif
            case .restricted, .denied:
                return false
            case .notDetermined: // Authorization not determined yet.
                return false
            @unknown default:
                return false
            }
        } set {
            if newValue {
                requestLocation()
            } else {
                location = nil
            }
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    private func requestLocation() {
        if lastUpdated.distance(to: .now) > 3600 {
            switch manager.authorizationStatus {
#if os(macOS)
            case .authorized, .authorizedAlways:
                manager.requestLocation()
#else
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
#endif
            case .notDetermined: // Authorization not determined yet.
                manager.requestWhenInUseAuthorization()
            default:
                return
            }
        }
    }

    func getLocation() async -> GeoLocation? {
        if lastUpdated.distance(to: .now) > 3600 {
#if os(watchOS)
            let authorized = [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus)
#else
            let authorized = manager.isAuthorizedForWidgetUpdates
#endif
            if authorized {
                return await withCheckedContinuation { continuation in
                    self.continuation = continuation
                    manager.requestLocation()
                }
            }
        }
        return nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let locationPoint = GeoLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            self.location = locationPoint
            continuation?.resume(with: .success(locationPoint))
        } else {
            continuation?.resume(with: .success(nil))
        }
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
#if os(macOS)
        case .authorized, .authorizedAlways: // Location services are available.
            requestLocation()
#else
        case .authorizedWhenInUse, .authorizedAlways: // Location services are available.
            requestLocation()
#endif

        case .restricted, .denied:
            break

        case .notDetermined: // Authorization not determined yet.
            manager.requestWhenInUseAuthorization()

        @unknown default:
            print("Unhandled Location Authorization Case")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let continuation = continuation {
            continuation.resume(with: .success(nil))
        }
        continuation = nil
        print(error)
    }
}
