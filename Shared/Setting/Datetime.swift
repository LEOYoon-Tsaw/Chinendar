//
//  Datetime.swift
//  Chinendar
//
//  Created by Leo Liu on 6/23/23.
//

import SwiftUI
import Observation

final class DataTree: CustomStringConvertible {
    var nodeName: String
    private var offsprings: [DataTree]
    private var registry: [String: Int]

    init(name: String) {
        nodeName = name
        offsprings = []
        registry = [:]
    }

    var nextLevel: [DataTree] {
        get {
            offsprings
        }
    }

    func add(element: String) -> DataTree {
        let data: DataTree
        if let index = registry[element] {
            data = offsprings[index]
        } else {
            registry[element] = offsprings.count
            offsprings.append(DataTree(name: element))
            data = offsprings.last!
        }
        return data
    }

    var count: Int {
        offsprings.count
    }

    subscript(element: String) -> DataTree? {
        if let index = registry[element] {
            return offsprings[index]
        } else {
            return nil
        }
    }

    var description: String {
        var string: String
        if offsprings.count > 0 {
            string = "{\(nodeName): "
        } else {
            string = "\(nodeName)"
        }
        for offspring in offsprings {
            string += offspring.description
        }
        if offsprings.count > 0 {
            string += "}, "
        } else {
            string += ","
        }
        return string
    }
}

private struct TimeZoneSelection: Equatable {
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

@MainActor
@Observable private final class DateManager: Bindable {
    var viewModel: ViewModel?
    
    func setup(viewModel: ViewModel) {
        self.viewModel = viewModel
        update()
    }
    
    var chineseCalendar: ChineseCalendar {
        get {
            viewModel?.chineseCalendar ?? .init()
        } set {
            viewModel?.settings.displayTime = newValue.time
            update()
        }
    }

    var timeZoneSelection: TimeZoneSelection {
        get {
            TimeZoneSelection(timezone: timezone)
        } set {
            if let tz = newValue.timezone {
                viewModel?.config.timezone = tz
                update()
            }
        }
    }

    var time: Date {
        get {
            viewModel?.settings.displayTime ?? viewModel?.chineseCalendar.time ?? .now
        } set {
            viewModel?.settings.displayTime = newValue
            update()
        }
    }

    var timezone: TimeZone {
        get {
            viewModel?.config.timezone ?? viewModel?.chineseCalendar.calendar.timeZone ?? Calendar.current.timeZone
        }
    }

    var isCurrent: Bool {
        get {
            viewModel?.settings.displayTime == nil
        } set {
            if newValue {
                viewModel?.settings.displayTime = nil
            } else {
                viewModel?.settings.displayTime = viewModel?.chineseCalendar.time
            }
            update()
        }
    }

    var isTimezoneCurrent: Bool {
        get {
            viewModel?.config.timezone == nil
        } set {
            if newValue {
                viewModel?.config.timezone = nil
            } else {
                viewModel?.config.timezone = Calendar.current.timeZone
            }
            update()
        }
    }

    var globalMonth: Bool {
        get {
            viewModel?.config.globalMonth ?? false
        } set {
            viewModel?.config.globalMonth = newValue
            update()
        }
    }

    var apparentTime: Bool {
        get {
            viewModel?.config.apparentTime ?? false
        } set {
            viewModel?.config.apparentTime = newValue
            update()
        }
    }

    var largeHour: Bool {
        get {
            viewModel?.config.largeHour ?? false
        } set {
            viewModel?.config.largeHour = newValue
            update()
        }
    }

    private func update() {
        viewModel?.updateChineseCalendar()
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
    @State fileprivate var reverseCount = false
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        Form {
            Section(header: Text("算法", comment: "Methodology setting")) {
                HStack {
                    Picker("置閏法", selection: dateManager.binding(\.globalMonth)) {
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
                    Picker("太陽時", selection: dateManager.binding(\.apparentTime)) {
                        let choice = if viewModel.location != nil {
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
                    Picker("時辰", selection: dateManager.binding(\.largeHour)) {
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
                Toggle("今", isOn: dateManager.binding(\.isCurrent))
                DatePicker("擇時", selection: dateManager.binding(\.time), in: ChineseCalendar.start...ChineseCalendar.end, displayedComponents: [.date, .hourAndMinute])
                    .environment(\.timeZone, dateManager.timezone)
            }
            
            Section(header: Text(NSLocalizedString("華曆日期：", comment: "Chinendar date & time section"))) {
                HStack {
                    Text("日期")
                    ChinendarDatePicker(chineseCalendar: dateManager.binding(\.chineseCalendar))
                    Spacer()
                        .frame(idealWidth: 10, maxWidth: 20)
                    Text("時間")
                    ChinendarTimePicker(chineseCalendar: dateManager.binding(\.chineseCalendar))
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            let timezoneTitle = if let desp = dateManager.timezone.localizedName(for: .standard, locale: Locale.current) {
                NSLocalizedString("時區：", comment: "Timezone section") + desp
            } else {
                NSLocalizedString("時區", comment: "Timezone section")
            }
            Section(header: Text(timezoneTitle)) {
                Toggle("今時區", isOn: dateManager.binding(\.isTimezoneCurrent))
                HStack(spacing: 10) {
                    Picker("大區", selection: dateManager.binding(\.timeZoneSelection.primary)) {
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
                        Picker("中區", selection: dateManager.binding(\.timeZoneSelection.secondary)) {
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
                        Picker("小區", selection: dateManager.binding(\.timeZoneSelection.tertiary)) {
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
                .frame(maxHeight: 125)
#else
                .pickerStyle(.menu)
#endif
            }
        }
        .formStyle(.grouped)
        .task {
            dateManager.setup(viewModel: viewModel)
        }
        .navigationTitle(Text("日時", comment: "Display time settings"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
                viewModel.settings.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#endif
    }
}

#Preview("Datetime", traits: .modifier(SampleData())) {
    Datetime()
}
