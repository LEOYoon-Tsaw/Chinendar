//
//  DataStructs.swift
//  Chinendar
//
//  Created by Leo Liu on 4/27/23.
//

import CoreGraphics
import SwiftUI

private let displayP3 = CGColorSpace(name: CGColorSpace.displayP3)!

struct CodableColor: Codable, Equatable {
    var cgColor: CGColor
    var color: Color {
        Color(cgColor: cgColor)
    }

    enum CodingKeys: String, CodingKey {
        case colorSpace
        case components
    }

    enum CodingError: Error {
        case wrongData
    }

    init(cgColor: CGColor) {
        self.cgColor = cgColor
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let colorSpace = try container.decode(String.self, forKey: .colorSpace)
        let components = try container.decode([CGFloat].self, forKey: .components)

        guard let cgColorSpace = CGColorSpace(name: colorSpace as CFString),
              components.count == cgColorSpace.numberOfComponents + 1,
              let cgColor = unsafe CGColor(colorSpace: cgColorSpace, components: components) else {
            throw CodingError.wrongData
        }

        self.cgColor = cgColor
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        guard let colorSpace = cgColor.colorSpace?.name, let components = cgColor.components else {
            throw CodingError.wrongData
        }

        try container.encode(colorSpace as String, forKey: .colorSpace)
        try container.encode(components, forKey: .components)
    }
}

extension CGColor {
    var codableColor: CodableColor {
        CodableColor(cgColor: self)
    }
}

extension Encodable {
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
}

extension Decodable {
    init(fromData data: Data) throws {
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
}

protocol LayoutExpressible: Sendable, Codable, Equatable {
    static var defaultLayout: Self { get }
    init()
}

extension LayoutExpressible {
    static var defaultLayout: Self {
        let filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "layout", ofType: "json")!)
        do {
            let defaultData = try Data(contentsOf: filePath)
            return try .init(fromData: defaultData)
        } catch {
            print(error.localizedDescription)
            return .init()
        }
    }
}

struct CodableGradient: Equatable, Codable {
    private let _locations: [CGFloat]
    private let _colors: [CodableColor]
    let isLoop: Bool

    private enum CodingKeys: String, CodingKey {
        case locations, colors, isLoop
    }

    init(locations: [CGFloat], colors: [CGColor], loop: Bool) {
        guard locations.count == colors.count else {
            fatalError("Gradient locations count does not equal colors count")
        }
        var colorAndLocation = Array(zip(colors, locations))
        colorAndLocation.sort { former, latter in
            former.1 < latter.1
        }
        _locations = colorAndLocation.map { $0.1 }
        _colors = colorAndLocation.map { $0.0.codableColor }
        isLoop = loop
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        _locations = try container.decode(Array<CGFloat>.self, forKey: .locations)
        _colors = try container.decode(Array<CodableColor>.self, forKey: .colors)
        isLoop = try container.decode(Bool.self, forKey: .isLoop)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(_locations, forKey: .locations)
        try container.encode(_colors, forKey: .colors)
        try container.encode(isLoop, forKey: .isLoop)
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
                let newColor = unsafe CGColor(colorSpace: displayP3, components: newComponents)
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
            return (_colors + [_colors[0]]).map { $0.cgColor }
        } else {
            return _colors.map { $0.cgColor }
        }
    }

    func apply(startingAngle: CGFloat) -> SwiftUI.Gradient {
        let colors: [CGColor]
        let locations: [CGFloat]
        if startingAngle >= 0 {
            colors = self.colors.reversed()
            locations = self.locations.map { 1 - $0 }.reversed()
        } else {
            colors = self.colors
            locations = self.locations
        }
        return SwiftUI.Gradient(stops: zip(colors, locations).map { SwiftUI.Gradient.Stop(color: Color(cgColor: $0.0), location: $0.1) })
    }
}

struct ThemedColor: Equatable, Codable {
    var light: CodableColor
    var dark: CodableColor

    func color(inDark: Bool) -> CGColor {
        if inDark {
            dark.cgColor
        } else {
            light.cgColor
        }
    }
}

struct BaseLayout: LayoutExpressible, Equatable, Codable {

    struct Color: Equatable, Codable {
        var firstRing = CodableGradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
        var secondRing = CodableGradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
        var thirdRing = CodableGradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
        var centerFontColor = CodableGradient(locations: [0, 1], colors: [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 1)], loop: false)
        var fontColor = ThemedColor(light: CGColor(gray: 0, alpha: 1).codableColor, dark: CGColor(gray: 0, alpha: 1).codableColor)

        var innerColor = ThemedColor(light: CGColor(gray: 0, alpha: 0).codableColor, dark: CGColor(gray: 0, alpha: 0).codableColor)
        var backColor = ThemedColor(light: CGColor(gray: 1, alpha: 1).codableColor, dark: CGColor(gray: 0, alpha: 1).codableColor)
        var majorTickColor = ThemedColor(light: CGColor(gray: 0, alpha: 0).codableColor, dark: CGColor(gray: 0, alpha: 0).codableColor)
        var minorTickColor = ThemedColor(light: CGColor(gray: 0, alpha: 0).codableColor, dark: CGColor(gray: 0, alpha: 0).codableColor)
        var evenSolarTermTickColor = ThemedColor(light: CGColor(gray: 0, alpha: 1).codableColor, dark: CGColor(gray: 1, alpha: 1).codableColor)
        var oddSolarTermTickColor = ThemedColor(light: CGColor(gray: 0, alpha: 0.7).codableColor, dark: CGColor(gray: 1, alpha: 0.7).codableColor)

        var majorTickAlpha: CGFloat = 0
        var minorTickAlpha: CGFloat = 0.7
        var shadeAlpha: CGFloat = 0
        var shadowSize: CGFloat = 0.03

        var planetIndicator = Planets(moon: CGColor(gray: 0.3, alpha: 1).codableColor, mercury: CGColor(gray: 0.4, alpha: 1).codableColor, venus: CGColor(gray: 0.5, alpha: 1).codableColor, mars: CGColor(gray: 0.6, alpha: 1).codableColor, jupiter: CGColor(gray: 0.7, alpha: 1).codableColor, saturn: CGColor(gray: 0.8, alpha: 1).codableColor)
        var sunPositionIndicator = Solar(midnight: CGColor(gray: 0.3, alpha: 1).codableColor, sunrise: CGColor(gray: 0.4, alpha: 1).codableColor, noon: CGColor(gray: 0.5, alpha: 1).codableColor, sunset: CGColor(gray: 0.6, alpha: 1).codableColor)
        var moonPositionIndicator = Lunar(moonrise: CGColor(gray: 0.4, alpha: 1).codableColor, highMoon: CGColor(gray: 0.5, alpha: 1).codableColor, moonset: CGColor(gray: 0.6, alpha: 1).codableColor)
        var monthlyIndicators = MonthTerm(fullMoon: CGColor(gray: 0.4, alpha: 1).codableColor, newMoon: CGColor(gray: 0.3, alpha: 1).codableColor, oddSolarTerm: CGColor(gray: 0.5, alpha: 1).codableColor, evenSolarTerm: CGColor(gray: 0.6, alpha: 1).codableColor)

        private enum CodingKeys: String, CodingKey {
            case firstRing, secondRing, thirdRing, centerFontColor, fontColor
            case innerColor, backColor, majorTickColor, minorTickColor, evenSolarTermTickColor, oddSolarTermTickColor
            case majorTickAlpha, minorTickAlpha, shadeAlpha, shadowSize
            case planetIndicator, sunPositionIndicator, moonPositionIndicator, monthlyIndicators
        }

        init() {}

        init(from decoder: any Decoder) throws {
            self.init()
            let container = try decoder.container(keyedBy: CodingKeys.self)

            firstRing ?= try container.decodeIfPresent(CodableGradient.self, forKey: .firstRing)
            secondRing ?= try container.decodeIfPresent(CodableGradient.self, forKey: .secondRing)
            thirdRing ?= try container.decodeIfPresent(CodableGradient.self, forKey: .thirdRing)
            centerFontColor ?= try container.decodeIfPresent(CodableGradient.self, forKey: .centerFontColor)
            fontColor ?= try container.decodeIfPresent(ThemedColor.self, forKey: .fontColor)

            innerColor ?= try container.decodeIfPresent(ThemedColor.self, forKey: .innerColor)
            backColor ?= try container.decodeIfPresent(ThemedColor.self, forKey: .backColor)
            majorTickColor ?= try container.decodeIfPresent(ThemedColor.self, forKey: .majorTickColor)
            minorTickColor ?= try container.decodeIfPresent(ThemedColor.self, forKey: .minorTickColor)
            evenSolarTermTickColor ?= try container.decodeIfPresent(ThemedColor.self, forKey: .evenSolarTermTickColor)
            oddSolarTermTickColor ?= try container.decodeIfPresent(ThemedColor.self, forKey: .oddSolarTermTickColor)

            majorTickAlpha ?= try container.decodeIfPresent(CGFloat.self, forKey: .majorTickAlpha)
            minorTickAlpha ?= try container.decodeIfPresent(CGFloat.self, forKey: .minorTickAlpha)
            shadeAlpha ?= try container.decodeIfPresent(CGFloat.self, forKey: .shadeAlpha)
            shadowSize ?= try container.decodeIfPresent(CGFloat.self, forKey: .shadowSize)

            planetIndicator ?= try container.decodeIfPresent(Planets<CodableColor>.self, forKey: .planetIndicator)
            sunPositionIndicator ?= try container.decodeIfPresent(Solar<CodableColor>.self, forKey: .sunPositionIndicator)
            moonPositionIndicator ?= try container.decodeIfPresent(Lunar<CodableColor>.self, forKey: .moonPositionIndicator)
            monthlyIndicators ?= try container.decodeIfPresent(MonthTerm<CodableColor>.self, forKey: .monthlyIndicators)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(firstRing, forKey: .firstRing)
            try container.encode(secondRing, forKey: .secondRing)
            try container.encode(thirdRing, forKey: .thirdRing)
            try container.encode(centerFontColor, forKey: .centerFontColor)
            try container.encode(fontColor, forKey: .fontColor)

            try container.encode(innerColor, forKey: .innerColor)
            try container.encode(backColor, forKey: .backColor)
            try container.encode(majorTickColor, forKey: .majorTickColor)
            try container.encode(minorTickColor, forKey: .minorTickColor)
            try container.encode(evenSolarTermTickColor, forKey: .evenSolarTermTickColor)
            try container.encode(oddSolarTermTickColor, forKey: .oddSolarTermTickColor)

            try container.encode(majorTickAlpha, forKey: .majorTickAlpha)
            try container.encode(minorTickAlpha, forKey: .minorTickAlpha)
            try container.encode(shadeAlpha, forKey: .shadeAlpha)
            try container.encode(shadowSize, forKey: .shadowSize)

            try container.encode(planetIndicator, forKey: .planetIndicator)
            try container.encode(sunPositionIndicator, forKey: .sunPositionIndicator)
            try container.encode(moonPositionIndicator, forKey: .moonPositionIndicator)
            try container.encode(monthlyIndicators, forKey: .monthlyIndicators)
        }
    }

    struct Offset: Equatable, Codable {
        var centerTextOffset: CGSize = .zero
        var textOffset: CGSize = .zero
        var watchSize: CGSize = CGSize(width: 128, height: 168)
        var cornerRadiusRatio: CGFloat = 0.3

        private enum CodingKeys: String, CodingKey {
            case centerTextOffset, textOffset, watchSize, cornerRadiusRatio
        }

        init() {}

        init(from decoder: any Decoder) throws {
            self.init()
            let container = try decoder.container(keyedBy: CodingKeys.self)

            centerTextOffset ?= try container.decodeIfPresent(CGSize.self, forKey: .centerTextOffset)
            textOffset ?= try container.decodeIfPresent(CGSize.self, forKey: .textOffset)
            watchSize ?= try container.decodeIfPresent(CGSize.self, forKey: .watchSize)
            cornerRadiusRatio ?= try container.decodeIfPresent(CGFloat.self, forKey: .cornerRadiusRatio)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(centerTextOffset, forKey: .centerTextOffset)
            try container.encode(textOffset, forKey: .textOffset)
            try container.encode(watchSize, forKey: .watchSize)
            try container.encode(cornerRadiusRatio, forKey: .cornerRadiusRatio)
        }
    }

    struct StartingPhase: Equatable, Codable {
        var zeroRing: CGFloat = 0.0
        var firstRing: CGFloat = 0.0
        var secondRing: CGFloat = 0.0
        var thirdRing: CGFloat = 0.0
        var fourthRing: CGFloat = 0.0

        private enum CodingKeys: String, CodingKey {
            case zeroRing, firstRing, secondRing, thirdRing, fourthRing
        }

        init() {}

        init(from decoder: any Decoder) throws {
            self.init()
            let container = try decoder.container(keyedBy: CodingKeys.self)

            zeroRing ?= try container.decodeIfPresent(CGFloat.self, forKey: .zeroRing)
            firstRing ?= try container.decodeIfPresent(CGFloat.self, forKey: .firstRing)
            secondRing ?= try container.decodeIfPresent(CGFloat.self, forKey: .secondRing)
            thirdRing ?= try container.decodeIfPresent(CGFloat.self, forKey: .thirdRing)
            fourthRing ?= try container.decodeIfPresent(CGFloat.self, forKey: .fourthRing)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(zeroRing, forKey: .zeroRing)
            try container.encode(firstRing, forKey: .firstRing)
            try container.encode(secondRing, forKey: .secondRing)
            try container.encode(thirdRing, forKey: .thirdRing)
            try container.encode(fourthRing, forKey: .fourthRing)
        }
    }

    var initialized = false
    var colors = Color()
    var offsets = Offset()
    var startingPhase = StartingPhase()
    var nativeLanguage = false

    private enum CodingKeys: String, CodingKey {
        case type, colors, offsets, startingPhase, nativeLanguage
    }

    init() {}

    init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard try container.decode(String.self, forKey: .type) == String(describing: Self.self) else {
            throw DecodingError.typeMismatch(Self.self, .init(codingPath: container.codingPath, debugDescription: "Type doesn't match expected"))
        }
        colors = try container.decode(Color.self, forKey: .colors)
        offsets = try container.decode(Offset.self, forKey: .offsets)
        startingPhase = try container.decode(StartingPhase.self, forKey: .startingPhase)
        nativeLanguage ?= try container.decodeIfPresent(Bool.self, forKey: .nativeLanguage)
        initialized = true
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(String(describing: Self.self), forKey: .type)
        try container.encode(colors, forKey: .colors)
        try container.encode(offsets, forKey: .offsets)
        try container.encode(startingPhase, forKey: .startingPhase)
        try container.encode(nativeLanguage, forKey: .nativeLanguage)
    }
}

#if os(macOS) || os(visionOS) || os(iOS)
struct StatusBar: Equatable, Codable {
    enum Separator: String, CaseIterable, Codable {
        case space = " "
        case dot = "・"
        case none = ""
        case comma = "，"

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedCase = try Self(rawValue: container.decode(String.self)) {
                self = decodedCase
            } else {
                self = .space
            }
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.rawValue)
        }
    }

    var date: Bool
    var time: Bool
    var holiday: Int
    var separator = Separator.space

    private enum CodingKeys: String, CodingKey {
        case date, time, holiday, separator
    }

    init(date: Bool, time: Bool, holiday: Int) {
        self.date = date
        self.time = time
        self.holiday = holiday
    }

    init(from decoder: any Decoder) throws {
        self.init(date: false, time: false, holiday: 0)
        let container = try decoder.container(keyedBy: CodingKeys.self)

        date ?= try container.decodeIfPresent(Bool.self, forKey: .date)
        time ?= try container.decodeIfPresent(Bool.self, forKey: .time)
        holiday ?= try container.decodeIfPresent(Int.self, forKey: .holiday)
        separator ?= try container.decodeIfPresent(Separator.self, forKey: .separator)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(date, forKey: .date)
        try container.encode(time, forKey: .time)
        try container.encode(holiday, forKey: .holiday)
        try container.encode(separator, forKey: .separator)
    }
}
#endif

struct CalendarConfigure: Equatable, Codable {
    var initialized = false
    var globalMonth: Bool = false
    var apparentTime: Bool = false
    var largeHour: Bool = false
    var locationEnabled: Bool = true
    var customLocation: GeoLocation?
    var timezone: TimeZone?

    private enum CodingKeys: String, CodingKey {
        case type, globalMonth, apparentTime, largeHour, locationEnabled, customLocation, timezone
    }

    init() {}

    init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard try container.decode(String.self, forKey: .type) == String(describing: Self.self) else {
            throw DecodingError.typeMismatch(Self.self, .init(codingPath: container.codingPath, debugDescription: "Type doesn't match expected"))
        }
        globalMonth = try container.decode(Bool.self, forKey: .globalMonth)
        apparentTime = try container.decode(Bool.self, forKey: .apparentTime)
        largeHour = try container.decode(Bool.self, forKey: .largeHour)
        locationEnabled = try container.decode(Bool.self, forKey: .locationEnabled)
        customLocation = try container.decodeIfPresent(GeoLocation.self, forKey: .customLocation)
        timezone = try container.decodeIfPresent(TimeZone.self, forKey: .timezone)
        initialized = true
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(String(describing: Self.self), forKey: .type)
        try container.encode(globalMonth, forKey: .globalMonth)
        try container.encode(apparentTime, forKey: .apparentTime)
        try container.encode(largeHour, forKey: .largeHour)
        try container.encode(locationEnabled, forKey: .locationEnabled)
        try container.encodeIfPresent(customLocation, forKey: .customLocation)
        try container.encodeIfPresent(timezone, forKey: .timezone)
    }
}

extension CalendarConfigure {
    var effectiveTimezone: TimeZone {
        timezone ?? TimeZone.current
    }

    func location(maxWait duration: Duration = .seconds(1), waitForAuthorization: Bool = true) async -> GeoLocation? {
        if locationEnabled {
            do {
                for try await loc in await LocationManager.shared.locationStream(maxWait: duration, waitForAuthorization: waitForAuthorization) {
                    return loc
                }
            } catch {
                return customLocation
            }
        }
        return customLocation
    }
}

struct Reminder: Codable, Equatable, Identifiable, Hashable, Sendable {

    enum TargetTime: Codable, Equatable, Hashable, Sendable {
        enum EventType: Codable, Equatable, Hashable, Sendable {
            case solarTerm(Int)

            private enum CodingKeys: CodingKey {
              case solarTerm
            }

            private enum SolarTermCodingKeys: CodingKey {
              case index
            }

            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                if container.allKeys.count != 1 {
                    let context = DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Invalid number of keys found, expected one.")
                    throw DecodingError.typeMismatch(EventType.self, context)
                }

                switch container.allKeys.first! {
                case .solarTerm:
                    let nestedContainer = try container.nestedContainer(keyedBy: SolarTermCodingKeys.self, forKey: .solarTerm)
                    self = .solarTerm(try nestedContainer.decode(Int.self, forKey: .index))
                @unknown default:
                    self = .solarTerm(0)
                }
            }

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case let .solarTerm(index):
                    var nestedContainer = container.nestedContainer(keyedBy: SolarTermCodingKeys.self, forKey: .solarTerm)
                    try nestedContainer.encode(index, forKey: .index)
                }
            }
        }

        case chinendar(ChineseCalendar.ChineseDateTime)
        case event(EventType)

        private enum CodingKeys: CodingKey {
            case chinendar, event
        }

        private enum ChinendarCodingKeys: CodingKey {
            case datetime
        }

        private enum EventCodingKeys: CodingKey {
            case eventType
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if container.allKeys.count != 1 {
                let context = DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid number of keys found, expected one.")
                throw DecodingError.typeMismatch(TargetTime.self, context)
            }

            switch container.allKeys.first! {
            case .chinendar:
                let nestedContainer = try container.nestedContainer(keyedBy: ChinendarCodingKeys.self, forKey: .chinendar)
                self = .chinendar(try nestedContainer.decode(ChineseCalendar.ChineseDateTime.self, forKey: .datetime))
            case .event:
                let nestedContainer = try container.nestedContainer(keyedBy: EventCodingKeys.self, forKey: .event)
                self = .event(try nestedContainer.decode(EventType.self, forKey: .eventType))
            @unknown default:
                self = .event(.solarTerm(0))
            }
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .chinendar(datetime):
                var nestedContainer = container.nestedContainer(keyedBy: ChinendarCodingKeys.self, forKey: .chinendar)
                try nestedContainer.encode(datetime, forKey: .datetime)
            case let .event(event):
                var nestedContainer = container.nestedContainer(keyedBy: EventCodingKeys.self, forKey: .event)
                try nestedContainer.encode(event, forKey: .eventType)
            }
        }
    }

    enum RemindTime: Codable, Equatable, Hashable, Sendable {
        case exact
        case timeInDay(Int, ChineseCalendar.ChineseTime)
        case quarterOffset(Int)

        private enum CodingKeys: CodingKey {
            case exact, timeInDay, quarterOffset
        }

        private enum TimeInDayCodingKeys: CodingKey {
            case day, time
        }

        private enum QuarterOffsetCodingKeys: CodingKey {
            case quarter
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if container.allKeys.count != 1 {
                let context = DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Invalid number of keys found, expected one.")
                throw DecodingError.typeMismatch(RemindTime.self, context)
            }

            switch container.allKeys.first! {
            case .exact:
                self = .exact
            case .timeInDay:
                let nestedContainer = try container.nestedContainer(keyedBy: TimeInDayCodingKeys.self, forKey: .timeInDay)
                self = .timeInDay(
                    try nestedContainer.decode(Int.self, forKey: .day),
                    try nestedContainer.decode(ChineseCalendar.ChineseTime.self, forKey: .time)
                )
            case .quarterOffset:
                let nestedContainer = try container.nestedContainer(keyedBy: QuarterOffsetCodingKeys.self, forKey: .quarterOffset)
                self = .quarterOffset(try nestedContainer.decode(Int.self, forKey: .quarter))
            @unknown default:
                self = .exact
            }
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .exact:
                try container.encode(true, forKey: .exact)
            case let .timeInDay(day, time):
                var nestedContainer = container.nestedContainer(keyedBy: TimeInDayCodingKeys.self, forKey: .timeInDay)
                try nestedContainer.encode(day, forKey: .day)
                try nestedContainer.encode(time, forKey: .time)
            case let .quarterOffset(quarter):
                var nestedContainer = container.nestedContainer(keyedBy: QuarterOffsetCodingKeys.self, forKey: .quarterOffset)
                try nestedContainer.encode(quarter, forKey: .quarter)
            }
        }
    }

    var id = UUID()
    var name: String
    var enabled: Bool
    var targetTime: TargetTime
    var remindTime: RemindTime

    private enum CodingKeys: String, CodingKey {
        case id, name, enabled, targetTime, remindTime
    }

    init(name: String, enabled: Bool, targetTime: TargetTime, remindTime: RemindTime) {
        self.name = name
        self.enabled = enabled
        self.targetTime = targetTime
        self.remindTime = remindTime
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        targetTime = try container.decode(TargetTime.self, forKey: .targetTime)
        remindTime = try container.decodeIfPresent(RemindTime.self, forKey: .remindTime) ?? .exact
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(targetTime, forKey: .targetTime)
        try container.encode(remindTime, forKey: .remindTime)
    }
}

extension Reminder {
    func nextEvent(in chineseCalendar: ChineseCalendar) -> Date? {
        var notifyTime: Date?

        switch targetTime {
        case .chinendar(let chineseDateTime):
            notifyTime = chineseCalendar.findNext(chineseDateTime: chineseDateTime)
        case .event(let eventType):
            switch eventType {
            case .solarTerm(let solarTerm):
                let solarTermTime = chineseCalendar.solarTerms[solarTerm].date
                if solarTermTime > .now {
                    notifyTime = solarTermTime
                } else {
                    var nextYearCalendar = chineseCalendar
                    nextYearCalendar.update(time: chineseCalendar.solarTerms[24].date + 1)
                    notifyTime = nextYearCalendar.solarTerms[solarTerm].date
                }
            }
        }
        return notifyTime
    }

    func nextReminder(in chineseCalendar: ChineseCalendar) -> Date? {
        nextReminder(for: nextEvent(in: chineseCalendar), in: chineseCalendar)
    }

    func nextReminder(for eventTime: Date?, in chineseCalendar: ChineseCalendar) -> Date? {
        var notifyTime = eventTime

        switch remindTime {
        case .exact:
            break
        case .quarterOffset(let offset):
            notifyTime = notifyTime.map { $0 + Double(offset) * 864 }
        case .timeInDay(let days, let time):
            if let unwrappedNotifyTime = notifyTime {
                var newCalendar = chineseCalendar
                newCalendar.update(time: unwrappedNotifyTime)
                if days > 0 {
                    for _ in 0..<days {
                        newCalendar.update(time: newCalendar.startOfNextDay + 1)
                    }
                } else if days < 0 {
                    for _ in 0..<(-days) {
                        newCalendar.update(time: newCalendar.startOfDay - 1)
                    }
                }
                notifyTime = newCalendar.find(chineseTime: time)
            }
        }
        return notifyTime
    }
}

struct ReminderList: Codable, Equatable, Sendable {
    var name: String
    var enabled: Bool
    var reminders: [Reminder]

    private enum CodingKeys: String, CodingKey {
        case type, name, enabled, reminders
    }

    init(name: String, enabled: Bool, reminders: [Reminder]) {
        self.name = name
        self.enabled = enabled
        self.reminders = reminders
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard try container.decode(String.self, forKey: .type) == String(describing: Self.self) else {
            throw DecodingError.typeMismatch(Self.self, .init(codingPath: container.codingPath, debugDescription: "Type doesn't match expected"))
        }
        name = try container.decode(String.self, forKey: .name)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        reminders = try container.decode(Array<Reminder>.self, forKey: .reminders)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(String(describing: Self.self), forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(reminders, forKey: .reminders)
    }
}

extension ReminderList {
    static var defaultValue: ReminderList {
        var reminders = [Reminder]()
        for (holiday, holidayName) in ChineseCalendar.holidays {
            let reminder = Reminder(name: Locale.translate(holidayName), enabled: true, targetTime: .chinendar(ChineseCalendar.ChineseDateTime(date: holiday, time: .init())), remindTime: .exact)
            reminders.append(reminder)
        }
        reminders.append(contentsOf: [
            Reminder(name: ChineseCalendar.solarTermName(for: 0)!, enabled: true, targetTime: .event(.solarTerm(0)), remindTime: .timeInDay(0, .init())),
            Reminder(name: ChineseCalendar.solarTermName(for: 3)!, enabled: true, targetTime: .event(.solarTerm(3)), remindTime: .timeInDay(0, .init())),
            Reminder(name: ChineseCalendar.solarTermName(for: 6)!, enabled: true, targetTime: .event(.solarTerm(6)), remindTime: .timeInDay(0, .init())),
            Reminder(name: ChineseCalendar.solarTermName(for: 7)!, enabled: true, targetTime: .event(.solarTerm(7)), remindTime: .timeInDay(0, .init())),
            Reminder(name: ChineseCalendar.solarTermName(for: 9)!, enabled: true, targetTime: .event(.solarTerm(9)), remindTime: .timeInDay(0, .init())),
            Reminder(name: ChineseCalendar.solarTermName(for: 12)!, enabled: true, targetTime: .event(.solarTerm(12)), remindTime: .timeInDay(0, .init())),
            Reminder(name: ChineseCalendar.solarTermName(for: 15)!, enabled: true, targetTime: .event(.solarTerm(15)), remindTime: .timeInDay(0, .init())),
            Reminder(name: ChineseCalendar.solarTermName(for: 18)!, enabled: true, targetTime: .event(.solarTerm(18)), remindTime: .timeInDay(0, .init())),
            Reminder(name: ChineseCalendar.solarTermName(for: 21)!, enabled: true, targetTime: .event(.solarTerm(21)), remindTime: .timeInDay(0, .init()))
        ])
        return ReminderList(name: AppInfo.defaultName, enabled: true, reminders: reminders)
    }
}

struct NextEventStatus: Sendable, Codable {
    static let navigationDuration: TimeInterval = 3600

    let type: NextEventType
    let updateTime: Date
    let step: Int
    let anchorTime: Date?

    var expirationDate: Date { updateTime + Self.navigationDuration }

    func isActive(at time: Date) -> Bool {
        anchorTime != nil && time < expirationDate
    }

    func navigating(forward: Bool, at time: Date) -> Self {
        let active = isActive(at: time)
        return Self(type: type, step: (active ? step : 0) + (forward ? 1 : -1), updateTime: time, anchorTime: active ? anchorTime : time)
    }

    init(type: NextEventType, step: Int, updateTime: Date, anchorTime: Date? = nil) {
        self.type = type
        self.step = step
        self.updateTime = updateTime
        self.anchorTime = anchorTime ?? (step != 0 ? updateTime : nil)
    }
}

struct AsyncLocalModels {
    let chineseCalendar: ChineseCalendar
    let config: CalendarConfigure
    let layout: WatchLayout

    @concurrent
    init(compact: Bool = true, config: CalendarConfigure? = nil, theme: WatchLayout? = nil) async {
        if let theme {
            self.layout = theme
        } else {
            self.layout = await LocalDataModel.shared.getLocalTheme()
        }

        if let config {
            self.config = config
        } else {
            self.config = await LocalDataModel.shared.getLocalConfig()
        }

        let location = await self.config.location(maxWait: .seconds(2), waitForAuthorization: false)
        chineseCalendar = ChineseCalendar(timezone: self.config.effectiveTimezone, location: location, compact: compact, globalMonth: self.config.globalMonth, apparentTime: self.config.apparentTime, largeHour: self.config.largeHour)
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
