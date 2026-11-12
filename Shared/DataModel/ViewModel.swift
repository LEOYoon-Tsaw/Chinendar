//
//  ViewModel.swift
//  Chinendar
//
//  Created by Leo Liu on 4/27/23.
//

import SwiftUI

@MainActor
protocol ViewModelType: AnyObject, Bindable, Sendable {
    associatedtype ObservationToken: DefaultObservationTokens

    var observationTokens: ObservationToken { get }
    var themeData: LocalTheme { get }
    var configData: LocalConfig { get }
    var baseLayout: BaseLayout { get set }
    var watchLayout: ExtraLayout<BaseLayout> { get set }
    var config: CalendarConfigure { get set }
    var settings: WatchSetting { get set }
    var chineseCalendar: ChineseCalendar { get set }
    var locationManager: LocationManager { get }
    var location: GeoLocation? { get }
    var gpsLocation: GeoLocation? { get set }
    var gpsLocationAvailable: Bool { get }
    var locatingTask: Task<Void, any Error>? { get set }

    var layoutInitialized: Bool { get }
    var configInitialized: Bool { get }
    var error: any Error? { get set }
    var hasError: Bool { get set }
    func setup()
    func clearLocation()
}

extension ViewModelType {
    var watchLayout: ExtraLayout<BaseLayout> {
        get {
            themeData.instance
        } set {
            themeData.instance = newValue
        }
    }
    var baseLayout: BaseLayout {
        get {
            watchLayout.baseLayout
        } set {
            watchLayout.baseLayout = newValue
        }
    }
    var config: CalendarConfigure {
        get {
            configData.instance
        } set {
            configData.instance = newValue
        }
    }
    var layoutInitialized: Bool {
        baseLayout.initialized
    }
    var configInitialized: Bool {
        config.initialized
    }

    var location: GeoLocation? {
        locatingTask?.cancel()
        locatingTask = Task(priority: .userInitiated) {
            for try await gpsLoc in await locationManager.locationStream(maxWait: .seconds(1)) where gpsLoc != gpsLocation {
                gpsLocation = gpsLoc
            }
        }
        if config.locationEnabled {
            return gpsLocation ?? config.customLocation
        } else {
            return config.customLocation
        }
    }

    var gpsLocationAvailable: Bool {
        gpsLocation != nil && config.locationEnabled
    }

    var hasError: Bool {
        get {
            error != nil
        } set {
            if !newValue {
                error = nil
            }
        }
    }

    func clearLocation() {
        gpsLocation = nil
        Task(priority: .userInitiated) {
            await locationManager.clearLocation()
        }
    }

    func updateChineseCalendar() {
        chineseCalendar.update(time: settings.effectiveTime,
                               timezone: config.effectiveTimezone,
                               location: self.location,
                               globalMonth: config.globalMonth,
                               apparentTime: config.apparentTime,
                               largeHour: config.largeHour)
    }

    func setup() {
        _ = Task {
            try await LocalDataModel.shared.pruneEventWidgetStatuses()
        }
        _ = Task {
            for try await _ in await self.locationManager.locationStream(maxWait: .seconds(10)) {}
        }
        self.observationTokens.autoupdateChineseCalendar = withContinuousObservation(options: .didSet) { [weak self] _ in
            self?.updateChineseCalendar()
        }
    }
}

protocol DefaultObservationTokens: AnyObject {
    var autoupdateChineseCalendar: ObservationTracking.Token? { get set }
}
