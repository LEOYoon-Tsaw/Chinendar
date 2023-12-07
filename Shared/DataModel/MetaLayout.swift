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

extension CGPoint {
    func encode() -> String {
        return "x: \(x), y: \(y)"
    }

    init?(from str: String?) {
        self.init()
        guard let str = str else { return nil }
        let regex = /x:\s*([\-0-9\.]+)\s*,\s*y:\s*([\-0-9\.]+)/
        let matches = try? regex.firstMatch(in: str)?.output
        if let matches = matches, let x = Double(matches.1), let y = Double(matches.2) {
            self.x = x
            self.y = y
        } else {
            return nil
        }
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

@Observable class MetaWatchLayout {
    @Observable final class Gradient {
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
            let regex = /([a-zA-Z_0-9]+)\s*:[\s"]*([^\s"#][^"#]*)[\s"#]*(#*.*)$/
            var values = [String: String]()
            for line in str.split(whereSeparator: \.isNewline) {
                if let match = try? regex.firstMatch(in: String(line))?.output {
                    values[String(match.1)] = String(match.2)
                }
            }
            guard let newLocations = values["locations"]?.split(separator: ","), let newColors = values["colors"]?.split(separator: ","), let isLoop = values["loop"]?.boolValue else { return nil }
            let locations = Array(newLocations).map { $0.trimmingCharacters(in: .whitespaces).floatValue }
            let colors = Array(newColors).map { $0.trimmingCharacters(in: .whitespaces).colorValue }
            guard let loc = locations.flattened(), let col = colors.flattened() else { return nil }
            _locations = loc
            _colors = col
            self.isLoop = isLoop
        }
    }

    @ObservationIgnored var initialized = false
    var globalMonth: Bool = false
    var apparentTime: Bool = false
    var locationEnabled: Bool = true
    var location: CGPoint? = nil
    var firstRing = Gradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
    var secondRing = Gradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
    var thirdRing = Gradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
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
    var planetIndicator: [CGColor] = [CGColor(gray: 0.2, alpha: 1), CGColor(gray: 0.3, alpha: 1), CGColor(gray: 0.4, alpha: 1), CGColor(gray: 0.5, alpha: 1), CGColor(gray: 0.6, alpha: 1), CGColor(gray: 0.7, alpha: 1)]
    var sunPositionIndicator: [CGColor] = [CGColor(gray: 0.3, alpha: 1), CGColor(gray: 0.4, alpha: 1), CGColor(gray: 0.5, alpha: 1), CGColor(gray: 0.6, alpha: 1)]
    var moonPositionIndicator: [CGColor] = [CGColor(gray: 0.4, alpha: 1), CGColor(gray: 0.5, alpha: 1), CGColor(gray: 0.6, alpha: 1)]
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
    
    func encode(includeOffset: Bool = true, includeColor: Bool = true, includeConfig: Bool = true) -> String {
        var encoded = ""
        if includeConfig {
            encoded += "globalMonth: \(globalMonth)\n"
            encoded += "apparentTime: \(apparentTime)\n"
            encoded += "locationEnabled: \(locationEnabled)\n"
            if let location = location {
                encoded += "customLocation: \(location.encode())\n"
            }
        }
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
            encoded += "planetIndicator: \(planetIndicator.map { $0.hexCode }.joined(separator: ", "))\n"
            encoded += "eclipseIndicator: \(eclipseIndicator.hexCode)\n"
            encoded += "fullmoonIndicator: \(fullmoonIndicator.hexCode)\n"
            encoded += "oddStermIndicator: \(oddStermIndicator.hexCode)\n"
            encoded += "evenStermIndicator: \(evenStermIndicator.hexCode)\n"
            encoded += "sunPositionIndicator: \(sunPositionIndicator.map { $0.hexCode }.joined(separator: ", "))\n"
            encoded += "moonPositionIndicator: \(moonPositionIndicator.map { $0.hexCode }.joined(separator: ", "))\n"
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
        return encoded
    }
    
    func extract(from str: String) -> [String: String] {
        let regex = /^([a-zA-Z_0-9]+)\s*:[\s"]*([^\s"#][^"#]*)[\s"#]*(#*.*)$/
        var values = [String: String]()
        for line in str.split(whereSeparator: \.isNewline) {
            if let match = try? regex.firstMatch(in: String(line))?.output {
                values[String(match.1)] = String(match.2)
            }
        }
        return values
    }
    
    func update(from values: [String: String], updateSize: Bool = true) {
        let seperatorRegex = /(\s*;|\{\})/
        func readGradient(value: String?) -> Gradient? {
            guard let value = value else { return nil }
            let newValue = value.replacing(seperatorRegex) { _ in "\n" }
            return Gradient(from: newValue)
        }
        
        func readColorList(_ list: String?) -> [CGColor]? {
            var colors = [CGColor?]()
            if let colorValues = list {
                for color in colorValues.split(separator: ",") {
                    colors.append(String(color).colorValue)
                }
                return colors.flattened()
            } else {
                return nil
            }
        }
        
        initialized = true
        
        globalMonth = values["globalMonth"]?.boolValue ?? globalMonth
        apparentTime = values["apparentTime"]?.boolValue ?? apparentTime
        locationEnabled = values["locationEnabled"]?.boolValue ?? locationEnabled
        location = CGPoint(from: values["customLocation"])
        firstRing = readGradient(value: values["firstRing"]) ?? firstRing
        secondRing = readGradient(value: values["secondRing"]) ?? secondRing
        thirdRing = readGradient(value: values["thirdRing"]) ?? thirdRing
        innerColor = values["innerColor"]?.colorValue ?? innerColor
        backColor = values["backColor"]?.colorValue ?? backColor
        majorTickColor = values["majorTickColor"]?.colorValue ?? majorTickColor
        majorTickAlpha = values["majorTickAlpha"]?.floatValue ?? majorTickAlpha
        minorTickColor = values["minorTickColor"]?.colorValue ?? minorTickColor
        minorTickAlpha = values["minorTickAlpha"]?.floatValue ?? minorTickAlpha
        fontColor = values["fontColor"]?.colorValue ?? fontColor
        centerFontColor = readGradient(value: values["centerFontColor"]) ?? centerFontColor
        evenSolarTermTickColor = values["evenSolarTermTickColor"]?.colorValue ?? evenSolarTermTickColor
        oddSolarTermTickColor = values["oddSolarTermTickColor"]?.colorValue ?? oddSolarTermTickColor
        innerColorDark = values["innerColorDark"]?.colorValue ?? innerColorDark
        backColorDark = values["backColorDark"]?.colorValue ?? backColorDark
        majorTickColorDark = values["majorTickColorDark"]?.colorValue ?? majorTickColorDark
        minorTickColorDark = values["minorTickColorDark"]?.colorValue ?? minorTickColorDark
        fontColorDark = values["fontColorDark"]?.colorValue ?? fontColorDark
        evenSolarTermTickColorDark = values["evenSolarTermTickColorDark"]?.colorValue ?? evenSolarTermTickColorDark
        oddSolarTermTickColorDark = values["oddSolarTermTickColorDark"]?.colorValue ?? oddSolarTermTickColorDark
        if let colourList = readColorList(values["planetIndicator"]), colourList.count == self.planetIndicator.count {
            planetIndicator = colourList
        }
        if let colourList = readColorList(values["sunPositionIndicator"]), colourList.count == self.sunPositionIndicator.count {
            sunPositionIndicator = colourList
        }
        if let colourList = readColorList(values["moonPositionIndicator"]), colourList.count == self.moonPositionIndicator.count {
            moonPositionIndicator = colourList
        }
        eclipseIndicator = values["eclipseIndicator"]?.colorValue ?? eclipseIndicator
        fullmoonIndicator = values["fullmoonIndicator"]?.colorValue ?? fullmoonIndicator
        oddStermIndicator = values["oddStermIndicator"]?.colorValue ?? oddStermIndicator
        evenStermIndicator = values["evenStermIndicator"]?.colorValue ?? evenStermIndicator
        shadeAlpha = values["shadeAlpha"]?.floatValue ?? shadeAlpha
        shadowSize = values["shadowSize"]?.floatValue ?? shadowSize
        centerTextOffset = values["centerTextOffset"]?.floatValue ?? centerTextOffset
        centerTextHOffset = values["centerTextHorizontalOffset"]?.floatValue ?? centerTextHOffset
        verticalTextOffset = values["verticalTextOffset"]?.floatValue ?? verticalTextOffset
        horizontalTextOffset = values["horizontalTextOffset"]?.floatValue ?? horizontalTextOffset
        if updateSize {
            if let width = values["watchWidth"]?.floatValue, let height = values["watchHeight"]?.floatValue {
                watchSize = CGSize(width: width, height: height)
            }
        }
        cornerRadiusRatio = values["cornerRadiusRatio"]?.floatValue ?? cornerRadiusRatio
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
        let defaultName = ThemeData.defaultName
        let predicate = {
            let deviceName = if local {
                try? LocalData.read()?.deviceName ?? ThemeData.deviceName
            } else {
                ThemeData.deviceName
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
    
    func saveDefault(context: ModelContext) {
        let defaultName = ThemeData.defaultName
        let deviceName = ThemeData.deviceName
        try? LocalData.write(deviceName: deviceName)
        
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
            let defaultTheme = ThemeData(name: ThemeData.defaultName, code: self.encode())
            context.insert(defaultTheme)
        }
    }
}
