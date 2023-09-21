//
//  Location.swift
//  Chinese Time iOS
//
//  Created by Leo Liu on 6/24/23.
//

import SwiftUI

internal func coordinateDesp(coordinate: CGPoint) -> (lat: String, lon: String) {
    var latitudeLabel = ""
    if coordinate.x > 0 {
        latitudeLabel = NSLocalizedString("北緯", comment: "N")
    } else if coordinate.x < 0 {
        latitudeLabel = NSLocalizedString("南緯", comment: "S")
    }
    let latitude = Int(round(abs(coordinate.x) * 3600))
    var latitudeString = "\(latitude / 3600)°\((latitude % 3600) / 60)\'\(latitude % 60)\""
    if Locale.isChinese {
        latitudeString = "\(latitudeLabel) \(latitudeString)"
    } else {
        latitudeString = "\(latitudeString) \(latitudeLabel)"
    }
    
    var longitudeLabel = ""
    if coordinate.y > 0 {
        longitudeLabel = NSLocalizedString("東經", comment: "E")
    } else if coordinate.y < 0 {
        longitudeLabel = NSLocalizedString("西經", comment: "W")
    }
    let longitude = Int(round(abs(coordinate.y) * 3600))
    var longitudeString = "\(longitude / 3600)°\((longitude % 3600) / 60)\'\(longitude % 60)\""
    if Locale.isChinese {
        longitudeString = "\(longitudeLabel) \(longitudeString)"
    } else {
        longitudeString = "\(longitudeString) \(longitudeLabel)"
    }
    
    return (latitudeString, longitudeString)
}

struct LocationSelection: Equatable {
    var positive = true
    var degree: Int = 0
    var minute: Int = 0
    var second: Int = 0
    
    var value: CGFloat {
        var locationValue = CGFloat(degree)
        locationValue += CGFloat(minute) / 60
        locationValue += CGFloat(second) / 3600
        locationValue *= positive ? 1.0 : -1.0
        return locationValue
    }
    
    static func from(value: CGFloat) -> Self {
        var values: [Int] = [0, 0, 0]
        let tempValue = Int(round(abs(value) * 3600))
        values[0] = tempValue / 3600
        values[1] = (tempValue % 3600) / 60
        values[2] = tempValue % 60
        return LocationSelection(positive: value >= 0, degree: values[0], minute: values[1], second: values[2])
    }
}

@Observable fileprivate class LocationData {
    var locationManager: LocationManager?
    var watchLayout: WatchLayout?
    var locationUnavailable = false
    
    var timezoneLongitude: CGFloat {
        let logitude = (CGFloat(Calendar.current.timeZone.secondsFromGMT()) - Calendar.current.timeZone.daylightSavingTimeOffset()) / 240
        return ((logitude + 180) %% 360) - 180
    }
    
    var locationEnabled: Bool {
        get {
            (locationManager?.enabled ?? false) || (watchLayout?.location != nil)
        } set {
            if newValue {
                locationManager?.enabled = true
                if !gpsEnabled {
                    watchLayout?.location = CGPoint(x: 0.0, y: timezoneLongitude)
                }
            } else {
                locationManager?.enabled = false
                watchLayout?.location = nil
            }
        }
    }
    
    var gpsEnabled: Bool {
        get {
            locationManager?.enabled ?? false
        } set {
            if newValue {
                locationManager?.enabled = true
                if !gpsEnabled {
                    locationUnavailable = true
                }
            } else {
                locationManager?.enabled = false
                watchLayout?.location = watchLayout?.location ?? locationManager?.location ?? CGPoint(x: 0.0, y: timezoneLongitude)
            }
        }
    }
    
    var gpsLocation: CGPoint? {
        locationManager?.location
    }
    
    var manualLocation: CGPoint? {
        watchLayout?.location
    }
    
    var latitudeSelection: LocationSelection {
        get {
            LocationSelection.from(value: manualLocation?.x ?? 0)
        } set {
            watchLayout?.location?.x = newValue.value
        }
    }
    
    var longitudeSelection: LocationSelection {
        get {
            LocationSelection.from(value: manualLocation?.y ?? CGFloat(Calendar.current.timeZone.secondsFromGMT()) / 240)
        } set {
            watchLayout?.location?.y = newValue.value
        }
    }
    
    var location: CGPoint? {
        self.gpsLocation ?? self.manualLocation
    }
    
    func setup(locationManager: LocationManager, watchLayout: WatchLayout) {
        self.locationManager = locationManager
        self.watchLayout = watchLayout
    }
}

#if os(macOS)
struct OnSubmitTextField<V: Numeric>: View {
    let title: LocalizedStringKey
    let formatter: NumberFormatter
    @Binding var value: V
    @State var tempValue: V
    @FocusState var isFocused: Bool
    
    init(_ title: LocalizedStringKey, value: Binding<V>, formatter: NumberFormatter) {
        self.title = title
        self.formatter = formatter
        self._value = value
        self._tempValue = State(initialValue: value.wrappedValue)
    }
    
    var body: some View {
        TextField(title, value: $tempValue, formatter: formatter)
            .focused($isFocused)
            .onSubmit(of: .text) {
                value = tempValue
            }
            .onChange(of: isFocused) { _, newValue in
                if !newValue {
                    value = tempValue
                }
            }
    }
}
#endif

struct Location: View {
    @State fileprivate var locationData = LocationData()
    @Environment(\.watchSetting) var watchSetting
    @Environment(\.locationManager) var locationManager
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.chineseCalendar) var chineseCalendar
    
    var body: some View {
        Form {
            Section {
                Toggle("定位", isOn: $locationData.locationEnabled)
                Toggle("今地", isOn: $locationData.gpsEnabled)
                    .disabled(!locationData.locationEnabled)
            }
            .alert("迷蹤難尋", isPresented: $locationData.locationUnavailable) {
                Button("罷", role: .cancel) {}
            } message: {
                Text("未開啓定位。如欲使用 GPS 定位，請於設置中啓用", comment: "Please enable location service in Settings App")
            }
            if locationData.locationEnabled {
                if locationData.gpsEnabled {
                    Section(header: Text("經緯度", comment: "Geo Location section")) {
                        if let location = locationManager.location {
                            let locationString = coordinateDesp(coordinate: location)
                            Text("\(locationString.0), \(locationString.1)")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .privacySensitive()
                        } else {
                            Text("虚無", comment: "Location fails to load")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                } else {
                    let manualLocationDesp = locationData.manualLocation.map { coordinateDesp(coordinate: $0) }
                    let latitudeTitle = if let desp = manualLocationDesp {
                        NSLocalizedString("緯度：", comment: "Latitude section") + desp.0
                    } else {
                        NSLocalizedString("緯度", comment: "Latitude section")
                    }
                    Section(header: Text(latitudeTitle)) {
                        HStack {
#if os(iOS)
                            Picker("度", selection: $locationData.latitudeSelection.degree) {
                                ForEach(0...89, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.latitudeSelection)
                            Picker("分", selection: $locationData.latitudeSelection.minute) {
                                ForEach(0...59, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.latitudeSelection)
                            Picker("秒", selection: $locationData.latitudeSelection.second) {
                                ForEach(0...60, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.latitudeSelection)
#elseif os(macOS)
                            OnSubmitTextField("度", value: $locationData.latitudeSelection.degree, formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 89
                                formatter.minimum = 0
                                return formatter
                            }())
                            .frame(height: 20)
                            .background(in: RoundedRectangle(cornerRadius: 10))
                            OnSubmitTextField("分", value: $locationData.latitudeSelection.minute, formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 59
                                formatter.minimum = 0
                                return formatter
                            }())
                            .frame(height: 20)
                            .background(in: RoundedRectangle(cornerRadius: 10))
                            OnSubmitTextField("秒", value: $locationData.latitudeSelection.second, formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 60
                                formatter.minimum = 0
                                return formatter
                            }())
                            .frame(height: 20)
                            .background(in: RoundedRectangle(cornerRadius: 10))
#endif
                            Picker("北南", selection: $locationData.latitudeSelection.positive) {
                                ForEach([true, false], id: \.self) { value in
                                    Text(value ? NSLocalizedString("北", comment: "N in geo location") : NSLocalizedString("南", comment: "S in geo location"))
                                }
                            }
                            .animation(.default, value: locationData.latitudeSelection)
                        }
#if os(iOS)
                        .pickerStyle(.wheel)
#elseif os(macOS)
                        .pickerStyle(.menu)
                        .frame(height: 20)
#endif
                    }

                    let longitudeTitle = if let desp = manualLocationDesp {
                        NSLocalizedString("經度：", comment: "Longitude section") + desp.1
                    } else {
                        NSLocalizedString("經度", comment: "Longitude section")
                    }
                    Section(header: Text(longitudeTitle)) {
                        HStack {
#if os(iOS)
                            Picker("度", selection: $locationData.longitudeSelection.degree) {
                                ForEach(0...179, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.longitudeSelection)
                            Picker("分", selection: $locationData.longitudeSelection.minute) {
                                ForEach(0...59, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.longitudeSelection)
                            Picker("秒", selection: $locationData.longitudeSelection.second) {
                                ForEach(0...60, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.longitudeSelection)
#elseif os(macOS)
                            OnSubmitTextField("度", value: $locationData.longitudeSelection.degree, formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 179
                                formatter.minimum = 0
                                return formatter
                            }())
                            .frame(height: 20)
                            .background(in: RoundedRectangle(cornerRadius: 10))
                            OnSubmitTextField("分", value: $locationData.longitudeSelection.minute, formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 59
                                formatter.minimum = 0
                                return formatter
                            }())
                            .frame(height: 20)
                            .background(in: RoundedRectangle(cornerRadius: 10))
                            OnSubmitTextField("秒", value: $locationData.longitudeSelection.second, formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 60
                                formatter.minimum = 0
                                return formatter
                            }())
                            .frame(height: 20)
                            .background(in: RoundedRectangle(cornerRadius: 10))
#endif
                            Picker("東西", selection: $locationData.longitudeSelection.positive) {
                                ForEach([true, false], id: \.self) { value in
                                    Text(value ? NSLocalizedString("東", comment: "E in geo location") : NSLocalizedString("西", comment: "W in geo location"))
                                }
                            }
                            .animation(.default, value: locationData.longitudeSelection)
                        }
#if os(iOS)
                        .pickerStyle(.wheel)
#elseif os(macOS)
                        .pickerStyle(.menu)
#endif
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task {
            locationData.setup(locationManager: locationManager, watchLayout: watchLayout)
        }
        .onChange(of: locationData.location) { _, newValue in
            chineseCalendar.update(time: watchSetting.displayTime ?? Date.now, location: newValue)
        }
        .navigationTitle(Text("經緯度", comment: "Geo Location section"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
                watchSetting.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#endif
    }
}

#Preview("Location") {
    Location()
}
