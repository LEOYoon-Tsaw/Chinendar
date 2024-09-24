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
            chineseCalendar.chineseDate
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
    var maxQuarterMajor: Int {
        chineseCalendar.maxQuarterMajor
    }
    var maxQuarterMinor: Int {
        chineseCalendar.maxQuarterMinor
    }
    
    var hour: Int {
        get {
            chineseCalendar.hour
        } set {
            updateSubquarters(hour: newValue)
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
    
    func prevHour() {
        if largeHour {
            updateSubquarters(hour: hour - 2)
        } else {
            updateSubquarters(hour: hour - 1)
        }
    }
    func nextHour() {
        if largeHour {
            updateSubquarters(hour: hour + 2)
        } else {
            updateSubquarters(hour: hour + 1)
        }
    }
    func prevDay() {
        var newChineseCalendar = chineseCalendar
        newChineseCalendar.update(time: chineseCalendar.startOfDay - 1)
        var chineseDate = chineseCalendar.chineseDate
        chineseDate.month = newChineseCalendar.nominalMonth
        chineseDate.day = newChineseCalendar.day
        chineseDate.leap = newChineseCalendar.isLeapMonth
        if let newDate = newChineseCalendar.find(chineseDate: chineseDate) {
            chineseCalendar.update(time: newDate)
        }
    }
    func nextDay() {
        var newChineseCalendar = chineseCalendar
        newChineseCalendar.update(time: chineseCalendar.startOfNextDay + 1)
        var chineseDate = chineseCalendar.chineseDate
        chineseDate.month = newChineseCalendar.nominalMonth
        chineseDate.day = newChineseCalendar.day
        chineseDate.leap = newChineseCalendar.isLeapMonth
        if let newDate = newChineseCalendar.find(chineseDate: chineseDate) {
            chineseCalendar.update(time: newDate)
        }
    }
    
    private func updateSubquarters(hour: Int? = nil, quarterMajor: Int? = nil, quarterMinor: Int? = nil) {
        var chineseDate = chineseCalendar.chineseDate
        chineseDate.hour ?= hour
        chineseDate.quarter ?= quarterMajor
        chineseDate.subQuarter ?= quarterMinor
        if let newDate = chineseCalendar.find(chineseDate: chineseDate) {
            chineseCalendar.update(time: newDate)
        }
    }
}

fileprivate func monthLabel(monthIndex: Int, in chineseCalendar: ChineseCalendar) -> String {
    let dummyChineseDate = ChineseCalendar.ChineseDate(monthIndex: monthIndex, in: chineseCalendar)
    if dummyChineseDate.leap {
        return String(localized: "閏\(ChineseCalendar.month_chinese_localized[dummyChineseDate.month-1])")
    } else {
        return String(localized: ChineseCalendar.month_chinese_localized[dummyChineseDate.month-1])
    }
}

fileprivate func hourName(hour: Int, largeHour: Bool) -> String {
    if largeHour {
        return String(localized: "\(ChineseCalendar.terrestrial_branches_localized[hour / 2])時")
    } else {
        return String(localized: "\(ChineseCalendar.terrestrial_branches_localized[((hour + 1) %% 24) / 2])\(ChineseCalendar.sub_hour_name_localized[(hour + 1) %% 2])")
        
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
                Picker("華曆時", selection: timeModel.binding(\.hour)) {
                    ForEach(Array(stride(from: 0, to: 24, by: timeModel.largeHour ? 2 : 1)), id: \.self) { hour in
                        Text(hourName(hour: hour, largeHour: timeModel.largeHour))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .animation(.default, value: timeModel.hour)
                Picker("刻", selection: timeModel.binding(\.quarterMajor)) {
                    ForEach(0..<timeModel.maxQuarterMajor, id: \.self) { quarterIndex in
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
                .animation(.default, value: timeModel.quarterMinor)
            }
        }
    }
}

#Preview("Watch") {
    @Previewable @State var chineseCalendar = ChineseCalendar()
    ChinendarPickerPanel(chineseCalendar: $chineseCalendar)
}
#else
fileprivate struct DragablePicker<V: View>: View {
    @State private var dragOffset: CGFloat = 0
    @State private var size: CGSize = .zero
    @State private var dragTriggered: Int = 0
    let view: V
    let prevAction: () -> Void
    let nextAction: () -> Void
    
    init(@ViewBuilder view: () -> V, prevAction: @escaping () -> Void, nextAction: @escaping () -> Void) {
        self.view = view()
        self.prevAction = prevAction
        self.nextAction = nextAction
    }
    
    var body: some View {
        let dragGesture = DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
                if abs(value.translation.width) > size.width / 3 {
                    dragTriggered = value.translation.width > 0 ? 1 : -1
                } else {
                    withAnimation(.easeIn(duration: 0.2)) {
                        dragTriggered = 0
                    }
                }
            }
            .onEnded { value in
                if abs(value.translation.width) < size.width / 3 {
                    withAnimation(.bouncy) {
                        dragOffset = 0
                    }
                } else if value.translation.width > 0 {
                    dragOffset = -size.width
                    prevAction()
                    withAnimation(.easeOut) {
                        dragOffset = 0
                    }
                } else {
                    dragOffset = size.width
                    nextAction()
                    withAnimation(.easeOut) {
                        dragOffset = 0
                    }
                }
            }
            
        ZStack {
            HStack {
                Image(systemName: "chevron.backward")
                    .font(dragTriggered > 0 ? .largeTitle : .title3)
                    .opacity(max(0, min(1, dragOffset / (size.width + 1.0) * 2.0)))
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(dragTriggered < 0 ? .largeTitle : .title3)
                    .opacity(max(0, min(1, -dragOffset / (size.width + 1.0) * 2.0)))
            }
#if os(iOS)
            .foregroundStyle(.blue)
#endif
            view
                .contentShape(.interaction, .containerRelative)
                .background(GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size, initial: true) {
                            size = geometry.size
                        }
                })
                .offset(x: dragOffset, y: 0)
                .highPriorityGesture(dragGesture)
        }
    }
}

fileprivate struct ChinendarDatePickerPanel: View {
    private var model: DatePickerModel
    private let dateColumns = Array(repeating: GridItem(spacing: 0), count: 10)
    private let monthColumns = Array(repeating: GridItem(spacing: 0), count: 6)
    @State private var monthView = false
#if os(visionOS)
    @ScaledMetric(relativeTo: .body) var cellSize: CGFloat = 65
#elseif os(iOS)
    @ScaledMetric(relativeTo: .body) var cellSize: CGFloat = 50
#else
    @ScaledMetric(relativeTo: .body) var cellSize: CGFloat = 30
#endif

    init(chineseCalendar: Binding<ChineseCalendar>) {
        self.model = DatePickerModel(chineseCalendar: chineseCalendar)
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation {
                        monthView.toggle()
                    }
                } label: {
                    HStack {
                        Text(monthLabel(monthIndex: model.chinendarMonth, in: model.chineseCalendar))
                            .fontWeight(.bold)
                            .lineLimit(1)
                        if monthView {
                            Image(systemName: "chevron.up")
                                .font(.footnote)
                        } else {
                            Image(systemName: "chevron.forward")
                                .font(.footnote)
                        }
                    }
                    .animation(.default, value: monthView)
                }
                .padding(.horizontal)
                .animation(.default, value: model.chinendarMonth)
                Spacer()
                if monthView {
                    Button {
                        withAnimation {
                            model.previousYear()
                        }
                    } label: {
                        Label("前年", systemImage: "chevron.backward")
                    }
                    Text("調整年")
                    Button {
                        withAnimation {
                            model.nextYear()
                        }
                    } label: {
                        Label("後年", systemImage: "chevron.forward")
                    }
                } else {
                    Button {
                        withAnimation {
                            model.previousMonth()
                        }
                    } label: {
                        Label("前月", systemImage: "chevron.backward")
                    }
                    Text("調整月")
                    Button {
                        withAnimation {
                            model.nextMonth()
                        }
                    } label: {
                        Label("後月", systemImage: "chevron.forward")
                    }
                }
            }
            .labelStyle(.iconOnly)
            
            Divider()
                .padding(5)
            
            if monthView {
                DragablePicker {
                    LazyVGrid(columns: monthColumns, spacing: 0) {
                        ForEach(1...model.chineseCalendar.numberOfMonths, id: \.self) { monthIndex in
                            let monthButton = Button {
                                withAnimation {
                                    model.chinendarMonth = monthIndex
                                }
                            } label: {
                                Text(monthLabel(monthIndex: monthIndex, in: model.chineseCalendar))
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                                .buttonBorderShape(.capsule)
                                .frame(minWidth: cellSize * 1.7, minHeight: cellSize)
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
                                    .buttonStyle(.borderless)
                            }
                        }
                    }
                    .animation(.default, value: model.chinendarMonth)
                } prevAction: {
                    model.previousYear()
                } nextAction: {
                    model.nextYear()
                }
            } else {
                DragablePicker {
                    LazyVGrid(columns: dateColumns, spacing: 0) {
                        let fullMoonDay = model.chineseCalendar.dayTicks.majorTicks.count { tick in
                            tick < (model.chineseCalendar.eventInMonth.fullMoon.first?.pos ?? 0.0)
                        }
                        ForEach(1...model.chineseCalendar.numberOfDaysInMonth, id: \.self) { day in
                            let dateText = switch day {
                            case fullMoonDay:
                                Text("\(day)")
                                    .foregroundStyle(.orange)
                            default:
                                Text("\(day)")
                            }
                            let dayButton = Button {
                                withAnimation {
                                    model.chineseDate.day = day
                                }
                            } label: {
                                dateText
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                                .buttonBorderShape(.circle)
                                .frame(minWidth: cellSize, minHeight: cellSize)
                            
                            if model.chineseDate.day == day {
                                dayButton
#if os(visionOS)
                                    .buttonStyle(.automatic)
#else
                                    .buttonStyle(.bordered)
                                    .fontWeight(.bold)
                                    .tint(.blue)
#endif
                            } else {
                                dayButton
                                    .foregroundStyle(.primary)
                                    .buttonStyle(.borderless)
                            }
                        }
                    }
                    .animation(.default, value: model.chineseDate.day)
                    .animation(.default, value: model.chinendarMonth)
                } prevAction: {
                    model.previousMonth()
                } nextAction: {
                    model.nextMonth()
                }
            }
        }
    }
}

struct ChinendarTimePickerPanel: View {
    private var model: TimePickerModel
    private let columns = Array(repeating: GridItem(spacing: 0), count: 6)
    @State private var hourView = false
#if os(visionOS)
    @ScaledMetric(relativeTo: .body) var cellSize: CGFloat = 65
#elseif os(iOS)
    @ScaledMetric(relativeTo: .body) var cellSize: CGFloat = 50
#else
    @ScaledMetric(relativeTo: .body) var cellSize: CGFloat = 30
#endif
    
    init(chineseCalendar: Binding<ChineseCalendar>) {
        self.model = TimePickerModel(chineseCalendar: chineseCalendar)
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation {
                        hourView.toggle()
                    }
                } label: {
                    HStack {
                        Text(hourName(hour: model.hour, largeHour: model.largeHour))
                            .fontWeight(.bold)
                            .lineLimit(1)
                        if hourView {
                            Image(systemName: "chevron.up")
                                .font(.footnote)
                        } else {
                            Image(systemName: "chevron.forward")
                                .font(.footnote)
                        }
                    }
                    .labelStyle(.titleAndIcon)
                    .animation(.default, value: hourView)
                }
                .padding(.horizontal)
                .animation(.default, value: model.hour)
                Spacer()
                if hourView {
                    Button {
                        withAnimation {
                            model.prevDay()
                        }
                    } label: {
                        Label("昨日", systemImage: "chevron.backward")
                    }
                    Text("調整日")
                    Button {
                        withAnimation {
                            model.nextDay()
                        }
                    } label: {
                        Label("翌日", systemImage: "chevron.forward")
                    }
                } else {
                    Button {
                        withAnimation {
                            model.prevHour()
                        }
                    } label: {
                        Label("前時", systemImage: "chevron.backward")
                    }
                    Text("調整時辰")
                    Button {
                        withAnimation {
                            model.nextHour()
                        }
                    } label: {
                        Label("後時", systemImage: "chevron.forward")
                    }
                }
            }
            .labelStyle(.iconOnly)
            
            Divider()
                .padding(5)
    
            if hourView {
                DragablePicker {
                    LazyVGrid(columns: columns) {
                        ForEach(Array(stride(from: 0, to: 24, by: model.largeHour ? 2 : 1)), id: \.self) { hour in
                            let hourButton = Button {
                                withAnimation {
                                    model.hour = hour
                                }
                            } label: {
                                Text(hourName(hour: hour, largeHour: model.largeHour))
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                                .frame(minWidth: cellSize * 2, minHeight: model.largeHour ? cellSize : cellSize * 0.8)
                                .buttonBorderShape(.capsule)
                            if hour == model.hour {
                                hourButton
#if os(visionOS)
                                    .buttonStyle(.automatic)
#else
                                    .buttonStyle(.bordered)
                                    .fontWeight(.bold)
                                    .tint(.blue)
#endif
                            } else {
                                hourButton
                                    .foregroundStyle(.primary)
                                    .buttonStyle(.borderless)
                            }
                        }
                    }
                    .animation(.default, value: model.hour)
#if os(macOS)
                    .fixedSize()
#endif
                } prevAction: {
                    model.prevDay()
                } nextAction: {
                    model.nextDay()
                }
            } else {
                DragablePicker {
                    VStack {
                        LazyVGrid(columns: columns) {
                            ForEach(0..<model.maxQuarterMajor, id: \.self) { quarterMajor in
                                let quarterMajorButton = Button {
                                    withAnimation {
                                        model.quarterMajor = quarterMajor
                                    }
                                } label: {
                                    Text("\(ChineseCalendar.chinese_numbers_localized[quarterMajor])刻")
                                        .lineLimit(1)
                                        .fixedSize()
                                }
                                    .frame(minWidth: cellSize * 1.7, minHeight: cellSize)
                                    .buttonBorderShape(.capsule)
                                if quarterMajor == model.quarterMajor {
                                    quarterMajorButton
#if os(visionOS)
                                        .buttonStyle(.automatic)
#else
                                        .buttonStyle(.bordered)
                                        .fontWeight(.bold)
                                        .tint(.blue)
#endif
                                } else {
                                    quarterMajorButton
                                        .foregroundStyle(.primary)
                                        .buttonStyle(.borderless)
                                }
                            }
                        }
                        .animation(.default, value: model.quarterMinor)
                        .animation(.default, value: model.quarterMajor)
                        Divider()
                            .padding(0)
                        LazyVGrid(columns: columns) {
                            ForEach(0..<model.maxQuarterMinor, id: \.self) { quarterMinor in
                                let quarterMinorButton = Button {
                                    withAnimation {
                                        model.quarterMinor = quarterMinor
                                    }
                                } label: {
                                    Text("\(ChineseCalendar.chinese_numbers_localized[quarterMinor])")
                                        .lineLimit(1)
                                        .fixedSize()
                                }
                                    .frame(minWidth: cellSize, minHeight: cellSize)
                                    .buttonBorderShape(.circle)
                                if quarterMinor == model.quarterMinor {
                                    quarterMinorButton
#if os(visionOS)
                                        .buttonStyle(.automatic)
#else
                                        .buttonStyle(.bordered)
                                        .fontWeight(.bold)
                                        .tint(.blue)
#endif
                                } else {
                                    quarterMinorButton
                                        .foregroundStyle(.primary)
                                        .buttonStyle(.borderless)
                                }
                            }
                        }
                        .animation(.default, value: model.hour)
                        .animation(.default, value: model.quarterMajor)
                        .animation(.default, value: model.quarterMinor)
                    }
                } prevAction: {
                    model.prevHour()
                } nextAction: {
                    model.nextHour()
                }
            }
        }
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
        .popover(isPresented: $presentPicker, arrowEdge: .top) {
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
        .popover(isPresented: $presentPicker, arrowEdge: .top) {
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
