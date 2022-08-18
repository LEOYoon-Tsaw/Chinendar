//
//  Layout.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/23/21.
//

import AppKit

extension NSColor {
    var hexCode: String {
        var colorString = "0x"
        colorString += String(format:"%02X", Int(round(self.alphaComponent * 255)))
        let colorWithColorspace = self.usingColorSpace(NSColorSpace.displayP3) ?? self
        colorString += String(format:"%02X", Int(round(colorWithColorspace.blueComponent * 255)))
        colorString += String(format:"%02X", Int(round(colorWithColorspace.greenComponent * 255)))
        colorString += String(format:"%02X", Int(round(colorWithColorspace.redComponent * 255)))
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

extension Array where Element : OptionalType {
    func flattened() -> Array<Element.Wrapped>? {
        var newArray = Array<Element.Wrapped>()
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

extension Date {
    func convertToTimeZone(initTimeZone: TimeZone, timeZone: TimeZone) -> Date {
         let delta = TimeInterval(timeZone.secondsFromGMT(for: self) - initTimeZone.secondsFromGMT(for: self))
         return addingTimeInterval(delta)
    }
}

extension String {
    var floatValue: CGFloat? {
        let string = self.trimmingCharacters(in: .whitespaces)
        guard !string.isEmpty else {
            return nil
        }
        return Double(string).map {CGFloat($0)}
    }
    var boolValue: Bool? {
        guard !self.isEmpty else {
            return nil
        }
        let trimmedString = self.trimmingCharacters(in: .whitespaces).lowercased()
        if ["true", "yes"].contains(trimmedString) {
            return true
        } else if ["false", "no"].contains(trimmedString) {
            return false
        } else {
            return nil
        }
    }
    var colorValue: NSColor? {
        let string = self.trimmingCharacters(in: .whitespaces)
        guard !string.isEmpty else {
            return nil
        }
        var r = 0, g = 0, b = 0, a = 0xff
        if (string.count == 10) {
          // 0xffccbbaa
            let regex = try! NSRegularExpression(pattern: "^0x([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$", options: .caseInsensitive)
            let matches = regex.matches(in: string, options: .init(rawValue: 0), range: NSMakeRange(0, string.endIndex.utf16Offset(in: string)))
            if matches.count == 1 {
                r = Int((string as NSString).substring(with: matches[0].range(at: 4)), radix: 16)!
                g = Int((string as NSString).substring(with: matches[0].range(at: 3)), radix: 16)!
                b = Int((string as NSString).substring(with: matches[0].range(at: 2)), radix: 16)!
                a = Int((string as NSString).substring(with: matches[0].range(at: 1)), radix: 16)!
            } else {
                return nil
            }
        } else if (string.count == 8) {
          // 0xccbbaa
          let regex = try! NSRegularExpression(pattern: "^0x([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$", options: .caseInsensitive)
          let matches = regex.matches(in: string, options: .init(rawValue: 0), range: NSMakeRange(0, string.endIndex.utf16Offset(in: string)))
          if matches.count == 1 {
              r = Int((string as NSString).substring(with: matches[0].range(at: 3)), radix: 16)!
              g = Int((string as NSString).substring(with: matches[0].range(at: 2)), radix: 16)!
              b = Int((string as NSString).substring(with: matches[0].range(at: 1)), radix: 16)!
          } else {
              return nil
          }
        }
        return NSColor(displayP3Red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

class WatchLayout {
    class Gradient {
        private let _locations: [CGFloat]
        private let _colors: [NSColor]
        let isLoop: Bool
        
        init(locations: [CGFloat], colors: [NSColor], loop: Bool) {
            guard locations.count == colors.count else {
                fatalError()
            }
            var colorAndLocation = Array(zip(colors, locations))
            colorAndLocation.sort { former, latter in
                former.1 < latter.1
            }
            self._locations = colorAndLocation.map { $0.1 }
            self._colors = colorAndLocation.map { $0.0 }
            self.isLoop = loop
        }
        
        func interpolate(at: CGFloat) -> NSColor {
            let locations = self.locations
            let colors = self.colors
            let nextIndex = locations.firstIndex { $0 >= at }
            if let nextIndex = nextIndex {
                let previousIndex = nextIndex.advanced(by: -1)
                if previousIndex >= locations.startIndex {
                    let leftColor = colors[previousIndex]
                    let rightColor = colors[nextIndex]
                    let ratio = (at - locations[previousIndex]) / (locations[nextIndex] - locations[previousIndex])
                    guard ratio <= 1 && ratio >= 0 else { fatalError() }
                    let components = [leftColor.redComponent * (1-ratio) + rightColor.redComponent * ratio,
                                      leftColor.greenComponent * (1-ratio) + rightColor.greenComponent * ratio,
                                      leftColor.blueComponent * (1-ratio) + rightColor.blueComponent * ratio,
                                      leftColor.alphaComponent * (1-ratio) + rightColor.alphaComponent * ratio]
                    let newColor = NSColor(colorSpace: leftColor.colorSpace, components: components, count: 4)
                    return newColor
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
        var colors: [NSColor] {
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
            let regex = try! NSRegularExpression(pattern: "([a-z_0-9]+)\\s*:[\\s\"]*([^\\s\"#][^\"#]*)[\\s\"#]*(#*.*)$", options: .caseInsensitive)
            var values = Dictionary<String, String>()
            for line in str.split(whereSeparator: \.isNewline) {
                let line = String(line)
                let matches = regex.matches(in: line, options: .init(rawValue: 0), range: NSMakeRange(0, line.endIndex.utf16Offset(in: line)))
                for match in matches {
                    values[(line as NSString).substring(with: match.range(at: 1))] = (line as NSString).substring(with: match.range(at: 2))
                }
            }
            guard let newLocations = values["locations"]?.split(separator: ","), let newColors = values["colors"]?.split(separator: ","), let isLoop = values["loop"]?.boolValue else { return nil }
            let locations = Array(newLocations).map { $0.trimmingCharacters(in: .whitespaces).floatValue }
            let colors = Array(newColors).map { $0.trimmingCharacters(in: .whitespaces).colorValue }
            guard let loc = locations.flattened(), let col = colors.flattened() else { return nil }
            self._locations = loc
            self._colors = col
            self.isLoop = isLoop
        }

    }
    var firstRing: Gradient
    var secondRing: Gradient
    var thirdRing: Gradient
    var innerColor: NSColor
    var majorTickColor: NSColor
    var minorTickColor: NSColor
    var majorTickAlpha: CGFloat
    var minorTickAlpha: CGFloat
    var fontColor: NSColor
    var centerFontColor: Gradient
    var evenSolarTermTickColor: NSColor
    var oddSolarTermTickColor: NSColor
    var innerColorDark: NSColor
    var majorTickColorDark: NSColor
    var minorTickColorDark: NSColor
    var fontColorDark: NSColor
    var evenSolarTermTickColorDark: NSColor
    var oddSolarTermTickColorDark: NSColor
    var planetIndicator: [NSColor]
    var sunPositionIndicator: [NSColor]
    var moonPositionIndicator: [NSColor]
    var eclipseIndicator: NSColor
    var fullmoonIndicator: NSColor
    var oddStermIndicator: NSColor
    var evenStermIndicator: NSColor
    var shadeAlpha: CGFloat
    var backAlpha: CGFloat
    var textFont: NSFont
    var centerFont: NSFont
    var centerTextOffset: CGFloat
    var verticalTextOffset: CGFloat
    var horizontalTextOffset: CGFloat
    var watchSize: NSSize
    var cornerRadiusRatio: CGFloat
    init() {
        let firstRingStart = NSColor(displayP3Red: 178/255, green: 93/255, blue: 141/255, alpha: 1.0)
        let firstRingEnd = NSColor(displayP3Red: 204/255, green: 75/255, blue: 89/255, alpha: 1.0)
        firstRing = Gradient(locations: [0, 0.5], colors: [firstRingStart, firstRingEnd], loop: true)
        
        let secondRingStart = NSColor(displayP3Red: 205/255, green: 74/255, blue: 94/255, alpha: 1.0)
        let secondRingEnd = NSColor(displayP3Red: 179/255, green: 98/255, blue: 89/255, alpha: 1.0)
        secondRing = Gradient(locations: [0, 0.5], colors: [secondRingStart, secondRingEnd], loop: true)
        
        let thirdRingStart = NSColor(displayP3Red: 147/255, green: 102/255, blue: 203/255, alpha: 1.0)
        let thirdRingEnd = NSColor(displayP3Red: 180/255, green: 94/255, blue: 119/255, alpha: 1.0)
        thirdRing = Gradient(locations: [0, 0.5], colors: [thirdRingStart, thirdRingEnd], loop: true)
        
        let centerFontColorStart = NSColor(displayP3Red: 243/255, green: 230/255, blue: 233/255, alpha: 1.0)
        let centerFontColorEnd = NSColor(displayP3Red: 219/255, green: 213/255, blue: 236/255, alpha: 1.0)
        centerFontColor = Gradient(locations: [0, 1], colors: [centerFontColorStart, centerFontColorEnd], loop: false)
        
        innerColor = NSColor(displayP3Red: 143/255, green: 115/255, blue: 140/255, alpha: 0.5)
        innerColorDark = NSColor(displayP3Red: 143/255, green: 115/255, blue: 140/255, alpha: 0.5)
        majorTickColor = NSColor.black
        majorTickColorDark = NSColor.black
        majorTickAlpha = 1
        minorTickColor = NSColor(displayP3Red: 22/255, green: 22/255, blue: 22/255, alpha: 1.0)
        minorTickColorDark = NSColor(displayP3Red: 22/255, green: 22/255, blue: 22/255, alpha: 1.0)
        minorTickAlpha = 1
        fontColor = NSColor.white
        fontColorDark = NSColor.white
        evenSolarTermTickColor = NSColor.black
        oddSolarTermTickColor = NSColor(displayP3Red: 102/255, green: 102/255, blue: 102/255, alpha: 1.0)
        evenSolarTermTickColorDark = NSColor.white
        oddSolarTermTickColorDark = NSColor(displayP3Red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
        planetIndicator = [NSColor(displayP3Red: 10/255, green: 30/255, blue: 60/255, alpha: 1.0), //Mercury
                           NSColor(displayP3Red: 200/255, green: 190/255, blue: 170/255, alpha: 1.0), //Venus
                           NSColor(displayP3Red: 210/255, green: 48/255, blue: 40/255, alpha: 1.0), //Mars
                           NSColor(displayP3Red: 60/255, green: 180/255, blue: 90/255, alpha: 1.0), //Jupyter
                           NSColor(displayP3Red: 170/255, green: 150/255, blue: 50/255, alpha: 1.0), //Saturn
                           NSColor(displayP3Red: 220/255, green: 200/255, blue: 60/255, alpha: 1.0)] //Moon
        sunPositionIndicator = [NSColor(displayP3Red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0), //Mid Night
                                NSColor(displayP3Red: 255/255, green: 80/255, blue: 10/255, alpha: 1.0), //Sunrise
                                NSColor(displayP3Red: 210/255, green: 170/255, blue: 120/255, alpha: 1.0), //Noon
                                NSColor(displayP3Red: 230/255, green: 120/255, blue: 30/255, alpha: 1.0)] //Sunset
        moonPositionIndicator = [NSColor(displayP3Red: 190/255, green: 210/255, blue: 30/255, alpha: 1.0), //Moon rise
                                 NSColor(displayP3Red: 255/255, green: 255/255, blue: 50/255, alpha: 1.0), //Moon at meridian
                                 NSColor(displayP3Red: 120/255, green: 30/255, blue: 150/255, alpha: 1.0)] //Moon set
        eclipseIndicator = NSColor(displayP3Red: 50/255, green: 68/255, blue: 96/255, alpha: 1.0)
        fullmoonIndicator = NSColor(displayP3Red: 255/255, green: 239/255, blue: 59/255, alpha: 1.0)
        oddStermIndicator = NSColor(displayP3Red: 153/255, green: 153/255, blue: 153/255, alpha:1.0)
        evenStermIndicator = NSColor.white
        shadeAlpha = 0.2
        backAlpha = 0.5
        textFont = NSFont.userFont(ofSize: NSFont.systemFontSize)!
        centerFont = NSFontManager.shared.font(withFamily: NSFont.userFont(ofSize: NSFont.systemFontSize)!.familyName!, traits: .boldFontMask, weight: 900, size: NSFont.systemFontSize)!
        centerTextOffset = -0.1
        verticalTextOffset = 0.3
        horizontalTextOffset = 0.01
        watchSize = NSMakeSize(396, 484)
        cornerRadiusRatio = 0.3
    }
    
    func encode() -> String {
        var encoded = ""
        encoded += "globalMonth: \(ChineseCalendar.globalMonth)\n"
        encoded += "backAlpha: \(backAlpha)\n"
        encoded += "firstRing: \(firstRing.encode().replacingOccurrences(of: "\n", with: "; "))\n"
        encoded += "secondRing: \(secondRing.encode().replacingOccurrences(of: "\n", with: "; "))\n"
        encoded += "thirdRing: \(thirdRing.encode().replacingOccurrences(of: "\n", with: "; "))\n"
        encoded += "innerColor: \(innerColor.hexCode)\n"
        encoded += "majorTickColor: \(majorTickColor.hexCode)\n"
        encoded += "majorTickAlpha: \(majorTickAlpha)\n"
        encoded += "minorTickColor: \(minorTickColor.hexCode)\n"
        encoded += "minorTickAlpha: \(minorTickAlpha)\n"
        encoded += "fontColor: \(fontColor.hexCode)\n"
        encoded += "centerFontColor: \(centerFontColor.encode().replacingOccurrences(of: "\n", with: "; "))\n"
        encoded += "evenSolarTermTickColor: \(evenSolarTermTickColor.hexCode)\n"
        encoded += "oddSolarTermTickColor: \(oddSolarTermTickColor.hexCode)\n"
        encoded += "innerColorDark: \(innerColorDark.hexCode)\n"
        encoded += "majorTickColorDark: \(majorTickColorDark.hexCode)\n"
        encoded += "minorTickColorDark: \(minorTickColorDark.hexCode)\n"
        encoded += "fontColorDark: \(fontColorDark.hexCode)\n"
        encoded += "evenSolarTermTickColorDark: \(evenSolarTermTickColorDark.hexCode)\n"
        encoded += "oddSolarTermTickColorDark: \(oddSolarTermTickColorDark.hexCode)\n"
        encoded += "planetIndicator: \(planetIndicator.map {$0.hexCode}.joined(separator: ", "))\n"
        encoded += "eclipseIndicator: \(eclipseIndicator.hexCode)\n"
        encoded += "fullmoonIndicator: \(fullmoonIndicator.hexCode)\n"
        encoded += "oddStermIndicator: \(oddStermIndicator.hexCode)\n"
        encoded += "evenStermIndicator: \(evenStermIndicator.hexCode)\n"
        encoded += "sunPositionIndicator: \(sunPositionIndicator.map {$0.hexCode}.joined(separator: ", "))\n"
        encoded += "moonPositionIndicator: \(moonPositionIndicator.map {$0.hexCode}.joined(separator: ", "))\n"
        encoded += "shadeAlpha: \(shadeAlpha)\n"
        encoded += "textFont: \(textFont.fontName)\n"
        encoded += "centerFont: \(centerFont.fontName)\n"
        encoded += "centerTextOffset: \(centerTextOffset)\n"
        encoded += "verticalTextOffset: \(verticalTextOffset)\n"
        encoded += "horizontalTextOffset: \(horizontalTextOffset)\n"
        encoded += "watchWidth: \(watchSize.width)\n"
        encoded += "watchHeight: \(watchSize.height)\n"
        encoded += "cornerRadiusRatio: \(cornerRadiusRatio)\n"
        
        return encoded
    }
    
    func update(from str: String) {
        let regex = try! NSRegularExpression(pattern: "^([a-z_0-9]+)\\s*:[\\s\"]*([^\\s\"#][^\"#]*)[\\s\"#]*(#*.*)$", options: .caseInsensitive)
        var values = Dictionary<String, String>()
        for line in str.split(whereSeparator: \.isNewline) {
            let line = String(line)
            let matches = regex.matches(in: line, options: .init(rawValue: 0), range: NSMakeRange(0, line.endIndex.utf16Offset(in: line)))
            for match in matches {
                values[(line as NSString).substring(with: match.range(at: 1))] = (line as NSString).substring(with: match.range(at: 2))
            }
        }
        
        let seperatorRegex = try! NSRegularExpression(pattern: "(\\s*;|\\{\\})", options: .caseInsensitive)
        func readGradient(value: String?) -> Gradient? {
            guard let value = value else { return nil }
            let mutableValue = NSMutableString(string: value)
            seperatorRegex.replaceMatches(in: mutableValue, options: .init(rawValue: 0), range: NSMakeRange(0, mutableValue.length), withTemplate: "\n")
            return Gradient(from: mutableValue as String)
        }
        
        func readColorList(_ list: String?) -> [NSColor]? {
            var colors = [NSColor?]()
            if let colorValues = list {
                for color in colorValues.split(separator: ",") {
                    colors.append(String(color).colorValue)
                }
                return colors.flattened()
            } else {
                return nil
            }
        }
        
        ChineseCalendar.globalMonth = values["globalMonth"]?.boolValue ?? ChineseCalendar.globalMonth
        backAlpha = values["backAlpha"]?.floatValue ?? backAlpha
        firstRing = readGradient(value: values["firstRing"]) ?? firstRing
        secondRing = readGradient(value: values["secondRing"]) ?? secondRing
        thirdRing = readGradient(value: values["thirdRing"]) ?? thirdRing
        innerColor = values["innerColor"]?.colorValue ?? innerColor
        majorTickColor = values["majorTickColor"]?.colorValue ?? majorTickColor
        majorTickAlpha = values["majorTickAlpha"]?.floatValue ?? majorTickAlpha
        minorTickColor = values["minorTickColor"]?.colorValue ?? minorTickColor
        minorTickAlpha = values["minorTickAlpha"]?.floatValue ?? minorTickAlpha
        fontColor = values["fontColor"]?.colorValue ?? fontColor
        centerFontColor = readGradient(value: values["centerFontColor"]) ?? centerFontColor
        evenSolarTermTickColor = values["evenSolarTermTickColor"]?.colorValue ?? evenSolarTermTickColor
        oddSolarTermTickColor = values["oddSolarTermTickColor"]?.colorValue ?? oddSolarTermTickColor
        innerColorDark = values["innerColorDark"]?.colorValue ?? innerColor
        majorTickColorDark = values["majorTickColorDark"]?.colorValue ?? majorTickColor
        minorTickColorDark = values["minorTickColorDark"]?.colorValue ?? minorTickColor
        fontColorDark = values["fontColorDark"]?.colorValue ?? fontColor
        evenSolarTermTickColorDark = values["evenSolarTermTickColorDark"]?.colorValue ?? evenSolarTermTickColorDark
        oddSolarTermTickColorDark = values["oddSolarTermTickColorDark"]?.colorValue ?? oddSolarTermTickColorDark
        if let colourList = readColorList(values["planetIndicator"]), colourList.count == self.planetIndicator.count {
            self.planetIndicator = colourList
        }
        if let colourList = readColorList(values["sunPositionIndicator"]), colourList.count == self.sunPositionIndicator.count {
            self.sunPositionIndicator = colourList
        }
        if let colourList = readColorList(values["moonPositionIndicator"]), colourList.count == self.moonPositionIndicator.count {
            self.moonPositionIndicator = colourList
        }
        eclipseIndicator = values["eclipseIndicator"]?.colorValue ?? eclipseIndicator
        fullmoonIndicator = values["fullmoonIndicator"]?.colorValue ?? fullmoonIndicator
        oddStermIndicator = values["oddStermIndicator"]?.colorValue ?? oddStermIndicator
        evenStermIndicator = values["evenStermIndicator"]?.colorValue ?? evenStermIndicator
        shadeAlpha = values["shadeAlpha"]?.floatValue ?? shadeAlpha
        if let name = values["textFont"] {
            textFont = NSFont(name: name, size: NSFont.systemFontSize) ?? textFont
        }
        if let name = values["centerFont"] {
            centerFont = NSFont(name: name, size: NSFont.systemFontSize) ?? centerFont
        }
        centerTextOffset = values["centerTextOffset"]?.floatValue ?? centerTextOffset
        verticalTextOffset = values["verticalTextOffset"]?.floatValue ?? verticalTextOffset
        horizontalTextOffset = values["horizontalTextOffset"]?.floatValue ?? horizontalTextOffset
        if let width = values["watchWidth"]?.floatValue, let height = values["watchHeight"]?.floatValue {
            watchSize = NSMakeSize(width, height)
        }
        cornerRadiusRatio = values["cornerRadiusRatio"]?.floatValue ?? cornerRadiusRatio
    }
    
    convenience init(from str: String) {
        self.init()
        update(from: str)
    }
}

class ColorWell: NSColorWell {
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        NSColorPanel.shared.showsAlpha = true
        super.mouseDown(with: event)
    }
    override func resignFirstResponder() -> Bool {
        NSColorPanel.shared.close()
        return super.resignFirstResponder()
    }
}

class ConfigurationViewController: NSViewController, NSWindowDelegate {
    static var currentInstance: ConfigurationViewController? = nil
    @IBOutlet weak var globalMonthToggle: NSSwitch!
    @IBOutlet weak var datetimePicker: NSDatePicker!
    @IBOutlet weak var currentTimeToggle: NSButton!
    @IBOutlet weak var timezonePicker: NSPopUpButton!
    @IBOutlet weak var latitudeDegreePicker: NSTextField!
    @IBOutlet weak var latitudeMinutePicker: NSTextField!
    @IBOutlet weak var latitudeSecondPicker: NSTextField!
    @IBOutlet weak var latitudeSpherePicker: NSSegmentedControl!
    @IBOutlet weak var longitudeDegreePicker: NSTextField!
    @IBOutlet weak var longitudeMinutePicker: NSTextField!
    @IBOutlet weak var longitudeSecondPicker: NSTextField!
    @IBOutlet weak var longitudeSpherePicker: NSSegmentedControl!
    @IBOutlet weak var currentLocationToggle: NSButton!
    @IBOutlet weak var firstRingGradientPicker: GradientSlider!
    @IBOutlet weak var secondRingGradientPicker: GradientSlider!
    @IBOutlet weak var thirdRingGradientPicker: GradientSlider!
    @IBOutlet weak var shadeAlphaValuePicker: NSSlider!
    @IBOutlet weak var shadeAlphaValueLabel: NSTextField!
    @IBOutlet weak var firstRingIsLoop: NSButton!
    @IBOutlet weak var secondRingIsLoop: NSButton!
    @IBOutlet weak var thirdRingIsLoop: NSButton!
    @IBOutlet weak var innerTextGradientPicker: GradientSlider!
    @IBOutlet weak var backAlphaValuePicker: NSSlider!
    @IBOutlet weak var backAlphaValueLabel: NSTextField!
    @IBOutlet weak var minorTickAlphaValuePicker: NSSlider!
    @IBOutlet weak var minorTickAlphaValueLabel: NSTextField!
    @IBOutlet weak var majorTickAlphaValuePicker: NSSlider!
    @IBOutlet weak var majorTickAlphaValueLabel: NSTextField!
    @IBOutlet weak var innerColorPicker: NSColorWell!
    @IBOutlet weak var majorTickColorPicker: NSColorWell!
    @IBOutlet weak var minorTickColorPicker: NSColorWell!
    @IBOutlet weak var textColorPicker: NSColorWell!
    @IBOutlet weak var oddStermTickColorPicker: NSColorWell!
    @IBOutlet weak var evenStermTickColorPicker: NSColorWell!
    @IBOutlet weak var innerColorPickerDark: NSColorWell!
    @IBOutlet weak var majorTickColorPickerDark: NSColorWell!
    @IBOutlet weak var minorTickColorPickerDark: NSColorWell!
    @IBOutlet weak var textColorPickerDark: NSColorWell!
    @IBOutlet weak var oddStermTickColorPickerDark: NSColorWell!
    @IBOutlet weak var evenStermTickColorPickerDark: NSColorWell!
    @IBOutlet weak var mercuryIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var venusIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var marsIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var jupyterIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var saturnIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var moonIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var eclipseIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var fullmoonIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var oddStermIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var evenStermIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var sunriseIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var sunsetIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var noonIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var midnightIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var moonriseIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var moonsetIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var moonmeridianIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var textFontFamilyPicker: NSPopUpButton!
    @IBOutlet weak var textFontTraitPicker: NSPopUpButton!
    @IBOutlet weak var centerTextFontFamilyPicker: NSPopUpButton!
    @IBOutlet weak var centerTextFontTraitPicker: NSPopUpButton!
    @IBOutlet weak var widthPicker: NSTextField!
    @IBOutlet weak var heightPicker: NSTextField!
    @IBOutlet weak var cornerRadiusRatioPicker: NSTextField!
    @IBOutlet weak var centerTextOffsetPicker: NSTextField!
    @IBOutlet weak var textHorizontalOffsetPicker: NSTextField!
    @IBOutlet weak var textVerticalOffsetPicker: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var revertButton: NSButton!
    @IBOutlet weak var applyButton: NSButton!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var contentView: NSView!
    var panelTimezone = TimeZone.init(secondsFromGMT: 0)!
    
    func scrollToTop() {
        let maxHeight = max(scrollView.bounds.height, contentView.bounds.height)
        contentView.scroll(NSPoint(x: 0, y: maxHeight))
    }
    func toggle(button: NSButton, with bool: Bool) {
        if bool {
            button.state = .on
        } else {
            button.state = .off
        }
    }
    func readToggle(button: NSButton) -> Bool {
        return button.state == .on
    }
    func populateFontMember(_ picker: NSPopUpButton, inFamily familyPicker: NSPopUpButton) {
        picker.removeAllItems()
        if let family = familyPicker.titleOfSelectedItem {
            let members = NSFontManager.shared.availableMembers(ofFontFamily: family)
            for member in members ?? [[Any]]() {
                if let fontType = member[1] as? String {
                    picker.addItem(withTitle: fontType)
                }
            }
        }
        picker.selectItem(at: 0)
    }
    func populateFontFamilies(_ picker: NSPopUpButton) {
        picker.removeAllItems()
        picker.addItem(withTitle: NSFont.systemFont(ofSize: NSFont.systemFontSize).familyName!)
        picker.addItems(withTitles: NSFontManager.shared.availableFontFamilies)
    }
    func clearFontMember(_ picker: NSPopUpButton) {
        picker.removeAllItems()
    }
    func readFont(family: NSPopUpButton, style: NSPopUpButton) -> NSFont? {
        let size = NSFont.systemFontSize
        let fontFamily: String = family.titleOfSelectedItem!
        let fontTraits: String = style.titleOfSelectedItem!
        if let font = NSFont(name: "\(fontFamily.filter {!$0.isWhitespace})-\(fontTraits.filter {!$0.isWhitespace})", size: size) {
            return font
        }
        let members = NSFontManager.shared.availableMembers(ofFontFamily: fontFamily) ?? [[Any]]()
        for i in 0..<members.count {
            if let memberName = members[i][1] as? String, memberName == fontTraits,
                let weight = members[i][2] as? Int,
                let traits = members[i][3] as? UInt {
                return NSFontManager.shared.font(withFamily: fontFamily, traits: NSFontTraitMask(rawValue: traits), weight: weight, size: size)
            }
        }
        if let font = NSFont(name: fontFamily, size: size) {
            return font
        }
        return nil
    }
    
    @IBAction func currentTimeToggled(_ sender: Any) {
        view.window?.makeFirstResponder(datetimePicker)
        datetimePicker.isEnabled = !readToggle(button: currentTimeToggle)
        if !datetimePicker.isEnabled {
            timezonePicker.selectItem(withTitle: Calendar.current.timeZone.identifier)
        }
    }
    @IBAction func currentLocationToggled(_ sender: Any) {
        if readToggle(button: currentLocationToggle) {
            if ChineseTime.locManager?.authorizationStatus == .authorized || ChineseTime.locManager?.authorizationStatus == .authorizedAlways {
                longitudeSpherePicker.isEnabled = false
                longitudeDegreePicker.isEnabled = false
                longitudeMinutePicker.isEnabled = false
                longitudeSecondPicker.isEnabled = false
                latitudeSpherePicker.isEnabled = false
                latitudeDegreePicker.isEnabled = false
                latitudeMinutePicker.isEnabled = false
                latitudeSecondPicker.isEnabled = false
                ChineseTime.locManager!.startUpdatingLocation()
            } else if ChineseTime.locManager?.authorizationStatus == .notDetermined || ChineseTime.locManager?.authorizationStatus == .restricted {
                ChineseTime.locManager!.requestWhenInUseAuthorization()
                currentLocationToggle.state = .off
            } else {
                currentLocationToggle.state = .off
                let alert = NSAlert()
                alert.messageText = "定位未開"
                alert.informativeText = "若需獲取所在地經緯度，請打開定位服務"
                alert.runModal()
            }
        } else {
            longitudeSpherePicker.isEnabled = true
            longitudeDegreePicker.isEnabled = true
            longitudeMinutePicker.isEnabled = true
            longitudeSecondPicker.isEnabled = true
            latitudeSpherePicker.isEnabled = true
            latitudeDegreePicker.isEnabled = true
            latitudeMinutePicker.isEnabled = true
            latitudeSecondPicker.isEnabled = true
        }
    }
    @IBAction func timezoneChanged(_ sender: Any) {
        view.window?.makeFirstResponder(timezonePicker)
        if let title = timezonePicker.titleOfSelectedItem {
            let newTimezone = TimeZone(identifier: title)!
            datetimePicker.dateValue = datetimePicker.dateValue.convertToTimeZone(initTimeZone: panelTimezone, timeZone: newTimezone)
            panelTimezone = newTimezone
        }
    }
    @IBAction func firstRingIsLoopToggled(_ sender: Any) {
        view.window?.makeFirstResponder(firstRingIsLoop)
        firstRingGradientPicker.isLoop = readToggle(button: firstRingIsLoop)
        firstRingGradientPicker.updateGradient()
    }
    @IBAction func secondRingIsLoopToggled(_ sender: Any) {
        view.window?.makeFirstResponder(secondRingIsLoop)
        secondRingGradientPicker.isLoop = readToggle(button: secondRingIsLoop)
        secondRingGradientPicker.updateGradient()
    }
    @IBAction func thirdRingIsLoopToggled(_ sender: Any) {
        view.window?.makeFirstResponder(thirdRingIsLoop)
        thirdRingGradientPicker.isLoop = readToggle(button: thirdRingIsLoop)
        thirdRingGradientPicker.updateGradient()
    }
    @IBAction func shadeAlphaPickerChanged(_ sender: Any) {
        view.window?.makeFirstResponder(shadeAlphaValuePicker)
        shadeAlphaValueLabel.stringValue = String(format: "%1.2f", shadeAlphaValuePicker.doubleValue)
    }
    @IBAction func backAlphaPickerChanged(_ sender: Any) {
        view.window?.makeFirstResponder(backAlphaValuePicker)
        backAlphaValueLabel.stringValue = String(format: "%1.2f", backAlphaValuePicker.doubleValue)
    }
    @IBAction func minorTickAlphaPickerChanged(_ sender: Any) {
        view.window?.makeFirstResponder(minorTickAlphaValuePicker)
        minorTickAlphaValueLabel.stringValue = String(format: "%1.2f", minorTickAlphaValuePicker.doubleValue)
    }
    @IBAction func majorTickAlphaPickerChanged(_ sender: Any) {
        view.window?.makeFirstResponder(majorTickAlphaValuePicker)
        majorTickAlphaValueLabel.stringValue = String(format: "%1.2f", majorTickAlphaValuePicker.doubleValue)
    }
    @IBAction func textFontFamilyChange(_ sender: Any) {
        view.window?.makeFirstResponder(textFontFamilyPicker)
        populateFontMember(textFontTraitPicker, inFamily: textFontFamilyPicker)
    }
    @IBAction func centerTextFontFamilyChange(_ sender: Any) {
        view.window?.makeFirstResponder(centerTextFontFamilyPicker)
        populateFontMember(centerTextFontTraitPicker, inFamily: centerTextFontFamilyPicker)
    }
    @IBAction func cancel(_ sender: Any) {
        self.view.window?.close()
    }
    @IBAction func revert(_ sender: Any) {
        view.window?.makeFirstResponder(revertButton)
        if let watchFace = WatchFace.currentInstance, let temp = WatchFaceView.layoutTemplate {
            watchFace._view.watchLayout.update(from: temp)
            watchFace.updateSize(with: watchFace.frame)
            watchFace._view.drawView()
            updateUI()
        }
    }
    @IBAction func apply(_ sender: Any) {
        updateData()
        if let watchFace = WatchFace.currentInstance {
            watchFace.invalidateShadow()
            watchFace.updateSize(with: watchFace.frame)
            watchFace._view.drawView()
        }
        updateUI()
    }
    @IBAction func ok(_ sender: Any) {
        apply(sender)
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else { return }
        WatchFaceView.layoutTemplate = delegate.saveLayout()
        self.view.window?.close()
    }
    
    func populateTimezonePicker(timezone: TimeZone?) {
        timezonePicker.removeAllItems()
        timezonePicker.addItems(withTitles: TimeZone.knownTimeZoneIdentifiers)
        if let timezone = timezone {
            timezonePicker.selectItem(withTitle: timezone.identifier)
            panelTimezone = timezone
        } else {
            let currentTimezone = Calendar.current.timeZone
            timezonePicker.selectItem(withTitle: currentTimezone.identifier)
            panelTimezone = currentTimezone
        }
    }
    
    func updateData() {
        let watchView = WatchFace.currentInstance!._view
        let watchLayout = watchView.watchLayout
        ChineseCalendar.globalMonth = globalMonthToggle.state == .on
        if readToggle(button: currentTimeToggle) {
            watchView.displayTime = nil
        } else {
            let selectedDate = datetimePicker.dateValue.convertToTimeZone(initTimeZone: panelTimezone, timeZone: Calendar.current.timeZone)
            let secondDiff = Calendar.current.component(.second, from: selectedDate)
            watchView.displayTime = selectedDate.advanced(by: -Double(secondDiff))
        }
        if let title = timezonePicker.titleOfSelectedItem {
            watchView.timezone = TimeZone(identifier: title)!
        }
        var latitude = latitudeDegreePicker.doubleValue
        latitude += latitudeMinutePicker.doubleValue / 60
        latitude += latitudeSecondPicker.doubleValue / 3600
        latitude *= latitudeSpherePicker.selectedSegment == 0 ? 1 : -1
        watchView.location.x = latitude
        
        var longitude = longitudeDegreePicker.doubleValue
        longitude += longitudeMinutePicker.doubleValue / 60
        longitude += longitudeSecondPicker.doubleValue / 3600
        longitude *= longitudeSpherePicker.selectedSegment == 0 ? 1 : -1
        watchView.location.y = longitude
        
        watchLayout.firstRing = firstRingGradientPicker.gradient
        watchLayout.secondRing = secondRingGradientPicker.gradient
        watchLayout.thirdRing = thirdRingGradientPicker.gradient
        watchLayout.shadeAlpha = shadeAlphaValuePicker.doubleValue
        watchLayout.centerFontColor = innerTextGradientPicker.gradient
        watchLayout.backAlpha = backAlphaValuePicker.doubleValue
        watchLayout.innerColor = innerColorPicker.color
        watchLayout.majorTickColor = majorTickColorPicker.color
        watchLayout.minorTickColor = minorTickColorPicker.color
        watchLayout.minorTickAlpha = minorTickAlphaValueLabel.doubleValue
        watchLayout.majorTickAlpha = majorTickAlphaValueLabel.doubleValue
        watchLayout.fontColor = textColorPicker.color
        watchLayout.oddSolarTermTickColor = oddStermTickColorPicker.color
        watchLayout.evenSolarTermTickColor = evenStermTickColorPicker.color
        watchLayout.innerColorDark = innerColorPickerDark.color
        watchLayout.majorTickColorDark = majorTickColorPickerDark.color
        watchLayout.minorTickColorDark = minorTickColorPickerDark.color
        watchLayout.fontColorDark = textColorPickerDark.color
        watchLayout.oddSolarTermTickColorDark = oddStermTickColorPickerDark.color
        watchLayout.evenSolarTermTickColorDark = evenStermTickColorPickerDark.color
        watchLayout.planetIndicator = [
            mercuryIndicatorColorPicker.color,
            venusIndicatorColorPicker.color,
            marsIndicatorColorPicker.color,
            jupyterIndicatorColorPicker.color,
            saturnIndicatorColorPicker.color,
            moonIndicatorColorPicker.color
        ]
        watchLayout.eclipseIndicator = eclipseIndicatorColorPicker.color
        watchLayout.fullmoonIndicator = fullmoonIndicatorColorPicker.color
        watchLayout.oddStermIndicator = oddStermIndicatorColorPicker.color
        watchLayout.evenStermIndicator = evenStermIndicatorColorPicker.color
        watchLayout.sunPositionIndicator = [
            midnightIndicatorColorPicker.color,
            sunriseIndicatorColorPicker.color,
            noonIndicatorColorPicker.color,
            sunsetIndicatorColorPicker.color
        ]
        watchLayout.moonPositionIndicator = [
            moonriseIndicatorColorPicker.color,
            moonmeridianIndicatorColorPicker.color,
            moonsetIndicatorColorPicker.color
        ]
        watchLayout.textFont = readFont(family: textFontFamilyPicker, style: textFontTraitPicker) ?? watchLayout.textFont
        watchLayout.centerFont = readFont(family: centerTextFontFamilyPicker, style: centerTextFontTraitPicker) ?? watchLayout.centerFont
        watchLayout.watchSize = NSMakeSize(max(0, widthPicker.doubleValue), max(0, heightPicker.doubleValue))
        watchLayout.cornerRadiusRatio = max(0, min(1, cornerRadiusRatioPicker.doubleValue))
        watchLayout.centerTextOffset = centerTextOffsetPicker.doubleValue
        watchLayout.horizontalTextOffset = textHorizontalOffsetPicker.doubleValue
        watchLayout.verticalTextOffset = textVerticalOffsetPicker.doubleValue
    }
    
    func updateUI() {
        let watchView = WatchFace.currentInstance!._view
        let watchLayout = watchView.watchLayout
        globalMonthToggle.state = ChineseCalendar.globalMonth ? .on : .off
        populateTimezonePicker(timezone: watchView.timezone)
        if let time = watchView.displayTime {
            datetimePicker.dateValue = time.convertToTimeZone(initTimeZone: Calendar.current.timeZone, timeZone: panelTimezone)
            datetimePicker.isEnabled = true
            currentTimeToggle.state = .off
        } else {
            datetimePicker.dateValue = Date().convertToTimeZone(initTimeZone: Calendar.current.timeZone, timeZone: panelTimezone)
            datetimePicker.isEnabled = false
            currentTimeToggle.state = .on
        }
        var latitude = watchView.location.x
        latitudeSpherePicker.selectSegment(withTag: latitude >= 0 ? 0 : 1)
        latitude = abs(latitude)
        latitudeDegreePicker.doubleValue = floor(latitude)
        latitude = (latitude - floor(latitude)) * 60
        latitudeMinutePicker.doubleValue = floor(latitude)
        latitude = (latitude - floor(latitude)) * 60
        latitudeSecondPicker.doubleValue = latitude
        
        var longitude = watchView.location.y
        longitudeSpherePicker.selectSegment(withTag: longitude >= 0 ? 0 : 1)
        longitude = abs(longitude)
        longitudeDegreePicker.doubleValue = floor(longitude)
        longitude = (longitude - floor(longitude)) * 60
        longitudeMinutePicker.doubleValue = floor(longitude)
        longitude = (longitude - floor(longitude)) * 60
        longitudeSecondPicker.doubleValue = longitude

        firstRingGradientPicker.gradient = watchLayout.firstRing
        secondRingGradientPicker.gradient = watchLayout.secondRing
        thirdRingGradientPicker.gradient = watchLayout.thirdRing
        toggle(button: firstRingIsLoop, with: watchLayout.firstRing.isLoop)
        toggle(button: secondRingIsLoop, with: watchLayout.secondRing.isLoop)
        toggle(button: thirdRingIsLoop, with: watchLayout.thirdRing.isLoop)
        shadeAlphaValuePicker.doubleValue = Double(watchLayout.shadeAlpha)
        shadeAlphaValueLabel.stringValue = String(format: "%1.2f", watchLayout.shadeAlpha)
        innerTextGradientPicker.gradient = watchLayout.centerFontColor
        backAlphaValuePicker.doubleValue = Double(watchLayout.backAlpha)
        backAlphaValueLabel.stringValue = String(format: "%1.2f", watchLayout.backAlpha)
        innerColorPicker.color = watchLayout.innerColor
        majorTickColorPicker.color = watchLayout.majorTickColor
        minorTickColorPicker.color = watchLayout.minorTickColor
        minorTickAlphaValuePicker.doubleValue = Double(watchLayout.minorTickAlpha)
        minorTickAlphaValueLabel.stringValue = String(format: "%1.2f", watchLayout.minorTickAlpha)
        majorTickAlphaValuePicker.doubleValue = Double(watchLayout.majorTickAlpha)
        majorTickAlphaValueLabel.stringValue = String(format: "%1.2f", watchLayout.majorTickAlpha)
        textColorPicker.color = watchLayout.fontColor
        oddStermTickColorPicker.color = watchLayout.oddSolarTermTickColor
        evenStermTickColorPicker.color = watchLayout.evenSolarTermTickColor
        innerColorPickerDark.color = watchLayout.innerColorDark
        majorTickColorPickerDark.color = watchLayout.majorTickColorDark
        minorTickColorPickerDark.color = watchLayout.minorTickColorDark
        textColorPickerDark.color = watchLayout.fontColorDark
        oddStermTickColorPickerDark.color = watchLayout.oddSolarTermTickColorDark
        evenStermTickColorPickerDark.color = watchLayout.evenSolarTermTickColorDark
        mercuryIndicatorColorPicker.color = watchLayout.planetIndicator[0]
        venusIndicatorColorPicker.color = watchLayout.planetIndicator[1]
        marsIndicatorColorPicker.color = watchLayout.planetIndicator[2]
        jupyterIndicatorColorPicker.color = watchLayout.planetIndicator[3]
        saturnIndicatorColorPicker.color = watchLayout.planetIndicator[4]
        moonIndicatorColorPicker.color = watchLayout.planetIndicator[5]
        eclipseIndicatorColorPicker.color = watchLayout.eclipseIndicator
        fullmoonIndicatorColorPicker.color = watchLayout.fullmoonIndicator
        oddStermIndicatorColorPicker.color = watchLayout.oddStermIndicator
        evenStermIndicatorColorPicker.color = watchLayout.evenStermIndicator
        midnightIndicatorColorPicker.color = watchLayout.sunPositionIndicator[0]
        sunriseIndicatorColorPicker.color = watchLayout.sunPositionIndicator[1]
        noonIndicatorColorPicker.color = watchLayout.sunPositionIndicator[2]
        sunsetIndicatorColorPicker.color = watchLayout.sunPositionIndicator[3]
        moonriseIndicatorColorPicker.color = watchLayout.moonPositionIndicator[0]
        moonmeridianIndicatorColorPicker.color = watchLayout.moonPositionIndicator[1]
        moonsetIndicatorColorPicker.color = watchLayout.moonPositionIndicator[2]
        populateFontFamilies(textFontFamilyPicker)
        textFontFamilyPicker.selectItem(withTitle: watchLayout.textFont.familyName!)
        populateFontMember(textFontTraitPicker, inFamily: textFontFamilyPicker)
        if let traits = watchLayout.textFont.fontName.split(separator: "-").last {
            textFontTraitPicker.selectItem(withTitle: String(traits))
            if textFontTraitPicker.selectedItem == nil {
                textFontTraitPicker.selectItem(at: 0)
            }
        }
        populateFontFamilies(centerTextFontFamilyPicker)
        centerTextFontFamilyPicker.selectItem(withTitle: watchLayout.centerFont.familyName!)
        populateFontMember(centerTextFontTraitPicker, inFamily: centerTextFontFamilyPicker)
        if let traits = watchLayout.centerFont.fontName.split(separator: "-").last {
            centerTextFontTraitPicker.selectItem(withTitle: String(traits))
            if centerTextFontTraitPicker.selectedItem == nil {
                centerTextFontTraitPicker.selectItem(at: 0)
            }
        }
        widthPicker.stringValue = "\(watchLayout.watchSize.width)"
        heightPicker.stringValue = "\(watchLayout.watchSize.height)"
        cornerRadiusRatioPicker.stringValue = "\(watchLayout.cornerRadiusRatio)"
        centerTextOffsetPicker.stringValue = "\(watchLayout.centerTextOffset)"
        textHorizontalOffsetPicker.stringValue = "\(watchLayout.horizontalTextOffset)"
        textVerticalOffsetPicker.stringValue = "\(watchLayout.verticalTextOffset)"
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.delegate = self
        if ChineseTime.locManager?.authorizationStatus == .authorized || ChineseTime.locManager?.authorizationStatus == .authorizedAlways {
            currentLocationToggle.state = .on
        } else {
            currentLocationToggle.state = .off
        }
        currentLocationToggled(currentLocationToggle!)
        if let window = self.view.window, let watchFace = WatchFace.currentInstance {
            let screen = watchFace.getCurrentScreen()
            if watchFace.frame.maxX + 10 + window.frame.width < screen.maxX {
                window.setFrameOrigin(NSMakePoint(watchFace.frame.maxX + 10, watchFace.frame.midY - window.frame.height / 2))
            } else {
                window.setFrameOrigin(NSMakePoint(max(watchFace.frame.minX - 10 - window.frame.width, screen.minX), watchFace.frame.midY - window.frame.height / 2))
            }
        }
    }

    
    override func viewDidLoad() {
        Self.currentInstance = self
        super.viewDidLoad()
        updateUI()
        scrollToTop()
    }
    
    override func viewDidDisappear() {
        Self.currentInstance = nil
        NSColorPanel.shared.showsAlpha = false
        NSColorPanel.shared.setTarget(nil)
        NSColorPanel.shared.setAction(nil)
        NSColorPanel.shared.close()
    }
}

@IBDesignable
class GradientSlider: NSControl, NSColorChanging {
    let minimumValue: CGFloat = 0
    let maximumValue: CGFloat = 1
    var values: [CGFloat] = [0, 1]
    var colors: [NSColor] = [.black, .white]
    private var controls = [CAShapeLayer]()
    private var controlsLayer = CALayer()
    
    var isLoop = false
    private let trackLayer = CAGradientLayer()
    private var previousLocation: CGPoint? = nil
    private var movingControl: CAShapeLayer? = nil
    private var movingIndex: Int? = nil
    private var controlRadius: CGFloat = 0
    private var dragging = false
    
    var gradient: WatchLayout.Gradient {
        get {
            return WatchLayout.Gradient(locations: values, colors: colors, loop: isLoop)
        } set {
            if newValue.isLoop {
                values = newValue.locations.dropLast()
                colors = newValue.colors.dropLast()
            } else {
                values = newValue.locations
                colors = newValue.colors
            }
            isLoop = newValue.isLoop
            updateLayerFrames()
            initializeControls()
            updateGradient()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        layer?.addSublayer(trackLayer)
        layer?.addSublayer(controlsLayer)
        updateLayerFrames()
        initializeControls()
        updateGradient()
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
            changeChontrols()
        }
    }
    
    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }

    private func addControl(at value: CGFloat, color: NSColor) {
        let control = CAShapeLayer()
        control.path = CGPath(ellipseIn: NSRect(origin: thumbOriginForValue(value), size: NSMakeSize(controlRadius * 2, controlRadius * 2)), transform: nil)
        control.fillColor = color.cgColor
        control.shadowPath = control.path
        control.shadowOpacity = 0.3
        control.shadowRadius = 1.5
        control.shadowOffset = NSMakeSize(0, -1)
        control.lineWidth = 2.0
        controls.append(control)
        controlsLayer.addSublayer(control)
    }
    
    private func initializeControls() {
        controlsLayer.sublayers = []
        controls = []
        for i in 0..<values.count {
            addControl(at: values[i], color: colors[i])
        }
    }
    
    private func changeChontrols() {
        for i in 0..<controls.count {
            controls[i].path = CGPath(ellipseIn: NSRect(origin: thumbOriginForValue(values[i]), size: NSMakeSize(controlRadius * 2, controlRadius * 2)), transform: nil)
            controls[i].shadowPath = controls[i].path
        }
    }
    
    private func updateLayerFrames() {
        trackLayer.frame = bounds.insetBy(dx: bounds.height / 2, dy: bounds.height / 3)
        let mask = CAShapeLayer()
        let maskShape = RoundedRect(rect: trackLayer.bounds, nodePos: bounds.height / 6, ankorPos: bounds.height / 6 * 0.2).path
        mask.path = maskShape
        trackLayer.mask = mask
        controlRadius = bounds.height / 3
        trackLayer.startPoint = NSMakePoint(0, 0)
        trackLayer.endPoint = NSMakePoint(1, 0)
    }
    
    func updateGradient() {
        let gradient = self.gradient
        trackLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
        trackLayer.colors = gradient.colors.map { $0.cgColor }
    }
    
    private func moveControl() {
        if let movingControl = movingControl, let movingIndex = movingIndex {
            movingControl.path = CGPath(ellipseIn: NSRect(origin: thumbOriginForValue(values[movingIndex]), size: NSMakeSize(controlRadius * 2, controlRadius * 2)), transform: nil)
            movingControl.shadowPath = movingControl.path
            updateGradient()
        }
    }

    func positionForValue(_ value: CGFloat) -> CGFloat {
        return trackLayer.frame.width * value
    }

    private func thumbOriginForValue(_ value: CGFloat) -> CGPoint {
        let x = positionForValue(value) - controlRadius
        return CGPoint(x: trackLayer.frame.minX + x, y: bounds.height / 2 - controlRadius)
    }
    
    override func resignFirstResponder() -> Bool {
        movingControl?.strokeColor = nil
        movingControl = nil
        movingIndex = nil
        previousLocation = nil
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        previousLocation = event.locationInWindow
        previousLocation = self.convert(previousLocation!, from: window?.contentView)
        var hit = false
        var i = 0
        for control in controls {
            if control.path!.contains(previousLocation!) {
                movingControl?.strokeColor = nil
                movingControl = control
                movingControl!.strokeColor = NSColor.controlAccentColor.cgColor
                movingIndex = i
                hit = true
            }
            i += 1
        }
        if !hit {
            var newValue = (previousLocation!.x - trackLayer.frame.minX) / trackLayer.frame.width
            newValue = min(max(newValue, minimumValue), maximumValue)
            let color = self.gradient.interpolate(at: newValue)
            values.append(newValue)
            colors.append(color)
            addControl(at: newValue, color: color)
            movingIndex = values.count - 1
            movingControl?.strokeColor = nil
            movingControl = controls.last!
            movingControl!.strokeColor = NSColor.controlAccentColor.cgColor
        }
    }
    override func mouseDragged(with event: NSEvent) {
        dragging = true
        if (movingIndex != nil) && (previousLocation != nil) && (movingIndex! < values.count) {
            var location = event.locationInWindow
            location = self.convert(location, from: window?.contentView)
            let deltaLocation = location.x - previousLocation!.x
            let deltaValue = (maximumValue - minimumValue) * deltaLocation / trackLayer.frame.width
            previousLocation = location
            // Change value
            values[movingIndex!] += deltaValue
            values[movingIndex!] = min(max(values[movingIndex!], minimumValue), maximumValue)
            moveControl()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if !dragging && movingControl != nil && movingIndex != nil {
            NSColorPanel.shared.showsAlpha = true
            let colorPicker = NSColorPanel.shared
            if let currentColor = movingControl?.fillColor {
                colorPicker.color = NSColor(cgColor: currentColor)!
                colorPicker.orderFront(self)
                colorPicker.setTarget(self)
                colorPicker.setAction(#selector(changeColor(_:)))
            }
        }
        dragging = false
        previousLocation = nil
    }
    
    override func keyUp(with event: NSEvent) {
        if event.keyCode == 51 && movingControl != nil && movingIndex != nil && values.count > 2 && colors.count > 2 {
            movingControl?.strokeColor = nil
            movingControl!.removeFromSuperlayer()
            controls.remove(at: movingIndex!)
            values.remove(at: movingIndex!)
            colors.remove(at: movingIndex!)
            movingControl = nil
            movingIndex = nil
            NSColorPanel.shared.close()
            updateGradient()
        }
    }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 51 && movingControl != nil && movingIndex != nil && values.count > 2 && colors.count > 2 {
            return true
        } else {
            return false
        }
    }
    
    @objc func changeColor(_ sender: NSColorPanel?) {
        if movingControl != nil && movingIndex != nil && sender != nil {
            movingControl!.fillColor = sender!.color.cgColor
            colors[movingIndex!] = sender!.color
            updateGradient()
        }
    }
    
}
