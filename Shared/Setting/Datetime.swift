//
//  Datetime.swift
//  Chinese Time iOS
//
//  Created by Leo Liu on 6/23/23.
//

import SwiftUI
import Observation

fileprivate struct TimeZoneSelection: Equatable {
    static func == (lhs: TimeZoneSelection, rhs: TimeZoneSelection) -> Bool {
        lhs.primary == rhs.primary && lhs.secondary == rhs.secondary && lhs.tertiary == rhs.tertiary
    }
    
    let timeZones = populateTimezones()
    var primary: String {
        didSet {
            if let next = timeZones[primary]?.nextLevel.first?.nodeName {
                secondary = next
            } else {
                secondary = ""
            }
        }
    }
    var secondary: String {
        didSet {
            if let next = timeZones[primary]?[secondary]?.nextLevel.first?.nodeName {
                tertiary = next
            } else {
                tertiary = ""
            }
        }
    }
    var tertiary: String
    
    init(primary: String = "", secondary: String = "", tertiary: String = "") {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
    }
    
    init(timezone: TimeZone) {
        let components = timezone.identifier.split(separator: "/")
        primary = if components.count > 0 { String(components[0]) } else { "" }
        secondary = if components.count > 1 { String(components[1]) } else { "" }
        tertiary = if components.count > 2 { String(components[2]) } else { "" }
    }
    
    var timezone: TimeZone? {
        var identifier = primary
        if secondary != "" {
            identifier += "/" + secondary
        }
        if tertiary != "" {
            identifier += "/" + tertiary
        }
        return TimeZone(identifier: identifier)
    }
}

@MainActor
@Observable fileprivate class DateManager {
    var chineseCalendar: ChineseCalendar?
    var watchSetting: WatchSetting?
    var watchLayout: WatchLayout?

    var timeZoneSelection: TimeZoneSelection {
        get {
            TimeZoneSelection(timezone: timezone)
        } set {
            watchSetting?.timezone = newValue.timezone
            updateTimeZone()
        }
    }
    
    var time: Date {
        get {
            watchSetting?.displayTime ?? chineseCalendar?.time ?? .now
        } set {
            watchSetting?.displayTime = newValue
            updateTime()
        }
    }
    
    var timezone: TimeZone {
        get {
            watchSetting?.timezone ?? chineseCalendar?.calendar.timeZone ?? Calendar.current.timeZone
        }
    }
    
    var isCurrent: Bool {
        get {
            watchSetting?.displayTime == nil && watchSetting?.timezone == nil
        } set {
            if newValue {
                watchSetting?.displayTime = nil
                watchSetting?.timezone = nil
            } else {
                watchSetting?.displayTime = chineseCalendar?.time
                watchSetting?.timezone = chineseCalendar?.calendar.timeZone
            }
            updateTimeZone()
        }
    }
    
    var globalMonth: Bool {
        get {
            watchLayout?.globalMonth ?? false
        } set {
            watchLayout?.globalMonth = newValue
            updateTime()
        }
    }
    
    var apparentTime: Bool {
        get {
            watchLayout?.apparentTime ?? false
        } set {
            watchLayout?.apparentTime = newValue
            updateTime()
        }
    }
    
    func setup(watchSetting: WatchSetting, watchLayout: WatchLayout, chineseCalendar: ChineseCalendar) {
        self.watchLayout = watchLayout
        self.watchSetting = watchSetting
        self.chineseCalendar = chineseCalendar
    }
    
    func updateTimeZone() {
        chineseCalendar?.update(time: watchSetting?.displayTime ?? .now,
                               timezone: watchSetting?.timezone ?? Calendar.current.timeZone, location: chineseCalendar?.location)
#if os(macOS)
        updateStatusBar()
#endif
    }
    
    func updateTime() {
        chineseCalendar?.update(time: watchSetting?.displayTime ?? .now)
#if os(macOS)
        updateStatusBar()
#endif
    }
    
#if os(macOS)
    @MainActor
    func updateStatusBar() {
        if let delegate = AppDelegate.instance,
           let chineseCalendar = chineseCalendar,
           let watchLayout = watchLayout {
            delegate.updateStatusBar(dateText: delegate.statusBar(from: chineseCalendar, options: watchLayout))
        }
    }
#endif
}

private func populateTimezones() -> DataTree {
    let root = DataTree(name: "Root")
    let allTimezones = TimeZone.knownTimeZoneIdentifiers
    for timezone in allTimezones {
        let components = timezone.split(separator: "/")
        var currentNode: DataTree? = root
        for component in components {
            currentNode = currentNode?.add(element: String(component))
        }
    }
    return root
}

@MainActor
struct Datetime: View {
    @State fileprivate var dateManager = DateManager()
    @Environment(\.chineseCalendar) var chineseCalendar
    @Environment(\.locationManager) var locationManager
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
    
    var body: some View {
        Form {
            Section(header: Text("算法", comment: "Methodology setting")) {
                HStack {
                    Picker("置閏法", selection: $dateManager.globalMonth) {
                        ForEach([true, false], id: \.self) { globalMonth in
                            if globalMonth {
                                Text("精確至時刻", comment: "Leap month setting: precise")
                            } else {
                                Text("精確至日", comment: "Leap month setting: daily precision")
                            }
                        }
                    }
                }
                
                HStack {
                    Picker("太陽時", selection: $dateManager.apparentTime) {
                        let choice = if locationManager.enabled {
                            [true, false]
                        } else {
                            [false]
                        }
                        ForEach(choice, id: \.self) { apparentTime in
                            if apparentTime {
                                Text("真太陽時", comment: "Time setting: apparent solar time")
                            } else {
                                Text("標準時", comment: "Time setting: mean solar time")
                            }
                        }
                    }
                }
            }
            .pickerStyle(.menu)
            
            Section(header: Text(NSLocalizedString("日時：", comment: "Date & time section") + dateManager.time.formatted(date: .abbreviated, time: .shortened))) {
                Toggle("今", isOn: $dateManager.isCurrent)
                DatePicker("擇時", selection: $dateManager.time, in: ChineseCalendar.start...ChineseCalendar.end, displayedComponents: [.date, .hourAndMinute])
                    .environment(\.timeZone, dateManager.timezone)
            }
            
            let timezoneTitle = if let desp = dateManager.timezone.localizedName(for: .standard, locale: Locale.current) {
                NSLocalizedString("時區：", comment: "Timezone section") + desp
            } else {
                NSLocalizedString("時區", comment: "Timezone section")
            }
            Section(header: Text(timezoneTitle)) {
                HStack {
                    Picker("大區", selection: $dateManager.timeZoneSelection.primary) {
                        ForEach(dateManager.timeZoneSelection.timeZones.nextLevel.map { $0.nodeName }, id: \.self) { tz in
                            Text(tz.replacingOccurrences(of: "_", with: " "))
                                
                        }
                    }
                    .lineLimit(1)
                    .animation(.default, value: dateManager.timeZoneSelection)
                    if let tzList = dateManager.timeZoneSelection.timeZones[dateManager.timeZoneSelection.primary], tzList.count > 0 {
#if os(macOS)
                        Spacer(minLength: 20)
#endif
                        Picker("中區", selection: $dateManager.timeZoneSelection.secondary) {
                            ForEach(tzList.nextLevel.map { $0.nodeName }, id: \.self) { tz in
                                Text(tz.replacingOccurrences(of: "_", with: " "))
                            }
                        }
                        .lineLimit(1)
                        .animation(.default, value: dateManager.timeZoneSelection)
                    }
                    if let tzList = dateManager.timeZoneSelection.timeZones[dateManager.timeZoneSelection.primary], let tzList2 = tzList[dateManager.timeZoneSelection.secondary], tzList2.count > 0 {
#if os(macOS)
                        Spacer(minLength: 20)
#endif
                        Picker("小區", selection: $dateManager.timeZoneSelection.tertiary) {
                            ForEach(tzList2.nextLevel.map { $0.nodeName }, id: \.self) { tz in
                                Text(tz.replacingOccurrences(of: "_", with: " "))
                            }
                        }
                        .lineLimit(1)
                        .animation(.default, value: dateManager.timeZoneSelection)
                    }
                }
                .minimumScaleFactor(0.5)
#if os(iOS)
                .pickerStyle(.wheel)
#elseif os(macOS)
                .pickerStyle(.menu)
#endif
            }
        }
        .formStyle(.grouped)
        .task {
            dateManager.setup(watchSetting: watchSetting, watchLayout: watchLayout, chineseCalendar: chineseCalendar)
        }
        .navigationTitle(Text("日時", comment: "Display time settings"))
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

#Preview("Datetime") {
    Datetime()
}
