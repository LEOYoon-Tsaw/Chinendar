//
//  Datetime.swift
//  Chinendar
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

@Observable fileprivate class DateManager {
    var chineseCalendar: ChineseCalendar?
    var watchSetting: WatchSetting?
    var calendarConfigure: CalendarConfigure?

    var timeZoneSelection: TimeZoneSelection {
        get {
            TimeZoneSelection(timezone: timezone)
        } set {
            if let tz = newValue.timezone {
                calendarConfigure?.timezone = tz
                update()
            }
        }
    }
    
    var time: Date {
        get {
            watchSetting?.displayTime ?? chineseCalendar?.time ?? .now
        } set {
            watchSetting?.displayTime = newValue
            update()
        }
    }
    
    var timezone: TimeZone {
        get {
            calendarConfigure?.timezone ?? chineseCalendar?.calendar.timeZone ?? Calendar.current.timeZone
        }
    }
    
    var isCurrent: Bool {
        get {
            watchSetting?.displayTime == nil
        } set {
            if newValue {
                watchSetting?.displayTime = nil
            } else {
                watchSetting?.displayTime = chineseCalendar?.time
            }
            update()
        }
    }
    
    var isTimezoneCurrent: Bool {
        get {
            calendarConfigure?.timezone == nil
        } set {
            if newValue {
                calendarConfigure?.timezone = nil
            } else {
                calendarConfigure?.timezone = Calendar.current.timeZone
            }
            update()
        }
    }
    
    var globalMonth: Bool {
        get {
            calendarConfigure?.globalMonth ?? false
        } set {
            calendarConfigure?.globalMonth = newValue
            update()
        }
    }
    
    var apparentTime: Bool {
        get {
            calendarConfigure?.apparentTime ?? false
        } set {
            calendarConfigure?.apparentTime = newValue
            update()
        }
    }
    
    var largeHour: Bool {
        get {
            calendarConfigure?.largeHour ?? false
        } set {
            calendarConfigure?.largeHour = newValue
            update()
        }
    }
    
    func setup(watchSetting: WatchSetting, calendarConfigure: CalendarConfigure, chineseCalendar: ChineseCalendar) {
        self.calendarConfigure = calendarConfigure
        self.watchSetting = watchSetting
        self.chineseCalendar = chineseCalendar
    }
    
    private func update() {
        chineseCalendar?.update(time: watchSetting?.displayTime ?? .now,
                                timezone: calendarConfigure?.effectiveTimezone, globalMonth: calendarConfigure?.globalMonth, apparentTime: calendarConfigure?.apparentTime, largeHour: calendarConfigure?.largeHour)
    }
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

struct Datetime: View {
    @State fileprivate var dateManager = DateManager()
    @Environment(ChineseCalendar.self) var chineseCalendar
    @Environment(LocationManager.self) var locationManager
    @Environment(CalendarConfigure.self) var calendarConfigure
    @Environment(WatchSetting.self) var watchSetting
    
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
                        let choice = if calendarConfigure.location(locationManager: locationManager) != nil {
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
                
                HStack {
                    Picker("時辰", selection: $dateManager.largeHour) {
                        ForEach([true, false], id: \.self) { largeHour in
                            if largeHour {
                                Text("不分初正", comment: "Large hour setting: large")
                            } else {
                                Text("分初正", comment: "Large hour setting: small")
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
                Toggle("今時區", isOn: $dateManager.isTimezoneCurrent)
                HStack(spacing: 10) {
                    Picker("大區", selection: $dateManager.timeZoneSelection.primary) {
                        ForEach(dateManager.timeZoneSelection.timeZones.nextLevel.map { $0.nodeName }, id: \.self) { tz in
                            Text(tz.replacingOccurrences(of: "_", with: " "))
                                
                        }
                    }
                    .lineLimit(1)
                    .animation(.default, value: dateManager.timeZoneSelection)
                    if let tzList = dateManager.timeZoneSelection.timeZones[dateManager.timeZoneSelection.primary], tzList.count > 0 {
#if os(macOS) || os(visionOS)
                        Divider()
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
#if os(macOS) || os(visionOS)
                        Divider()
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
            dateManager.setup(watchSetting: watchSetting, calendarConfigure: calendarConfigure, chineseCalendar: chineseCalendar)
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
    let chineseCalendar = ChineseCalendar()
    let locationManager = LocationManager()
    let calendarConfigure = CalendarConfigure()
    let watchSetting = WatchSetting()

    return Datetime()
    .environment(chineseCalendar)
    .environment(locationManager)
    .environment(calendarConfigure)
    .environment(watchSetting)
}
