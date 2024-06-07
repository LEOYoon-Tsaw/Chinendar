//
//  MetaLayout.swift
//  Chinendar
//
//  Created by Leo Liu on 4/27/23.
//

import CoreGraphics
import Foundation
import Observation
import SwiftData
import SwiftUI

private let displayP3 = CGColorSpace(name: CGColorSpace.displayP3)!

extension CGColor {
    var hexCode: String {
        var colorString = "0x"
        let colorWithColorspace = converted(to: displayP3, intent: .defaultIntent, options: nil) ?? self
        colorString += String(format: "%02X", Int(round(colorWithColorspace.components![3] * 255)))
        colorString += String(format: "%02X", Int(round(colorWithColorspace.components![2] * 255)))
        colorString += String(format: "%02X", Int(round(colorWithColorspace.components![1] * 255)))
        colorString += String(format: "%02X", Int(round(colorWithColorspace.components![0] * 255)))
        return colorString
    }
}

protocol OptionalType {
    associatedtype Wrapped
    var optional: Wrapped? { get }
}

extension Optional: OptionalType {
    var optional: Self { self }
}

extension Array where Element: OptionalType {
    func flattened() -> [Element.Wrapped]? {
        var newArray = [Element.Wrapped]()
        for item in self {
            if item.optional == nil {
                return nil
            } else {
                newArray.append(item.optional!)
            }
        }
        return newArray
    }
}

extension String {
    var intValue: Int? {
        let string = trimmingCharacters(in: .whitespaces)
        if string.isEmpty {
            return nil
        } else {
            return Int(string)
        }
    }

    var floatValue: CGFloat? {
        let string = trimmingCharacters(in: .whitespaces)
        if string.isEmpty {
            return nil
        } else {
            return Double(string).map { CGFloat($0) }
        }
    }

    var boolValue: Bool? {
        guard !isEmpty else {
            return nil
        }
        let trimmedString = trimmingCharacters(in: .whitespaces).lowercased()
        if ["true", "yes"].contains(trimmedString) {
            return true
        } else if ["false", "no"].contains(trimmedString) {
            return false
        } else {
            return nil
        }
    }

    var colorValue: CGColor? {
        let string = trimmingCharacters(in: .whitespaces)
        guard !string.isEmpty else {
            return nil
        }
        var r = 0, g = 0, b = 0, a = 0xff
        if string.count == 10 {
            // 0xffccbbaa
            let regex = /^0x([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/
            let matches = try? regex.firstMatch(in: string)?.output
            if let matches = matches {
                r = Int(matches.4, radix: 16)!
                g = Int(matches.3, radix: 16)!
                b = Int(matches.2, radix: 16)!
                a = Int(matches.1, radix: 16)!
            } else {
                return nil
            }
        } else if string.count == 8 {
            // 0xccbbaa
            let regex = /^0x([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/
            let matches = try? regex.firstMatch(in: string)?.output
            if let matches = matches {
                r = Int(matches.3, radix: 16)!
                g = Int(matches.2, radix: 16)!
                b = Int(matches.1, radix: 16)!
            } else {
                return nil
            }
        }
        return CGColor(colorSpace: displayP3, components: [CGFloat(r)/255, CGFloat(g)/255, CGFloat(b)/255, CGFloat(a)/255])
    }
}

private func extract(from str: String, inner: Bool = false) -> [String: String] {
    let regex = if inner {
        /([a-zA-Z_0-9]+)\s*:[\s"]*([^\s"#][^"#]*)[\s"#]*(#*.*)$/
    } else {
        /^([a-zA-Z_0-9]+)\s*:[\s"]*([^\s"#][^"#]*)[\s"#]*(#*.*)$/
    }
    var values = [String: String]()
    for line in str.split(whereSeparator: \.isNewline) {
        if let match = try? regex.firstMatch(in: String(line))?.output {
            values[String(match.1)] = String(match.2)
        }
    }
    return values
}

func applyGradient(gradient: WatchLayout.Gradient, startingAngle: CGFloat) -> Gradient {
    let colors: [CGColor]
    let locations: [CGFloat]
    if startingAngle >= 0 {
        colors = gradient.colors.reversed()
        locations = gradient.locations.map { 1 - $0 }.reversed()
    } else {
        colors = gradient.colors
        locations = gradient.locations
    }
    return Gradient(stops: zip(colors, locations).map { Gradient.Stop(color: Color(cgColor: $0.0), location: $0.1) })
}

@Observable class MetaWatchLayout {
    struct Gradient {
        private let _locations: [CGFloat]
        private let _colors: [CGColor]
        let isLoop: Bool

        init(locations: [CGFloat], colors: [CGColor], loop: Bool) {
            guard locations.count == colors.count else {
                fatalError("Gradient locations count does not equal colors count")
            }
            var colorAndLocation = Array(zip(colors, locations))
            colorAndLocation.sort { former, latter in
                former.1 < latter.1
            }
            _locations = colorAndLocation.map { $0.1 }
            _colors = colorAndLocation.map { $0.0 }
            isLoop = loop
        }

        func interpolate(at: CGFloat) -> CGColor {
            let locations = self.locations
            let colors = self.colors
            let nextIndex = locations.firstIndex { $0 >= at }
            if let nextIndex = nextIndex {
                let previousIndex = nextIndex.advanced(by: -1)
                if previousIndex >= locations.startIndex {
                    let leftColor = colors[previousIndex]
                    let rightColor = colors[nextIndex]
                    var ratio = (at - locations[previousIndex])/(locations[nextIndex] - locations[previousIndex])
                    ratio = max(0.0, min(1.0, ratio))
                    let leftComponents = leftColor.converted(to: displayP3, intent: .perceptual, options: nil)!.components!
                    let rightComponents = rightColor.converted(to: displayP3, intent: .perceptual, options: nil)!.components!
                    let newComponents = zip(leftComponents, rightComponents).map { (1 - ratio) * $0.0 + ratio * $0.1 }
                    let newColor = CGColor(colorSpace: displayP3, components: newComponents)
                    return newColor!
                } else {
                    return colors.first!
                }
            } else {
                return colors.last!
            }
        }

        var locations: [CGFloat] {
            if isLoop {
                return _locations + [1]
            } else {
                return _locations
            }
        }

        var colors: [CGColor] {
            if isLoop {
                return _colors + [_colors[0]]
            } else {
                return _colors
            }
        }

        func encode() -> String {
            var encoded = ""
            let locationString = _locations.map { "\($0)" }.joined(separator: ", ")
            encoded += "locations: \(locationString)\n"
            let colorString = _colors.map { $0.hexCode }.joined(separator: ", ")
            encoded += "colors: \(colorString)\n"
            encoded += "loop: \(isLoop)"
            return encoded
        }

        init?(from str: String?) {
            guard let str = str else { return nil }
            let values = extract(from: str, inner: true)
            guard let newLocations = values["locations"]?.split(separator: ","), let newColors = values["colors"]?.split(separator: ","), let isLoop = values["loop"]?.boolValue else { return nil }
            let locations = Array(newLocations).map { $0.trimmingCharacters(in: .whitespaces).floatValue }
            let colors = Array(newColors).map { $0.trimmingCharacters(in: .whitespaces).colorValue }
            guard let loc = locations.flattened(), let col = colors.flattened() else { return nil }
            _locations = loc
            _colors = col
            self.isLoop = isLoop
        }
    }

    struct StartingPhase {
        var zeroRing: CGFloat = 0.0
        var firstRing: CGFloat = 0.0
        var secondRing: CGFloat = 0.0
        var thirdRing: CGFloat = 0.0
        var fourthRing: CGFloat = 0.0

        init() { }

        func encode() -> String {
            var encoded = ""
            encoded += "zeroRing: \(zeroRing)\n"
            encoded += "firstRing: \(firstRing)\n"
            encoded += "secondRing: \(secondRing)\n"
            encoded += "thirdRing: \(thirdRing)\n"
            encoded += "fourthRing: \(fourthRing)\n"
            return encoded
        }

        init?(from str: String?) {
            guard let str = str else { return nil }
            let values = extract(from: str, inner: true)
            zeroRing = values["zeroRing"]?.floatValue ?? zeroRing
            firstRing = values["firstRing"]?.floatValue ?? firstRing
            secondRing = values["secondRing"]?.floatValue ?? secondRing
            thirdRing = values["thirdRing"]?.floatValue ?? thirdRing
            fourthRing = values["fourthRing"]?.floatValue ?? fourthRing
        }
    }

    @ObservationIgnored var initialized = false
    var firstRing = Gradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
    var secondRing = Gradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
    var thirdRing = Gradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
    var startingPhase = StartingPhase()
    var innerColor = CGColor(gray: 0, alpha: 0)
    var backColor = CGColor(gray: 1, alpha: 1)
    var majorTickColor = CGColor(gray: 0, alpha: 0)
    var minorTickColor = CGColor(gray: 0, alpha: 0)
    var majorTickAlpha: CGFloat = 0
    var minorTickAlpha: CGFloat = 0.7
    var fontColor = CGColor(gray: 0, alpha: 1)
    var centerFontColor = Gradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
    var evenSolarTermTickColor = CGColor(gray: 1, alpha: 1)
    var oddSolarTermTickColor = CGColor(gray: 0.67, alpha: 1)
    var innerColorDark = CGColor(gray: 0, alpha: 0)
    var backColorDark = CGColor(gray: 0, alpha: 1)
    var majorTickColorDark = CGColor(gray: 0, alpha: 0)
    var minorTickColorDark = CGColor(gray: 0, alpha: 0)
    var fontColorDark = CGColor(gray: 0, alpha: 1)
    var evenSolarTermTickColorDark = CGColor(gray: 1, alpha: 1)
    var oddSolarTermTickColorDark = CGColor(gray: 0.67, alpha: 1)
    var planetIndicator = Planets(moon: CGColor(gray: 0.3, alpha: 1), mercury: CGColor(gray: 0.4, alpha: 1), venus: CGColor(gray: 0.5, alpha: 1), mars: CGColor(gray: 0.6, alpha: 1), jupiter: CGColor(gray: 0.7, alpha: 1), saturn: CGColor(gray: 0.8, alpha: 1))
    var sunPositionIndicator = Solar(midnight: CGColor(gray: 0.3, alpha: 1), sunrise: CGColor(gray: 0.4, alpha: 1), noon: CGColor(gray: 0.5, alpha: 1), sunset: CGColor(gray: 0.6, alpha: 1))
    var moonPositionIndicator = Lunar(moonrise: CGColor(gray: 0.4, alpha: 1), highMoon: CGColor(gray: 0.5, alpha: 1), moonset: CGColor(gray: 0.6, alpha: 1))
    var eclipseIndicator = CGColor(gray: 0.3, alpha: 1)
    var fullmoonIndicator = CGColor(gray: 0.4, alpha: 1)
    var oddStermIndicator = CGColor(gray: 0.5, alpha: 1)
    var evenStermIndicator = CGColor(gray: 0.6, alpha: 1)
    var shadeAlpha: CGFloat = 0
    var shadowSize: CGFloat = 0.03
    var centerTextOffset: CGFloat = 0
    var centerTextHOffset: CGFloat = 0
    var verticalTextOffset: CGFloat = 0
    var horizontalTextOffset: CGFloat = 0
    var watchSize: CGSize = .zero
    var cornerRadiusRatio: CGFloat = 0

    func encode(includeOffset: Bool = true, includeColor: Bool = true) -> String {
        var encoded = ""
        if includeColor {
            encoded += "firstRing: \(firstRing.encode().replacingOccurrences(of: "\n", with: "; "))\n"
            encoded += "secondRing: \(secondRing.encode().replacingOccurrences(of: "\n", with: "; "))\n"
            encoded += "thirdRing: \(thirdRing.encode().replacingOccurrences(of: "\n", with: "; "))\n"
            encoded += "innerColor: \(innerColor.hexCode)\n"
            encoded += "backColor: \(backColor.hexCode)\n"
            encoded += "majorTickColor: \(majorTickColor.hexCode)\n"
            encoded += "majorTickAlpha: \(majorTickAlpha)\n"
            encoded += "minorTickColor: \(minorTickColor.hexCode)\n"
            encoded += "minorTickAlpha: \(minorTickAlpha)\n"
            encoded += "fontColor: \(fontColor.hexCode)\n"
            encoded += "centerFontColor: \(centerFontColor.encode().replacingOccurrences(of: "\n", with: "; "))\n"
            encoded += "evenSolarTermTickColor: \(evenSolarTermTickColor.hexCode)\n"
            encoded += "oddSolarTermTickColor: \(oddSolarTermTickColor.hexCode)\n"
            encoded += "innerColorDark: \(innerColorDark.hexCode)\n"
            encoded += "backColorDark: \(backColorDark.hexCode)\n"
            encoded += "majorTickColorDark: \(majorTickColorDark.hexCode)\n"
            encoded += "minorTickColorDark: \(minorTickColorDark.hexCode)\n"
            encoded += "fontColorDark: \(fontColorDark.hexCode)\n"
            encoded += "evenSolarTermTickColorDark: \(evenSolarTermTickColorDark.hexCode)\n"
            encoded += "oddSolarTermTickColorDark: \(oddSolarTermTickColorDark.hexCode)\n"
            encoded += "planetIndicator: \(planetIndicator.encode([\.mercury, \.venus, \.mars, \.jupiter, \.saturn, \.moon]))\n"
            encoded += "eclipseIndicator: \(eclipseIndicator.hexCode)\n"
            encoded += "fullmoonIndicator: \(fullmoonIndicator.hexCode)\n"
            encoded += "oddStermIndicator: \(oddStermIndicator.hexCode)\n"
            encoded += "evenStermIndicator: \(evenStermIndicator.hexCode)\n"
            encoded += "sunPositionIndicator: \(sunPositionIndicator.encode([\.midnight, \.sunrise, \.noon, \.sunset]))\n"
            encoded += "moonPositionIndicator: \(moonPositionIndicator.encode([\.moonrise, \.highMoon, \.moonset]))\n"
            encoded += "shadeAlpha: \(shadeAlpha)\n"
            encoded += "shadowSize: \(shadowSize)\n"
        }
        if includeOffset {
            encoded += "centerTextOffset: \(centerTextOffset)\n"
            encoded += "centerTextHorizontalOffset: \(centerTextHOffset)\n"
            encoded += "verticalTextOffset: \(verticalTextOffset)\n"
            encoded += "horizontalTextOffset: \(horizontalTextOffset)\n"
            encoded += "watchWidth: \(watchSize.width)\n"
            encoded += "watchHeight: \(watchSize.height)\n"
            encoded += "cornerRadiusRatio: \(cornerRadiusRatio)\n"
        }
        encoded += "startingPhase: \(startingPhase.encode().replacingOccurrences(of: "\n", with: "; "))\n"
        return encoded
    }

    func update(from values: [String: String], updateSize: Bool = true) {
        let seperatorRegex = /(\s*;|\{\})/
        func expand(value: String?) -> String? {
            guard let value = value else { return nil }
            return value.replacing(seperatorRegex) { _ in "\n" }
        }

        initialized = true
        self.withMutation(keyPath: \.firstRing) {
            _firstRing = Gradient(from: expand(value: values["firstRing"])) ?? _firstRing
            _secondRing = Gradient(from: expand(value: values["secondRing"])) ?? _secondRing
            _thirdRing = Gradient(from: expand(value: values["thirdRing"])) ?? _thirdRing
            _startingPhase = StartingPhase(from: expand(value: values["startingPhase"])) ?? _startingPhase
            _innerColor = values["innerColor"]?.colorValue ?? _innerColor
            _backColor = values["backColor"]?.colorValue ?? _backColor
            _majorTickColor = values["majorTickColor"]?.colorValue ?? _majorTickColor
            _majorTickAlpha = values["majorTickAlpha"]?.floatValue ?? _majorTickAlpha
            _minorTickColor = values["minorTickColor"]?.colorValue ?? _minorTickColor
            _minorTickAlpha = values["minorTickAlpha"]?.floatValue ?? _minorTickAlpha
            _fontColor = values["fontColor"]?.colorValue ?? _fontColor
            _centerFontColor = Gradient(from: expand(value: values["centerFontColor"])) ?? _centerFontColor
            _evenSolarTermTickColor = values["evenSolarTermTickColor"]?.colorValue ?? _evenSolarTermTickColor
            _oddSolarTermTickColor = values["oddSolarTermTickColor"]?.colorValue ?? _oddSolarTermTickColor
            _innerColorDark = values["innerColorDark"]?.colorValue ?? _innerColorDark
            _backColorDark = values["backColorDark"]?.colorValue ?? _backColorDark
            _majorTickColorDark = values["majorTickColorDark"]?.colorValue ?? _majorTickColorDark
            _minorTickColorDark = values["minorTickColorDark"]?.colorValue ?? _minorTickColorDark
            _fontColorDark = values["fontColorDark"]?.colorValue ?? _fontColorDark
            _evenSolarTermTickColorDark = values["evenSolarTermTickColorDark"]?.colorValue ?? _evenSolarTermTickColorDark
            _oddSolarTermTickColorDark = values["oddSolarTermTickColorDark"]?.colorValue ?? _oddSolarTermTickColorDark
            _planetIndicator.read(string: values["planetIndicator"], to: [\.mercury, \.venus, \.mars, \.jupiter, \.saturn, \.moon])
            _sunPositionIndicator.read(string: values["sunPositionIndicator"], to: [\.midnight, \.sunrise, \.noon, \.sunset])
            _moonPositionIndicator.read(string: values["moonPositionIndicator"], to: [\.moonrise, \.highMoon, \.moonset])
            _eclipseIndicator = values["eclipseIndicator"]?.colorValue ?? _eclipseIndicator
            _fullmoonIndicator = values["fullmoonIndicator"]?.colorValue ?? _fullmoonIndicator
            _oddStermIndicator = values["oddStermIndicator"]?.colorValue ?? _oddStermIndicator
            _evenStermIndicator = values["evenStermIndicator"]?.colorValue ?? _evenStermIndicator
            _shadeAlpha = values["shadeAlpha"]?.floatValue ?? _shadeAlpha
            _shadowSize = values["shadowSize"]?.floatValue ?? _shadowSize
            _centerTextOffset = values["centerTextOffset"]?.floatValue ?? _centerTextOffset
            _centerTextHOffset = values["centerTextHorizontalOffset"]?.floatValue ?? _centerTextHOffset
            _verticalTextOffset = values["verticalTextOffset"]?.floatValue ?? _verticalTextOffset
            _horizontalTextOffset = values["horizontalTextOffset"]?.floatValue ?? _horizontalTextOffset
            if updateSize {
                if let width = values["watchWidth"]?.floatValue, let height = values["watchHeight"]?.floatValue {
                    _watchSize = CGSize(width: width, height: height)
                }
            }
            _cornerRadiusRatio = values["cornerRadiusRatio"]?.floatValue ?? _cornerRadiusRatio
        }
    }

    func update(from str: String, updateSize: Bool = true) {
        let values = extract(from: str)
        update(from: values, updateSize: updateSize)
    }

    func loadStatic() {
        let filePath = Bundle.main.path(forResource: "layout", ofType: "txt")!
        let defaultLayout = try! String(contentsOfFile: filePath)
        self.update(from: defaultLayout)
    }

    func loadDefault(context: ModelContext, local: Bool = false) {
        let defaultName = AppInfo.defaultName
        let predicate = {
            let deviceName = if local {
                LocalData.read(context: LocalSchema.context)?.deviceName ?? AppInfo.deviceName
            } else {
                AppInfo.deviceName
            }
            return #Predicate<ThemeData> { data in
                data.name == defaultName && data.deviceName == deviceName
            }
        }()
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])

        var found = false
        do {
            let themes = try context.fetch(descriptor)
            for theme in themes {
                if !found && !theme.isNil {
                    self.update(from: theme.code!)
                    found = true
                    break
                }
            }
        } catch {
            print(error.localizedDescription)
        }

        if !found {
            let filePath = Bundle.main.path(forResource: "layout", ofType: "txt")!
            let defaultLayout = try! String(contentsOfFile: filePath)
            self.update(from: defaultLayout)
        }
    }

    @MainActor func saveDefault(context: ModelContext) {
        let defaultName = AppInfo.defaultName
        let deviceName = AppInfo.deviceName
        try? LocalData.write(context: LocalSchema.container.mainContext, deviceName: deviceName)

        let predicate = #Predicate<ThemeData> { data in
            data.name == defaultName && data.deviceName == deviceName
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        var found = false
        do {
            let themes = try context.fetch(descriptor)
            for theme in themes {
                if !found && !theme.isNil {
                    theme.update(code: self.encode())
                    found = true
                } else {
                    context.delete(theme)
                }
            }
        } catch {
            print(error.localizedDescription)
        }

        if !found {
            let defaultTheme = ThemeData(name: AppInfo.defaultName, code: self.encode())
            context.insert(defaultTheme)
        }
    }

    func autoSave() {
        withObservationTracking {
            _ = self.encode()
        } onChange: {
            Task { @MainActor in
                let context = DataSchema.container.mainContext
                self.saveDefault(context: context)
                self.autoSave()
            }
        }
    }
}

@Observable final class CalendarConfigure {

#if os(iOS)
    @ObservationIgnored var watchConnectivity: WatchConnectivityManager?
#endif
    @ObservationIgnored var initialized = false
    var name: String = AppInfo.defaultName
    var globalMonth: Bool = false
    var apparentTime: Bool = false
    var largeHour: Bool = false
    var locationEnabled: Bool = true
    var customLocation: GeoLocation?
    var timezone: TimeZone?
    var effectiveTimezone: TimeZone {
        timezone ?? Calendar.current.timeZone
    }

    convenience init(from code: String, name: String? = nil) {
        self.init()
        self.update(from: code, newName: name)
    }

    func location(locationManager: LocationManager?) -> GeoLocation? {
        if locationEnabled, let locationManager = locationManager {
            return locationManager.location ?? customLocation
        } else {
            return customLocation
        }
    }

    func encode(withName: Bool = false) -> String {
        var encoded = ""
        if withName {
            encoded += "name: \(name)\n"
        }
        encoded += "globalMonth: \(globalMonth)\n"
        encoded += "apparentTime: \(apparentTime)\n"
        encoded += "largeHour: \(largeHour)\n"
        encoded += "locationEnabled: \(locationEnabled)\n"
        if let location = customLocation {
            encoded += "customLocation: \(location.encode())\n"
        }
        if let timezone = timezone {
            encoded += "timezone: \(timezone.identifier)\n"
        }
        return encoded
    }

    private func update(from values: [String: String], newName: String?) {
        initialized = true
        self.withMutation(keyPath: \.name) {
            _name = newName ?? values["name"] ?? _name
            _globalMonth = values["globalMonth"]?.boolValue ?? _globalMonth
            _apparentTime = values["apparentTime"]?.boolValue ?? _apparentTime
            _largeHour = values["largeHour"]?.boolValue ?? _largeHour
            _locationEnabled = values["locationEnabled"]?.boolValue ?? _locationEnabled
            _customLocation = GeoLocation(from: values["customLocation"])
            if let tzStr = values["timezone"], let tz = TimeZone(identifier: tzStr) {
                _timezone = tz
            } else {
                _timezone = nil
            }
        }
    }

    func update(from str: String, newName: String? = nil) {
        let values = extract(from: str)
        update(from: values, newName: newName)
    }

    func load(name: String?, context: ModelContext) {
        let descriptor: FetchDescriptor<ConfigData>
        if let name = name {
            let predicate = #Predicate<ConfigData> { data in
                data.name == name
            }
            descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        } else {
            descriptor = FetchDescriptor(sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        }
        var found = false
        do {
            let configs = try context.fetch(descriptor)
            for config in configs {
                if !found && !config.isNil {
                    self.update(from: config.code!, newName: config.name!)
                    found = true
                    break
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func save(context: ModelContext) {
        let name = name
        let predicate = #Predicate<ConfigData> { data in
            data.name == name
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        var found = false
        do {
            let configs = try context.fetch(descriptor)
            for config in configs {
                if !found && !config.isNil {
                    config.update(code: self.encode(), name: name)
                    found = true
                } else {
                    context.delete(config)
                }
            }
        } catch {
            print(error.localizedDescription)
        }

        if !found {
            let config = ConfigData(name: self.name, code: self.encode())
            context.insert(config)
        }
    }

    func sendToWatch() {
#if os(iOS)
        self.watchConnectivity?.send(messages: [
            "config": self.encode(withName: true)
        ])
#endif
    }

    @MainActor func saveName() {
        do {
            try LocalData.write(context: LocalSchema.container.mainContext, configName: self.name)
        } catch {
            print(error.localizedDescription)
        }
    }

    func autoSaveName() {
        withObservationTracking {
            _ = self.name
        } onChange: {
            Task { @MainActor in
                self.saveName()
                self.autoSaveName()
            }
        }
    }

    func autoSave() {
        withObservationTracking {
            _ = self.encode(withName: true)
        } onChange: {
            Task { @MainActor in
                let context = DataSchema.container.mainContext
                self.save(context: context)
                self.sendToWatch()
                self.autoSave()
            }
        }
    }
}

private protocol ReadWrite {
    mutating func read(string list: String?, to properties: [WritableKeyPath<Self, CGColor>])
    func encode(_ properties: [KeyPath<Self, CGColor>]) -> String
}

private extension ReadWrite {
    mutating func read(string list: String?, to properties: [WritableKeyPath<Self, CGColor>]) {
        if let colorValues = list {
            let colorList = colorValues.split(separator: ",").compactMap { color in
                String(color).colorValue
            }
            guard colorList.count == properties.count else { return }
            for i in 0..<colorList.count {
                self[keyPath: properties[i]] = colorList[i]
            }
        }
    }
    
    func encode(_ properties: [KeyPath<Self, CGColor>]) -> String {
        properties.map { self[keyPath: $0].hexCode }.joined(separator: ", ")
    }
}

extension Planets<CGColor> : ReadWrite {}
extension Solar<CGColor> : ReadWrite {}
extension Lunar<CGColor> : ReadWrite {}
