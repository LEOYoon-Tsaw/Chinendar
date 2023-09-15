//
//  Delegates.swift
//  MacWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import CoreLocation
import Observation

@Observable final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private var _location: CGPoint? = nil
    private(set) var location: CGPoint? {
        get {
            if enabled {
                _location
            } else {
                nil
            }
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
    @ObservationIgnored private var continuation: CheckedContinuation<CGPoint?, Never>?
    @ObservationIgnored let watchLayout = WatchLayout.shared
    var enabled: Bool {
        get {
            if watchLayout.locationEnabled {
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
            } else {
                return false
            }
        } set {
            watchLayout.locationEnabled = newValue
            if newValue {
                requestLocation()
            }
        }
    }
    

    override private init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        if enabled && (lastUpdated.distance(to: .now) > 3600) {
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
    
    func getLocation() async -> CGPoint? {
        if enabled && (lastUpdated.distance(to: .now) > 3600) {
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
            let locationPoint = CGPoint(x: location.coordinate.latitude, y: location.coordinate.longitude)
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
