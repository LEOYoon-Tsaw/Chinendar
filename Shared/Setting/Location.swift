//
//  Location.swift
//  Chinendar
//
//  Created by Leo Liu on 6/24/23.
//

import SwiftUI

private func coordinateDesp(coordinate: GeoLocation) -> (lat: String, lon: String) {
    var latitudeLabel = ""
    if coordinate.lat > 0 {
        latitudeLabel = NSLocalizedString("北緯", comment: "N")
    } else if coordinate.lat < 0 {
        latitudeLabel = NSLocalizedString("南緯", comment: "S")
    }
    let latitude = Int(round(abs(coordinate.lat) * 3600))
    var latitudeString = "\(latitude / 3600)°\((latitude % 3600) / 60)\'\(latitude % 60)\""
    if Locale.isEastAsian {
        latitudeString = "\(latitudeLabel) \(latitudeString)"
    } else {
        latitudeString = "\(latitudeString) \(latitudeLabel)"
    }

    var longitudeLabel = ""
    if coordinate.lon > 0 {
        longitudeLabel = NSLocalizedString("東經", comment: "E")
    } else if coordinate.lon < 0 {
        longitudeLabel = NSLocalizedString("西經", comment: "W")
    }
    let longitude = Int(round(abs(coordinate.lon) * 3600))
    var longitudeString = "\(longitude / 3600)°\((longitude % 3600) / 60)\'\(longitude % 60)\""
    if Locale.isEastAsian {
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

@MainActor
@Observable private final class LocationData: Bindable {
    var viewModel: ViewModel?
    var error: LocationError?
    var presentError: Bool {
        get {
           error != nil
        } set {
           if !newValue {
               error = nil
           }
       }
    }

    func setup(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var timezoneLongitude: CGFloat {
        let timezone = viewModel?.config.timezone ?? Calendar.current.timeZone
        let logitude = (CGFloat(timezone.secondsFromGMT()) - timezone.daylightSavingTimeOffset()) / 240
        return ((logitude + 180) %% 360) - 180
    }

    var locationEnabled: Bool {
        get {
            viewModel?.location != nil
        } set {
            if newValue {
                viewModel?.config.customLocation = viewModel?.config.customLocation ?? GeoLocation(lat: 0.0, lon: timezoneLongitude)
            } else {
                viewModel?.config.locationEnabled = false
                viewModel?.config.customLocation = nil
                viewModel?.clearLocation()
            }
        }
    }

    var gpsEnabled: Bool {
        get {
            viewModel?.gpsLocationAvailable ?? false
        } set {
            if newValue {
                Task {
                    do throws(LocationError) {
                        try await viewModel?.locationManager.getLocation(wait: .seconds(5))
                        viewModel?.config.locationEnabled = true
                    } catch {
                        self.error = error
                    }
                }
            } else {
                viewModel?.config.locationEnabled = false
                viewModel?.config.customLocation = viewModel?.config.customLocation ?? viewModel?.location ?? GeoLocation(lat: 0.0, lon: timezoneLongitude)
                viewModel?.clearLocation()
            }
        }
    }

    var manualLocation: GeoLocation? {
        viewModel?.config.customLocation
    }

    var latitudeSelection: LocationSelection {
        get {
            LocationSelection.from(value: manualLocation?.lat ?? 0)
        } set {
            viewModel?.config.customLocation = GeoLocation(lat: newValue.value, lon: viewModel?.config.customLocation?.lon ?? 0)
        }
    }

    var longitudeSelection: LocationSelection {
        get {
            LocationSelection.from(value: manualLocation?.lon ?? CGFloat(Calendar.current.timeZone.secondsFromGMT()) / 240)
        } set {
            viewModel?.config.customLocation? = GeoLocation(lat: viewModel?.config.customLocation?.lat ?? 0, lon: newValue.value)
        }
    }

    var location: GeoLocation? {
        viewModel?.location
    }
}

#if os(macOS) || os(visionOS)
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
        HStack {
            Text(title)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("", value: $tempValue, formatter: formatter)
                .labelsHidden()
#if os(iOS) || os(visionOS)
                .keyboardType(.decimalPad)
#endif
                .focused($isFocused)
                .autocorrectionDisabled()
                .onSubmit(of: .text) {
                    value = tempValue
                }
                .onChange(of: isFocused) {
                    if !isFocused {
                        value = tempValue
                    }
                }
#if os(macOS)
                .frame(height: 20)
#elseif os(visionOS)
                .frame(height: 40)
#endif
                .padding(.leading, 15)
#if os(visionOS)
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 10))
                .contentShape(.hoverEffect, .rect(cornerRadius: 10, style: .continuous))
                .hoverEffect()
#elseif os(macOS)
                .background(in: RoundedRectangle(cornerRadius: 10))
#endif
        }
    }
}
#endif

struct Location: View {
    @State fileprivate var locationData = LocationData()
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        Form {
            Section {
                Toggle("定位", isOn: locationData.binding(\.locationEnabled))
                Toggle("今地", isOn: locationData.binding(\.gpsEnabled))
                    .disabled(!locationData.locationEnabled)
            }
            if locationData.locationEnabled {
                if locationData.gpsEnabled {
                    Section(header: Text("經緯度", comment: "Geo Location section")) {
                        if let location = viewModel.location {
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
                    let latitudeTitle = if let manualLocationDesp {
                        NSLocalizedString("緯度：", comment: "Latitude section") + manualLocationDesp.lat
                    } else {
                        NSLocalizedString("緯度", comment: "Latitude section")
                    }
                    Section(header: Text(latitudeTitle)) {
                        HStack(spacing: 10) {
#if os(iOS)
                            Picker("度", selection: locationData.binding(\.latitudeSelection.degree)) {
                                ForEach(0...89, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.latitudeSelection)
                            Picker("分", selection: locationData.binding(\.latitudeSelection.minute)) {
                                ForEach(0...59, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.latitudeSelection)
                            Picker("秒", selection: locationData.binding(\.latitudeSelection.second)) {
                                ForEach(0...60, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.latitudeSelection)
#elseif os(macOS) || os(visionOS)
                            OnSubmitTextField("度", value: locationData.binding(\.latitudeSelection.degree), formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 89
                                formatter.minimum = 0
                                return formatter
                            }())
                            Divider()
                            OnSubmitTextField("分", value: locationData.binding(\.latitudeSelection.minute), formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 59
                                formatter.minimum = 0
                                return formatter
                            }())
                            Divider()
                            OnSubmitTextField("秒", value: locationData.binding(\.latitudeSelection.second), formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 60
                                formatter.minimum = 0
                                return formatter
                            }())
                            Divider()
#endif
                            Picker("北南", selection: locationData.binding(\.latitudeSelection.positive)) {
                                ForEach([true, false], id: \.self) { value in
                                    Text(value ? NSLocalizedString("北", comment: "N in geo location") : NSLocalizedString("南", comment: "S in geo location"))
                                }
                            }
                            .animation(.default, value: locationData.latitudeSelection)
                        }
#if os(iOS)
                        .pickerStyle(.wheel)
                        .frame(maxHeight: 125)
#elseif os(macOS)
                        .pickerStyle(.menu)
                        .frame(height: 20)
#endif
                    }

                    let longitudeTitle = if let manualLocationDesp {
                        NSLocalizedString("經度：", comment: "Longitude section") + manualLocationDesp.lon
                    } else {
                        NSLocalizedString("經度", comment: "Longitude section")
                    }
                    Section(header: Text(longitudeTitle)) {
                        HStack(spacing: 10) {
#if os(iOS)
                            Picker("度", selection: locationData.binding(\.longitudeSelection.degree)) {
                                ForEach(0...179, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.longitudeSelection)
                            Picker("分", selection: locationData.binding(\.longitudeSelection.minute)) {
                                ForEach(0...59, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.longitudeSelection)
                            Picker("秒", selection: locationData.binding(\.longitudeSelection.second)) {
                                ForEach(0...60, id: \.self) { value in
                                    Text("\(value)")
                                }
                            }
                            .animation(.default, value: locationData.longitudeSelection)
#elseif os(macOS) || os(visionOS)
                            OnSubmitTextField("度", value: locationData.binding(\.longitudeSelection.degree), formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 179
                                formatter.minimum = 0
                                return formatter
                            }())
                            Divider()
                            OnSubmitTextField("分", value: locationData.binding(\.longitudeSelection.minute), formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 59
                                formatter.minimum = 0
                                return formatter
                            }())
                            Divider()
                            OnSubmitTextField("秒", value: locationData.binding(\.longitudeSelection.second), formatter: {
                                let formatter = NumberFormatter()
                                formatter.maximumFractionDigits = 0
                                formatter.maximum = 60
                                formatter.minimum = 0
                                return formatter
                            }())
                            Divider()
#endif
                            Picker("東西", selection: locationData.binding(\.longitudeSelection.positive)) {
                                ForEach([true, false], id: \.self) { value in
                                    Text(value ? NSLocalizedString("東", comment: "E in geo location") : NSLocalizedString("西", comment: "W in geo location"))
                                }
                            }
                            .animation(.default, value: locationData.longitudeSelection)
                        }
#if os(iOS)
                        .pickerStyle(.wheel)
                        .frame(maxHeight: 125)
#elseif os(macOS)
                        .pickerStyle(.menu)
#endif
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert("迷蹤難尋", isPresented: locationData.binding(\.presentError)) {
            Button("罷", role: .cancel) {}
        } message: {
            let errorMessage = switch locationData.error {
            case .authorizationDenied:
                Text("未開啓本 App 定位。如欲使用 GPS 定位，請於設置中啓用", comment: "Location authorization denied")
            case .authorizationDeniedGlobally:
                Text("未開啓本機定位。如欲使用 GPS 定位，請於設置中啓用", comment: "Location authorization denied globally")
            case .authorizationRestricted:
                Text("定位受限。如欲使用 GPS 定位，請於設置中啓用", comment: "Location authorization restricted")
            case .locationUnavailable:
                Text("暫未能獲取定位，請稍後再試", comment: "Location unavailable")
            case .updateError:
                Text("獲取 GPS 時出錯", comment: "location update error")
            case .none:
                Text("")
            }
            errorMessage
        }
        .task {
            locationData.setup(viewModel: viewModel)
        }
        .onChange(of: locationData.location) {
            viewModel.updateChineseCalendar()
        }
        .navigationTitle(Text("經緯度", comment: "Geo Location section"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
                viewModel.settings.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#endif
    }
}

#Preview("Location", traits: .modifier(SampleData())) {
    Location()
}
