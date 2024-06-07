//
//  Layout.swift
//  Chinendar
//
//  Created by Leo Liu on 11/12/23.
//

import SwiftUI
import Observation

@Observable final class WatchLayout: MetaWatchLayout {

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

    var textFont = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)
    var centerFont = UIFont(name: "SourceHanSansKR-Heavy", size: UIFont.systemFontSize)!

    var statusBar = StatusBar()

    override func encode(includeOffset: Bool = true, includeColor: Bool = true) -> String {
        var encoded = super.encode(includeOffset: includeOffset, includeColor: includeColor)
        encoded += "statusBar: \(statusBar.encode())\n"
        return encoded
    }

    override func update(from values: [String: String], updateSize: Bool = true) {
        super.update(from: values, updateSize: updateSize)
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
    enum Selection: String, CaseIterable {
        case datetime, location, configs, ringColor, decoration, markColor, layout, themes
    }
    enum TabSelection: String, CaseIterable {
        case spaceTime, design, documentation
    }

    var displayTime: Date?
    var vertical = true
    var settingIsOpen = false
    var timeDisplay = ""
    @ObservationIgnored var previousSelectionSpaceTime: Selection?
    @ObservationIgnored var previousSelectionDesign: Selection?
    @ObservationIgnored var previousTabSelection: TabSelection?
    var effectiveTime: Date {
        displayTime ?? .now
    }

    func binding<T>(_ keyPath: ReferenceWritableKeyPath<WatchSetting, T>) -> Binding<T> {
        return Binding(get: { self[keyPath: keyPath] }, set: { self[keyPath: keyPath] = $0 })
    }
}
