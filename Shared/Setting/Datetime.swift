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
    var chinendarError: ChineseCalendar.ChineseDate?
    var presentError: Bool {
        get {
            chinendarError != nil
        } set {
            if newValue {
                chinendarError = .init(month: 1, day: 1)
            } else {
                chinendarError = nil
            }
        }
    }
    var chinendarMonth: Int {
        get {
            guard let chineseCalendar = viewModel?.chineseCalendar else { return 1 }
            return chineseDate.monthIndex(in: chineseCalendar)
        } set {
            guard let chineseCalendar = viewModel?.chineseCalendar else { return }
            chineseDate.update(monthIndex: newValue, in: chineseCalendar)
        }
    }
    
    func setup(viewModel: ViewModel) {
        self.viewModel = viewModel
        update()
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
    
    var chineseDate: ChineseCalendar.ChineseDate {
        get {
            if let chineseCalendar = viewModel?.chineseCalendar {
                return .init(month: chineseCalendar.nominalMonth, day: chineseCalendar.day, leap: chineseCalendar.isLeapMonth)
            } else {
                return .init(month: 1, day: 1)
            }
        } set {
            if let newDate = viewModel?.chineseCalendar.startOf(chineseDate: newValue) {
                viewModel?.settings.displayTime = newDate
                update()
            } else {
                chinendarError = newValue
            }
        }
    }
    
    func nextYear() {
        viewModel?.settings.displayTime = viewModel?.chineseCalendar.nextYear()
        update()
    }
    
    func previousYear() {
        viewModel?.settings.displayTime = viewModel?.chineseCalendar.previousYear()
        update()
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
            
            if let chineseCalendar = dateManager.viewModel?.chineseCalendar {
                Section(header: Text(NSLocalizedString("華曆日期：", comment: "Chinendar date & time section"))) {
                    HStack {
                        Picker("月", selection: dateManager.binding(\.chinendarMonth)) {
                            ForEach(1...chineseCalendar.numberOfMonths, id: \.self) { monthIndex in
                                let dummyChineseDate = ChineseCalendar.ChineseDate(monthIndex: monthIndex, day: 1, in: chineseCalendar)
                                if dummyChineseDate.leap {
                                    Text("閏\(ChineseCalendar.month_chinese_localized[dummyChineseDate.month-1])")
                                        .lineLimit(1)
                                } else {
                                    Text(ChineseCalendar.month_chinese_localized[dummyChineseDate.month-1])
                                        .lineLimit(1)
                                }
                            }
                        }
                        .animation(.default, value: dateManager.chinendarMonth)
                        Picker("日", selection: dateManager.binding(\.chineseDate.day)) {
                            ForEach(1...chineseCalendar.numberOfDaysInMonth, id: \.self) { day in
                                Text("\(ChineseCalendar.day_chinese_localized[day-1])日")
                                    .lineLimit(1)
                            }
                        }
                        .animation(.default, value: dateManager.chineseDate)
                    }
                    .minimumScaleFactor(0.5)
#if os(iOS)
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 125)
#else
                    .pickerStyle(.menu)
#endif
                    HStack {
                        Button {
                            dateManager.previousYear()
                        } label: {
                            Label("前年", systemImage: "chevron.backward")
                        }
                        .labelStyle(IconCenterStyleLeft())
                        Spacer()
                        Button {
                            dateManager.nextYear()
                        } label: {
                            Label("後年", systemImage: "chevron.forward")
                        }
                        .labelStyle(IconCenterStyleRight())
                    }
#if os(iOS)
                    .buttonStyle(.borderless)
#else
                    .buttonStyle(.bordered)
#endif
                }
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
        .alert("轉換有誤", isPresented: dateManager.binding(\.presentError)) {
            Button("罷", role: .cancel) {}
        } message: {
            if let chinendarError = dateManager.chinendarError {
                Text("華曆今年無此日：\(chinendarError.leap ? ChineseCalendar.leapLabel_localized : "")\(ChineseCalendar.month_chinese_localized[chinendarError.month-1])\(ChineseCalendar.day_chinese_localized[chinendarError.day-1])日", comment: "Chinendar date not convertible")
            } else {
                Text("")
            }
        }
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
