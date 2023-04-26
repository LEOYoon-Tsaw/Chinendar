//
//  Layout.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/23/21.
//

import UIKit

let displayP3 = CGColorSpace(name: CGColorSpace.displayP3)!

extension CGColor {
    var hexCode: String {
        var colorString = "0x"
        let colorWithColorspace = self.converted(to: displayP3, intent: .defaultIntent, options: nil) ?? self
        colorString += String(format:"%02X", Int(round(colorWithColorspace.components![3] * 255)))
        colorString += String(format:"%02X", Int(round(colorWithColorspace.components![2] * 255)))
        colorString += String(format:"%02X", Int(round(colorWithColorspace.components![1] * 255)))
        colorString += String(format:"%02X", Int(round(colorWithColorspace.components![0] * 255)))
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
    var colorValue: CGColor? {
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
        return CGColor(colorSpace: displayP3, components: [CGFloat(r) / 255, CGFloat(g) / 255, CGFloat(b) / 255, CGFloat(a) / 255])
    }
}

class WatchLayout {
    class Gradient {
        private let _locations: [CGFloat]
        private let _colors: [CGColor]
        let isLoop: Bool
        
        init(locations: [CGFloat], colors: [CGColor], loop: Bool) {
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
        
        func interpolate(at: CGFloat) -> CGColor {
            let locations = self.locations
            let colors = self.colors
            let nextIndex = locations.firstIndex { $0 >= at }
            if let nextIndex = nextIndex {
                let previousIndex = nextIndex.advanced(by: -1)
                if previousIndex >= locations.startIndex {
                    let leftColor = UIColor(cgColor: colors[previousIndex])
                    let rightColor = UIColor(cgColor: colors[nextIndex])
                    let ratio = (at - locations[previousIndex]) / (locations[nextIndex] - locations[previousIndex])
                    guard ratio <= 1 && ratio >= 0 else { fatalError() }
                    var leftRed: CGFloat = 0.0; var leftGreen: CGFloat = 0.0; var leftBlue: CGFloat = 0.0; var leftAlpha: CGFloat = 0.0
                    leftColor.getRed(&leftRed, green: &leftGreen, blue: &leftBlue, alpha: &leftAlpha)
                    var rightRed: CGFloat = 0.0; var rightGreen: CGFloat = 0.0; var rightBlue: CGFloat = 0.0; var rightAlpha: CGFloat = 0.0
                    rightColor.getRed(&rightRed, green: &rightGreen, blue: &rightBlue, alpha: &rightAlpha)
                    let newColor = UIColor(displayP3Red: leftRed * (1-ratio) + rightRed * ratio,
                                           green: leftGreen * (1-ratio) + rightGreen * ratio,
                                           blue: leftBlue * (1-ratio) + rightBlue * ratio,
                                           alpha: leftAlpha * (1-ratio) + rightAlpha * ratio).cgColor
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
    var innerColor: CGColor
    var majorTickColor: CGColor
    var minorTickColor: CGColor
    var majorTickAlpha: CGFloat
    var minorTickAlpha: CGFloat
    var fontColor: CGColor
    var centerFontColor: Gradient
    var evenSolarTermTickColor: CGColor
    var oddSolarTermTickColor: CGColor
    var innerColorDark: CGColor
    var majorTickColorDark: CGColor
    var minorTickColorDark: CGColor
    var fontColorDark: CGColor
    var evenSolarTermTickColorDark: CGColor
    var oddSolarTermTickColorDark: CGColor
    var planetIndicator: [CGColor]
    var sunPositionIndicator: [CGColor]
    var moonPositionIndicator: [CGColor]
    var eclipseIndicator: CGColor
    var fullmoonIndicator: CGColor
    var oddStermIndicator: CGColor
    var evenStermIndicator: CGColor
    var shadeAlpha: CGFloat
    var backAlpha: CGFloat
    var textFont: UIFont
    var centerFont: UIFont
    var centerTextOffset: CGFloat
    var verticalTextOffset: CGFloat
    var horizontalTextOffset: CGFloat
    var watchSize: CGSize
    var cornerRadiusRatio: CGFloat
    init() {
        let firstRingStart = CGColor(colorSpace: displayP3, components: [178.0/255.0, 93.0/255.0, 141.0/255.0, 1.0])!
        let firstRingEnd = CGColor(colorSpace: displayP3, components: [204.0/255.0, 75/255.0, 89.0/255.0, 1.0])!
        firstRing = Gradient(locations: [0, 0.5], colors: [firstRingStart, firstRingEnd], loop: true)
        
        let secondRingStart = CGColor(colorSpace: displayP3, components: [205.0/255.0, 74.0/255.0, 94.0/255.0, 1.0])!
        let secondRingEnd = CGColor(colorSpace: displayP3, components: [179.0/255.0, 98.0/255.0, 89.0/255.0, 1.0])!
        secondRing = Gradient(locations: [0, 0.5], colors: [secondRingStart, secondRingEnd], loop: true)
        
        let thirdRingStart = CGColor(colorSpace: displayP3, components: [147.0/255.0, 102.0/255.0, 203.0/255.0, 1.0])!
        let thirdRingEnd = CGColor(colorSpace: displayP3, components: [180.0/255.0, 94.0/255.0, 119.0/255.0, 1.0])!
        thirdRing = Gradient(locations: [0, 0.5], colors: [thirdRingStart, thirdRingEnd], loop: true)
        
        let centerFontColorStart = CGColor(colorSpace: displayP3, components: [243.0/255.0, 230.0/255.0, 233.0/255.0, 1.0])!
        let centerFontColorEnd = CGColor(colorSpace: displayP3, components: [219.0/255.0, 213.0/255.0, 236.0/255.0, 1.0])!
        centerFontColor = Gradient(locations: [0, 1], colors: [centerFontColorStart, centerFontColorEnd], loop: false)
        
        innerColor = CGColor(colorSpace: displayP3, components: [143.0/255.0, 115.0/255.0, 140.0/255.0, 0.5])!
        innerColorDark = CGColor(colorSpace: displayP3, components: [143.0/255.0, 115.0/255.0, 140.0/255.0, 0.5])!
        majorTickColor = CGColor(gray: 0.0, alpha: 1.0)
        majorTickColorDark = CGColor(gray: 0.0, alpha: 1.0)
        majorTickAlpha = 1
        minorTickColor = CGColor(colorSpace: displayP3, components: [22.0/255.0, 22.0/255.0, 22.0/255.0, 1.0])!
        minorTickColorDark = CGColor(colorSpace: displayP3, components: [22.0/255.0, 22.0/255.0, 22.0/255.0, 1.0])!
        minorTickAlpha = 1
        fontColor = CGColor(gray: 1.0, alpha: 1.0)
        fontColorDark = CGColor(gray: 1.0, alpha: 1.0)
        evenSolarTermTickColor = CGColor(gray: 0.0, alpha: 1.0)
        oddSolarTermTickColor = CGColor(colorSpace: displayP3, components: [102.0/255.0, 102.0/255.0, 102.0/255.0, 1.0])!
        evenSolarTermTickColorDark = CGColor(gray: 1.0, alpha: 1.0)
        oddSolarTermTickColorDark = CGColor(colorSpace: displayP3, components: [153.0/255.0, 153.0/255.0, 153.0/255.0, 1.0])!
        planetIndicator = [CGColor(colorSpace: displayP3, components: [10.0/255.0, 30.0/255.0, 60.0/255.0, 1.0])!, //Mercury
                           CGColor(colorSpace: displayP3, components: [200.0/255.0, 190.0/255.0, 170.0/255.0, 1.0])!, //Venus
                           CGColor(colorSpace: displayP3, components: [210.0/255.0, 48.0/255.0, 40.0/255.0, 1.0])!, //Mars
                           CGColor(colorSpace: displayP3, components: [60.0/255.0, 180.0/255.0, 90.0/255.0, 1.0])!, //Jupyter
                           CGColor(colorSpace: displayP3, components: [170.0/255.0, 150.0/255.0, 50.0/255.0, 1.0])!, //Saturn
                           CGColor(colorSpace: displayP3, components: [220.0/255.0, 200.0/255.0, 60.0/255.0, 1.0])!] //Moon
        sunPositionIndicator = [CGColor(colorSpace: displayP3, components: [0/255.0, 0/255.0, 0/255.0, 1.0])!, //Mid Night
                                CGColor(colorSpace: displayP3, components: [255.0/255.0, 80.0/255.0, 10.0/255.0, 1.0])!, //Sunrise
                                CGColor(colorSpace: displayP3, components: [210.0/255.0, 170.0/255.0, 120.0/255.0, 1.0])!, //Noon
                                CGColor(colorSpace: displayP3, components: [230.0/255.0, 120.0/255.0, 30.0/255.0, 1.0])!] //Sunset
        moonPositionIndicator = [CGColor(colorSpace: displayP3, components: [190.0/255.0, 210.0/255.0, 30.0/255.0, 1.0])!, //Moon rise
                                 CGColor(colorSpace: displayP3, components: [255.0/255.0, 255.0/255.0, 50.0/255.0, 1.0])!, //Moon at meridian
                                 CGColor(colorSpace: displayP3, components: [120.0/255.0, 30.0/255.0, 150.0/255.0, 1.0])!] //Moon set
        eclipseIndicator = CGColor(colorSpace: displayP3, components: [50.0/255.0, 68.0/255.0, 96.0/255.0, 1.0])!
        fullmoonIndicator = CGColor(colorSpace: displayP3, components: [255.0/255.0, 239.0/255.0, 59.0/255.0, 1.0])!
        oddStermIndicator = CGColor(colorSpace: displayP3, components: [153.0/255.0, 153.0/255.0, 153.0/255.0, 1.0])!

        evenStermIndicator = CGColor(gray: 1.0, alpha: 1.0)
        shadeAlpha = 0.2
        backAlpha = 0.5
        textFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        centerFont = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)
        centerTextOffset = -0.1
        verticalTextOffset = 0.3
        horizontalTextOffset = 0.01
        watchSize = CGSize(width: 396, height: 484)
        cornerRadiusRatio = 0.3
    }
    
    func encode() -> String {
        var encoded = ""
        encoded += "globalMonth: \(ChineseCalendar.globalMonth)\n"
        encoded += "apparentTime: \(ChineseCalendar.apparentTime)\n"
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
        
        ChineseCalendar.globalMonth = values["globalMonth"]?.boolValue ?? ChineseCalendar.globalMonth
        ChineseCalendar.apparentTime = values["apparentTime"]?.boolValue ?? ChineseCalendar.apparentTime
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
            textFont = UIFont(name: name, size: UIFont.systemFontSize) ?? textFont
        }
        if let name = values["centerFont"] {
            centerFont = UIFont(name: name, size: UIFont.systemFontSize) ?? centerFont
        }
        centerTextOffset = values["centerTextOffset"]?.floatValue ?? centerTextOffset
        verticalTextOffset = values["verticalTextOffset"]?.floatValue ?? verticalTextOffset
        horizontalTextOffset = values["horizontalTextOffset"]?.floatValue ?? horizontalTextOffset
        if let width = values["watchWidth"]?.floatValue, let height = values["watchHeight"]?.floatValue {
            watchSize = CGSize(width: width, height: height)
        }
        cornerRadiusRatio = values["cornerRadiusRatio"]?.floatValue ?? cornerRadiusRatio
    }
    
    convenience init(from str: String) {
        self.init()
        update(from: str)
    }
}

class ColorWell: UIColorWell {
    var index: Int!
    
    @objc func dragged(_ sender: UIPanGestureRecognizer) {
        guard let slider = self.superview as? GradientSlider else { return }
        let translation = sender.translation(in: slider)
        self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: slider)
        if sender.state == .ended {
            if slider.bounds.contains(self.center) || slider.controls.count == 1 {
                self.frame = CGRect(x: frame.origin.x, y: (slider.bounds.height - frame.height) / 2, width: frame.width, height: frame.height)
                slider.values[index] = (center.x - slider.bounds.origin.x) / (slider.bounds.width - slider.controlRadius * 2)
            } else {
                self.removeFromSuperview()
                slider.removeControl(at: index)
                UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
            }
            slider.updateGradient()
        }
    }
    
    @objc func colorWellChanged(_ sender: Any) {
        guard let slider = self.superview as? GradientSlider else { return }
        if let color = self.selectedColor {
            slider.colors[index] = color
            slider.updateGradient()
        }
    }
}

class GradientSlider: UIControl, UIGestureRecognizerDelegate {
    let minimumValue: CGFloat = 0
    let maximumValue: CGFloat = 1
    var values: [CGFloat] = [0, 1]
    var colors: [UIColor] = [.black, .white]
    internal var controls = [ColorWell]()
    
    var isLoop = false
    private let trackLayer = CAGradientLayer()
    private var previousLocation: CGPoint? = nil
    internal var controlRadius: CGFloat = 0
    private var dragging = false
    
    var gradient: WatchLayout.Gradient {
        get {
            return WatchLayout.Gradient(locations: values, colors: colors.map{$0.cgColor}, loop: isLoop)
        } set {
            if newValue.isLoop {
                values = newValue.locations.dropLast()
                colors = newValue.colors.dropLast().map { UIColor(cgColor: $0) }
            } else {
                values = newValue.locations
                colors = newValue.colors.map { UIColor(cgColor: $0) }
            }
            isLoop = newValue.isLoop
            updateLayerFrames()
            initializeControls()
            updateGradient()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(trackLayer)
        updateLayerFrames()
        initializeControls()
        updateGradient()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self) {
            let ratio = (location.x - bounds.origin.x - controlRadius) / (bounds.width - controlRadius * 2)
            let color = UIColor(cgColor: self.gradient.interpolate(at: ratio))
            addControl(at: ratio, color: color)
            values.append(ratio)
            colors.append(color)
            UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
        }
        super.touchesBegan(touches, with: event)
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
            changeChontrols()
        }
    }

    private func addControl(at value: CGFloat, color: UIColor) {
        let control = ColorWell()
        control.frame = CGRect(origin: thumbOriginForValue(value), size: CGSize(width: controlRadius * 2, height: controlRadius * 2))
        control.selectedColor = color
        let panGesture = UIPanGestureRecognizer(target: control, action: #selector(ColorWell.dragged(_:)))
        control.isUserInteractionEnabled = true
        control.addGestureRecognizer(panGesture)
        control.addTarget(control, action: #selector(ColorWell.colorWellChanged(_:)), for: .allEvents)
        controls.append(control)
        control.index = controls.count - 1
        self.addSubview(control)
    }
    
    private func initializeControls() {
        for control in controls.reversed() {
            control.removeFromSuperview()
        }
        controls = []
        for i in 0..<values.count {
            addControl(at: values[i], color: colors[i])
        }
    }
    
    func removeControl(at index: Int) {
        colors.remove(at: index)
        values.remove(at: index)
        controls.remove(at: index)
        for i in index..<controls.count {
            controls[i].index = i
        }
    }
    
    private func changeChontrols() {
        for i in 0..<controls.count {
            controls[i].frame = CGRect(origin: thumbOriginForValue(values[i]), size: CGSize(width: controlRadius * 2, height: controlRadius * 2))
        }
    }
    
    private func updateLayerFrames() {
        trackLayer.frame = bounds.insetBy(dx: bounds.height / 2, dy: bounds.height / 3)
        let mask = CAShapeLayer()
        let maskShape = RoundedRect(rect: trackLayer.bounds, nodePos: bounds.height / 6, ankorPos: bounds.height / 6 * 0.2).path
        mask.path = maskShape
        trackLayer.mask = mask
        controlRadius = bounds.height / 3
        trackLayer.startPoint = CGPoint(x: 0, y: 0)
        trackLayer.endPoint = CGPoint(x: 1, y: 0)
    }
    
    func updateGradient() {
        let gradient = self.gradient
        trackLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
        trackLayer.colors = gradient.colors
    }

    func positionForValue(_ value: CGFloat) -> CGFloat {
        return trackLayer.frame.width * value
    }

    private func thumbOriginForValue(_ value: CGFloat) -> CGPoint {
        let x = positionForValue(value) - controlRadius
        return CGPoint(x: trackLayer.frame.minX + x, y: bounds.height / 2 - controlRadius)
    }
}
