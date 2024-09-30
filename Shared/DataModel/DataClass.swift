//
//  MetaLayout.swift
//  Chinendar
//
//  Created by Leo Liu on 4/27/23.
//

import CoreGraphics
import Foundation
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
            if let matches {
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
            if let matches {
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

func extract(from str: String, inner: Bool = false) -> [String: String] {
    let regex = if inner {
        /([a-zA-Z_0-9]+)\s*:[\s"]*([^\s"#][^"#]*)[\s"#]*(#*.*)$/
    } else {
        /^([a-zA-Z_0-9]+)\s*:[\s"]*([^\s"#][^"#]*)[\s"#]*(#*.*)$/
    }
    var values: [String: String] = [:]
    for line in str.split(whereSeparator: \.isNewline) {
        if let match = try? regex.firstMatch(in: String(line))?.output {
            values[String(match.1)] = String(match.2)
        }
    }
    return values
}

func applyGradient(gradient: BaseLayout.Gradient, startingAngle: CGFloat) -> Gradient {
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

protocol LayoutExpressible: Sendable {
    func encode(includeOffset: Bool, includeColor: Bool) -> String
    mutating func update(from: String, updateSize: Bool) -> [String: String]
}

struct BaseLayout: LayoutExpressible, Equatable {
    struct Gradient: Equatable {
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
            if let nextIndex {
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

    struct StartingPhase: Equatable {
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

    var initialized = false
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

    private mutating func update(from values: [String: String], updateSize: Bool = true) {
        let seperatorRegex = /(\s*;|\{\})/
        func expand(value: String?) -> String? {
            guard let value = value else { return nil }
            return value.replacing(seperatorRegex) { _ in "\n" }
        }

        initialized = true
        firstRing ?= Gradient(from: expand(value: values["firstRing"]))
        secondRing ?= Gradient(from: expand(value: values["secondRing"]))
        thirdRing ?= Gradient(from: expand(value: values["thirdRing"]))
        startingPhase ?= StartingPhase(from: expand(value: values["startingPhase"]))
        innerColor ?= values["innerColor"]?.colorValue
        backColor ?= values["backColor"]?.colorValue
        majorTickColor ?= values["majorTickColor"]?.colorValue
        majorTickAlpha ?= values["majorTickAlpha"]?.floatValue
        minorTickColor ?= values["minorTickColor"]?.colorValue
        minorTickAlpha ?= values["minorTickAlpha"]?.floatValue
        fontColor ?= values["fontColor"]?.colorValue
        centerFontColor ?= Gradient(from: expand(value: values["centerFontColor"]))
        evenSolarTermTickColor ?= values["evenSolarTermTickColor"]?.colorValue
        oddSolarTermTickColor ?= values["oddSolarTermTickColor"]?.colorValue
        innerColorDark ?= values["innerColorDark"]?.colorValue
        backColorDark ?= values["backColorDark"]?.colorValue
        majorTickColorDark ?= values["majorTickColorDark"]?.colorValue
        minorTickColorDark ?= values["minorTickColorDark"]?.colorValue
        fontColorDark ?= values["fontColorDark"]?.colorValue
        evenSolarTermTickColorDark ?= values["evenSolarTermTickColorDark"]?.colorValue
        oddSolarTermTickColorDark ?= values["oddSolarTermTickColorDark"]?.colorValue
        planetIndicator.read(string: values["planetIndicator"], to: [\.mercury, \.venus, \.mars, \.jupiter, \.saturn, \.moon])
        sunPositionIndicator.read(string: values["sunPositionIndicator"], to: [\.midnight, \.sunrise, \.noon, \.sunset])
        moonPositionIndicator.read(string: values["moonPositionIndicator"], to: [\.moonrise, \.highMoon, \.moonset])
        eclipseIndicator ?= values["eclipseIndicator"]?.colorValue
        fullmoonIndicator ?= values["fullmoonIndicator"]?.colorValue
        oddStermIndicator ?= values["oddStermIndicator"]?.colorValue
        evenStermIndicator ?= values["evenStermIndicator"]?.colorValue
        shadeAlpha ?= values["shadeAlpha"]?.floatValue
        shadowSize ?= values["shadowSize"]?.floatValue
        centerTextOffset ?= values["centerTextOffset"]?.floatValue
        centerTextHOffset ?= values["centerTextHorizontalOffset"]?.floatValue
        verticalTextOffset ?= values["verticalTextOffset"]?.floatValue
        horizontalTextOffset ?= values["horizontalTextOffset"]?.floatValue
        if updateSize {
            if let width = values["watchWidth"]?.floatValue, let height = values["watchHeight"]?.floatValue {
                watchSize = CGSize(width: width, height: height)
            }
        }
        cornerRadiusRatio ?= values["cornerRadiusRatio"]?.floatValue
    }

    @discardableResult mutating func update(from str: String, updateSize: Bool = true) -> [String: String] {
        let values = extract(from: str)
        update(from: values, updateSize: updateSize)
        return values
    }

    @discardableResult mutating func loadStatic() -> [String: String] {
        self.update(from: ThemeData.staticLayoutCode)
    }
}

struct CalendarConfigure: Equatable {
    var initialized = false
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

    func location(wait duration: Duration = .seconds(1)) async -> GeoLocation? {
        if locationEnabled {
            try? await LocationManager.shared.getLocation(wait: duration) ?? customLocation
        } else {
            customLocation
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
        if let customLocation {
            encoded += "customLocation: \(customLocation.encode())\n"
        }
        if let timezone {
            encoded += "timezone: \(timezone.identifier)\n"
        }
        return encoded
    }

    mutating func update(from values: [String: String], newName: String?) {
        initialized = true
        name ?= newName ?? values["name"]
        globalMonth ?= values["globalMonth"]?.boolValue
        apparentTime ?= values["apparentTime"]?.boolValue
        largeHour ?= values["largeHour"]?.boolValue
        locationEnabled ?= values["locationEnabled"]?.boolValue
        customLocation = GeoLocation(from: values["customLocation"])
        if let tzStr = values["timezone"], let tz = TimeZone(identifier: tzStr) {
            timezone = tz
        } else {
            timezone = nil
        }
    }

    mutating func update(from str: String, newName: String? = nil) {
        let values = extract(from: str)
        update(from: values, newName: newName)
    }
}

private protocol ReadWrite {
    mutating func read(string list: String?, to properties: [WritableKeyPath<Self, CGColor>])
    func encode(_ properties: [KeyPath<Self, CGColor>]) -> String
}

private extension ReadWrite {
    mutating func read(string colorValues: String?, to properties: [WritableKeyPath<Self, CGColor>]) {
        if let colorValues {
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

extension Planets<CGColor>: ReadWrite {}
extension Solar<CGColor>: ReadWrite {}
extension Lunar<CGColor>: ReadWrite {}

@MainActor
protocol ViewModelType: AnyObject, Bindable {
    associatedtype Base: LayoutExpressible, Equatable
    var baseLayout: BaseLayout { get set }
    var watchLayout: ExtraLayout<Base> { get set }
    var config: CalendarConfigure { get set }
    var settings: WatchSetting { get set }
    var chineseCalendar: ChineseCalendar { get set }
    var locationManager: LocationManager { get }
    var location: GeoLocation? { get }

    var layoutInitialized: Bool { get }
    var configInitialized: Bool { get }
    func layoutString(includeOffset: Bool, includeColor: Bool) -> String
    func configString(withName: Bool) -> String
    func updateLayout(from: String, updateSize: Bool)
    func updateConfig(from: String, newName: String?)
    func setup()
}

extension ViewModelType {
    var baseLayout: Base {
        get {
            watchLayout.baseLayout
        } set {
            watchLayout.baseLayout = newValue
        }
    }
    var layoutInitialized: Bool {
        baseLayout.initialized
    }
    var configInitialized: Bool {
        config.initialized
    }

    func layoutString(includeOffset: Bool = true, includeColor: Bool = true) -> String {
        watchLayout.encode(includeOffset: includeOffset, includeColor: includeColor)
    }
    func configString(withName: Bool = true) -> String {
        config.encode(withName: withName)
    }
    func updateLayout(from layoutString: String, updateSize: Bool = true) {
        watchLayout.update(from: layoutString, updateSize: updateSize)
    }
    func updateConfig(from configString: String, newName: String? = nil) {
        config.update(from: configString, newName: newName)
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
        Task {
            try await self.locationManager.getLocation(wait: .seconds(15))
        }
        let defaultLayout = ThemeData.loadDefault()
        let defaultConfig = ConfigData.loadDefault()
        self.updateLayout(from: defaultLayout)
        if let code = defaultConfig?.code {
            self.updateConfig(from: code)
        }
        LocalData.update(deviceName: AppInfo.deviceName)
    }
}

@MainActor
protocol Bindable {
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>) -> Binding<T>
}

extension Bindable {
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>) -> Binding<T> {
        return Binding(get: { self[keyPath: keyPath] }, set: { self[keyPath: keyPath] = $0 })
    }
}
