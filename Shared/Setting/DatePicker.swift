//
//  DatePicker.swift
//  Chinendar
//
//  Created by Leo Liu on 9/21/24.
//

import SwiftUI

@MainActor
fileprivate final class DatePickerModel: Bindable {
    @Binding var chineseCalendar: ChineseCalendar
    
    init(chineseCalendar: Binding<ChineseCalendar>) {
        self._chineseCalendar = chineseCalendar
    }
    
    var chineseDate: ChineseCalendar.ChineseDate {
        get {
            .init(month: chineseCalendar.nominalMonth, day: chineseCalendar.day, subquarter: chineseCalendar.subquarter, leap: chineseCalendar.isLeapMonth)
        } set {
            if let newDate = chineseCalendar.find(chineseDate: newValue) {
                chineseCalendar.update(time: newDate)
            }
        }
    }
    
    var chinendarMonth: Int {
        get {
            chineseDate.monthIndex(in: chineseCalendar)
        } set {
            chineseDate.update(monthIndex: newValue, in: chineseCalendar)
        }
    }
    
    func nextMonth() {
        if let newDate = chineseCalendar.nextMonth() {
            chineseCalendar.update(time: newDate)
        }
    }
    
    func previousMonth() {
        if let newDate = chineseCalendar.previousMonth() {
            chineseCalendar.update(time: newDate)
        }
    }
    
    func nextYear() {
        if let newDate = chineseCalendar.nextYear() {
            chineseCalendar.update(time: newDate)
        }
    }
    
    func previousYear() {
        if let newDate = chineseCalendar.previousYear() {
            chineseCalendar.update(time: newDate)
        }
    }
}

@MainActor
fileprivate final class TimePickerModel: Bindable {
    @Binding var chineseCalendar: ChineseCalendar
    
    init(chineseCalendar: Binding<ChineseCalendar>) {
        self._chineseCalendar = chineseCalendar
    }
    
    var largeHour: Bool {
        chineseCalendar.largeHour
    }
    
    var hour: Int {
        chineseCalendar.hour
    }
    
    var hourMajor: Int {
        get {
            if largeHour {
                hour / 2
            } else {
                ((hour + 1) %% 24) / 2
            }
        } set {
            if largeHour {
                updateSubquarters(hour: newValue * 2)
            } else {
                updateSubquarters(hour: (newValue * 2 + hourPostfix - 1) %% 24)
            }
        }
    }
    var hourPostfix: Int {
        get {
            if largeHour {
                0
            } else {
                (hour + 1) %% 2
            }
        } set {
            if !largeHour {
                updateSubquarters(hour: (hourMajor * 2 + newValue - 1) %% 24)
            }
        }
    }
    var quarterMajor: Int {
        get {
            chineseCalendar.quarterMajor
        } set {
            updateSubquarters(quarterMajor: newValue)
        }
    }
    var quarterMinor: Int {
        get {
            chineseCalendar.quarterMinor
        } set {
            updateSubquarters(quarterMinor: newValue)
        }
    }
    var maxQuarterMinor: Int {
        let hourStartCap = (quarterMajor + 1) * 6 - hour %% 6
        let hourEndCap = hourStartCap - (largeHour ? 50 : 25)
        return min(6, hourStartCap, 6 - hourEndCap)
    }
    
    private func updateSubquarters(hour: Int? = nil, quarterMajor: Int? = nil, quarterMinor: Int? = nil) {
        let hour = hour ?? self.hour
        let quarterMajor = quarterMajor ?? self.quarterMajor
        let quarterMinor = quarterMinor ?? self.quarterMinor
        
        let hourStartCap = (quarterMajor + 1) * 6 - hour %% 6
        let hourEndCap = hourStartCap - (largeHour ? 50 : 25)
        let maxQuarterMinor = min(6, hourStartCap, 6 - hourEndCap)
        
        let subquarters = hour * 25 + max(0, quarterMajor * 6 - (hour %% 6)) + min(maxQuarterMinor - 1, quarterMinor)
        let newTime = chineseCalendar.startOfDay + Double(subquarters) * 144
        chineseCalendar.update(time: newTime)
    }
}

fileprivate func monthLabel(monthIndex: Int, in chineseCalendar: ChineseCalendar) -> String {
    let dummyChineseDate = ChineseCalendar.ChineseDate(monthIndex: monthIndex, day: 1, in: chineseCalendar)
    if dummyChineseDate.leap {
        return String(localized: "閏\(ChineseCalendar.month_chinese_localized[dummyChineseDate.month-1])")
    } else {
        return String(localized: ChineseCalendar.month_chinese_localized[dummyChineseDate.month-1])
    }
}

#if os(watchOS)
struct ChinendarPickerPanel: View {
    private var dateModel: DatePickerModel
    private var timeModel: TimePickerModel
    
    init(chineseCalendar: Binding<ChineseCalendar>) {
        self.dateModel = DatePickerModel(chineseCalendar: chineseCalendar)
        self.timeModel = TimePickerModel(chineseCalendar: chineseCalendar)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 3) {
                Button {
                    dateModel.previousYear()
                } label: {
                    Label("前年", systemImage: "chevron.backward.2")
                        .fontWeight(.bold)
                }
                .padding(.top)
                Picker("月", selection: dateModel.binding(\.chinendarMonth)) {
                    ForEach(1...dateModel.chineseCalendar.numberOfMonths, id: \.self) { monthIndex in
                        Text(monthLabel(monthIndex: monthIndex, in: dateModel.chineseCalendar))
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                    }
                }
                .animation(.default, value: dateModel.chinendarMonth)
                Picker("日", selection: dateModel.binding(\.chineseDate.day)) {
                    ForEach(1...dateModel.chineseCalendar.numberOfDaysInMonth, id: \.self) { day in
                        Text("\(ChineseCalendar.day_chinese_localized[day-1])日")
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                }
                .animation(.default, value: dateModel.chineseDate)
                Button {
                    dateModel.nextYear()
                } label: {
                    Label("後年", systemImage: "chevron.forward.2")
                        .fontWeight(.bold)
                }
                .padding(.top)
            }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .buttonBorderShape(.capsule)
        
            HStack(spacing: 3) {
                Picker("華曆時", selection: timeModel.binding(\.hourMajor)) {
                    ForEach(0..<12, id: \.self) { hourIndex in
                        Text("\(ChineseCalendar.terrestrial_branches_localized[hourIndex])時")
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .animation(.default, value: timeModel.hourMajor)
                if !timeModel.largeHour {
                    Picker("初正", selection: timeModel.binding(\.hourPostfix)) {
                        ForEach(0..<2, id: \.self) { postfix in
                            Text(ChineseCalendar.sub_hour_name_localized[postfix])
                                .lineLimit(1)
                                .minimumScaleFactor(0.4)
                        }
                    }
                    .animation(.default, value: timeModel.hourPostfix)
                }
                Picker("刻", selection: timeModel.binding(\.quarterMajor)) {
                    ForEach(0...(timeModel.largeHour ? 8 : 4), id: \.self) { quarterIndex in
                        Text("\(ChineseCalendar.chinese_numbers_localized[quarterIndex])刻")
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .animation(.default, value: timeModel.quarterMajor)
                Picker("小刻", selection: timeModel.binding(\.quarterMinor)) {
                    ForEach(0..<timeModel.maxQuarterMinor, id: \.self) { subquarterIndex in
                        Text("\(ChineseCalendar.chinese_numbers_localized[subquarterIndex])")
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .animation(.default, value: timeModel.quarterMajor)
            }
        }
    }
}

#Preview("Watch") {
    @Previewable @State var chineseCalendar = ChineseCalendar()
    ChinendarPickerPanel(chineseCalendar: $chineseCalendar)
}
#else
fileprivate struct ChinendarDatePickerPanel: View {
    private var model: DatePickerModel
    private let dateColumns = Array(repeating: GridItem(spacing: 0), count: 10)
    private let monthColumns = Array(repeating: GridItem(spacing: 0), count: 6)
    @State private var monthView = false
#if os(iOS) || os(visionOS)
    @ScaledMetric(relativeTo: .body) var dateSize: CGFloat = 50
#else
    @ScaledMetric(relativeTo: .body) var dateSize: CGFloat = 30
#endif

    init(chineseCalendar: Binding<ChineseCalendar>) {
        self.model = DatePickerModel(chineseCalendar: chineseCalendar)
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation {
                        model.previousYear()
                    }
                } label: {
                    Label("前年", systemImage: "chevron.backward.2")
                        .fontWeight(.bold)
                }
                Spacer()
                Button {
                    withAnimation {
                        model.previousMonth()
                    }
                } label: {
                    Label("前月", systemImage: "chevron.backward")
                }
                Button {
                    withAnimation {
                        monthView.toggle()
                    }
                } label: {
                    Label {
                        Text(monthLabel(monthIndex: model.chinendarMonth, in: model.chineseCalendar))
                            .fontWeight(.bold)
                            .lineLimit(1)
                    } icon: {
                        if monthView {
                            Image(systemName: "chevron.up")
                                .font(.footnote)
                        } else {
                            Image(systemName: "chevron.down")
                                .font(.footnote)
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .animation(.default, value: monthView)
                }
                .padding(.horizontal)
                Button {
                    withAnimation {
                        model.nextMonth()
                    }
                } label: {
                    Label("後月", systemImage: "chevron.forward")
                }
                Spacer()
                Button {
                    withAnimation {
                        model.nextYear()
                    }
                } label: {
                    Label("後年", systemImage: "chevron.forward.2")
                        .fontWeight(.bold)
                }
            }
            .labelStyle(.iconOnly)
            .animation(.default, value: model.chinendarMonth)
            
            Divider()
                .padding(0)
            
            if monthView {
                LazyVGrid(columns: monthColumns, spacing: 0) {
                    ForEach(1...model.chineseCalendar.numberOfMonths, id: \.self) { monthIndex in
                        let monthButton = Button {
                            withAnimation {
                                model.chinendarMonth = monthIndex
                            }
                        } label: {
                            Text(monthLabel(monthIndex: monthIndex, in: model.chineseCalendar))
                                .lineLimit(1)
                        }
                            .frame(minWidth: dateSize * 2, minHeight: dateSize)
                            .buttonBorderShape(.capsule)
                        if monthIndex == model.chinendarMonth {
                            monthButton
#if os(visionOS)
                                .buttonStyle(.automatic)
#else
                                .buttonStyle(.bordered)
                                .fontWeight(.bold)
                                .tint(.blue)
#endif
                        } else {
                            monthButton
                                .foregroundStyle(.primary)
                                .buttonStyle(.plain)
                        }
                    }
                }
                .animation(.default, value: model.chinendarMonth)
            } else {
                LazyVGrid(columns: dateColumns, spacing: 0) {
                    let fullMoonDay = model.chineseCalendar.dayTicks.majorTicks.count { tick in
                        tick < (model.chineseCalendar.eventInMonth.fullMoon.first?.pos ?? 0.0)
                    }
                    ForEach(1...model.chineseCalendar.numberOfDaysInMonth, id: \.self) { day in
                        let dateText = switch day {
                        case model.chineseDate.day:
                            Text("\(day)")
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        case fullMoonDay:
                            Text("\(day)")
                                .foregroundStyle(.orange)
                        default:
                            Text("\(day)")
                                .foregroundStyle(.primary)
                        }
                        let dayButton = Button {
                            withAnimation {
                                model.chineseDate.day = day
                            }
                        } label: {
                            dateText
                                .lineLimit(1)
                                .frame(minWidth: dateSize)
                        }
                            .frame(width: dateSize, height: dateSize)
                            .buttonBorderShape(.circle)
                        
                        if model.chineseDate.day == day {
                            dayButton
#if os(visionOS)
                                .buttonStyle(.automatic)
#else
                                .buttonStyle(.bordered)
                                .tint(.blue)
#endif
                        } else {
                            dayButton
                                .buttonStyle(.plain)
                        }
                    }
                }
                .animation(.default, value: model.chineseDate.day)
            }
        }
    }
}

struct ChinendarTimePickerPanel: View {
    private var model: TimePickerModel
    
    init(chineseCalendar: Binding<ChineseCalendar>) {
        self.model = TimePickerModel(chineseCalendar: chineseCalendar)
    }
    
    var body: some View {
        HStack {
            Picker("華曆時", selection: model.binding(\.hourMajor)) {
                ForEach(0..<12, id: \.self) { hourIndex in
                    Text("\(ChineseCalendar.terrestrial_branches_localized[hourIndex])時")
                        .lineLimit(1)
                }
            }
            .animation(.default, value: model.hourMajor)
            if !model.largeHour {
                Picker("初正", selection: model.binding(\.hourPostfix)) {
                    ForEach(0..<2, id: \.self) { postfix in
                        Text(ChineseCalendar.sub_hour_name_localized[postfix])
                            .lineLimit(1)
                    }
                }
                .labelsHidden()
                .animation(.default, value: model.hourPostfix)
            }
            Picker("刻", selection: model.binding(\.quarterMajor)) {
                ForEach(0...(model.largeHour ? 8 : 4), id: \.self) { quarterIndex in
                    Text("\(ChineseCalendar.chinese_numbers_localized[quarterIndex])刻")
                        .lineLimit(1)
                }
            }
            .animation(.default, value: model.quarterMajor)
            Picker("小刻", selection: model.binding(\.quarterMinor)) {
                ForEach(0..<model.maxQuarterMinor, id: \.self) { subquarterIndex in
                    Text("\(ChineseCalendar.chinese_numbers_localized[subquarterIndex])")
                        .lineLimit(1)
                }
            }
            .animation(.default, value: model.quarterMajor)
        }
#if os(iOS)
        .minimumScaleFactor(0.5)
        .pickerStyle(.wheel)
        .frame(maxHeight: 200)
#elseif !os(watchOS)
        .pickerStyle(.menu)
#endif
    }
}

struct ChinendarDatePicker: View {
    @Binding var chineseCalendar: ChineseCalendar
    @State private var presentPicker = false
    
    var body: some View {
        Button {
            presentPicker = true
        } label: {
            Text(chineseCalendar.dateString)
        }
        .foregroundStyle(.primary)
        .popover(isPresented: $presentPicker) {
            ChinendarDatePickerPanel(chineseCalendar: $chineseCalendar)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }
}

struct ChinendarTimePicker: View {
    @Binding var chineseCalendar: ChineseCalendar
    @State private var presentPicker = false
    
    var body: some View {
        Button {
            presentPicker = true
        } label: {
            Text(chineseCalendar.timeString)
        }
        .foregroundStyle(.primary)
        .popover(isPresented: $presentPicker) {
            ChinendarTimePickerPanel(chineseCalendar: $chineseCalendar)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview("non Watch") {
    @Previewable @State var chineseCalendar = ChineseCalendar()
    HStack {
        ChinendarDatePicker(chineseCalendar: $chineseCalendar)
        ChinendarTimePicker(chineseCalendar: $chineseCalendar)
    }
}
#endif
