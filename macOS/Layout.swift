//
//  Layout.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/23/21.
//

import SwiftUI
import Observation

@Observable final class WatchLayout: MetaWatchLayout {
    static var shared = WatchLayout()
    
    struct StatusBar: Equatable {
        
        enum Separator: String, CaseIterable {
            case space, dot, none
            var symbol: String {
                switch self {
                case .space: " "
                case .dot: "・"
                case .none: ""
                }
            }
        }
        
        var date: Bool
        var time: Bool
        var holiday: Int
        var separator: Separator
        
        func encode() -> String {
            "date: \(date.description), time: \(time.description), holiday: \(holiday.description), separator: \(separator.rawValue)"
        }
        
        init(date: Bool = true, time: Bool = true, holiday: Int = 0, separator: Separator = .space) {
            self.date = date
            self.time = time
            self.holiday = holiday
            self.separator = separator
        }
        
        init?(from str: String?) {
            guard let str = str else { return nil }
            let regex = /([a-zA-Z_0-9]+)\s*:[\s"]*([^\s"#][^"#]*)[\s"#]*(#*.*)$/
            var values = [String: String]()
            for line in str.split(separator: ",") {
                if let match = try? regex.firstMatch(in: String(line))?.output {
                    values[String(match.1)] = String(match.2)
                }
            }
            guard let date = values["date"]?.boolValue, let time = values["time"]?.boolValue, let holiday = values["holiday"]?.intValue, let separator = values["separator"] else { return nil }
            self.date = date
            self.time = time
            self.holiday = max(0, min(2, holiday))
            self.separator = Separator(rawValue: separator) ?? .space
        }
    }

    var textFont: NSFont = NSFont.userFont(ofSize: NSFont.systemFontSize)!
    var centerFont: NSFont = NSFontManager.shared.font(withFamily: NSFont.userFont(ofSize: NSFont.systemFontSize)!.familyName!,
                                                       traits: .boldFontMask, weight: 900, size: NSFont.systemFontSize)!
    var statusBar = StatusBar()
    
    private override init() {
        super.init()
    }

    override func encode(includeOffset: Bool = true, includeColor: Bool = true, includeConfig: Bool = true) -> String {
        var encoded = super.encode(includeOffset: includeOffset, includeColor: includeColor, includeConfig: includeConfig)
        encoded += "textFont: \(textFont.fontName)\n"
        encoded += "centerFont: \(centerFont.fontName)\n"
        encoded += "statusBar: \(statusBar.encode())\n"
        return encoded
    }

    override func update(from values: [String: String]) {
        super.update(from: values)
        if let name = values["textFont"] {
            textFont = NSFont(name: name, size: NSFont.systemFontSize) ?? textFont
        }
        if let name = values["centerFont"] {
            centerFont = NSFont(name: name, size: NSFont.systemFontSize) ?? centerFont
        }
        if let value = values["statusBar"] {
            statusBar = StatusBar(from: value) ?? statusBar
        }
    }
    
    var monochrome: Self {
        let emptyLayout = Self.init()
        emptyLayout.update(from: self.encode(includeColor: false))
        return emptyLayout
    }
    
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<WatchLayout, T>) -> Binding<T> {
        return Binding(get: { self[keyPath: keyPath] }, set: { self[keyPath: keyPath] = $0 })
    }
}

@Observable class WatchSetting {
    static let shared = WatchSetting()
    enum Selection: String, CaseIterable {
        case datetime, location, ringColor, markColor, layout, themes, documentation
    }
    
    var displayTime: Date? = nil
    var timezone: TimeZone? = nil
    @ObservationIgnored var previousSelection: Selection? = nil
    
    private init() {}
}
