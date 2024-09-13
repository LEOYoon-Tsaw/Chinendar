//
//  DateTimeAdjust.swift
//  Chinendar
//
//  Created by Leo Liu on 6/26/23.
//

import SwiftUI
import Observation

@MainActor
@Observable private final class TimeManager: Bindable {
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
    
    func setup(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var time: Date {
        get {
            viewModel?.settings.displayTime ?? viewModel?.chineseCalendar.time ?? .now
        } set {
            if abs(newValue.distance(to: .now)) > 1 {
                viewModel?.settings.displayTime = newValue
            } else {
                viewModel?.settings.displayTime = nil
            }
            update()
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
    
    var chinendarMonth: Int {
        get {
            guard let chineseCalendar = viewModel?.chineseCalendar else { return 1 }
            return chineseDate.monthIndex(in: chineseCalendar)
        } set {
            guard let chineseCalendar = viewModel?.chineseCalendar else { return }
            chineseDate.update(monthIndex: newValue, in: chineseCalendar)
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

struct DateTimeAdjust: View {
    @Environment(ViewModel.self) var viewModel
    @State private var timeManager = TimeManager()
    @State private var selectedTab: WatchSetting.TimeadjSelection = .gregorian

    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: 10) {
                DatePicker(selection: timeManager.binding(\.time), in: ChineseCalendar.start...ChineseCalendar.end, displayedComponents: [.date]) {
                    Text("日", comment: "Date")
                }
                .animation(.default, value: timeManager.time)
                .minimumScaleFactor(0.75)
                DatePicker(selection: timeManager.binding(\.time), displayedComponents: [.hourAndMinute]) {
                    Text("時", comment: "Time")
                }
                .animation(.default, value: timeManager.time)
                .minimumScaleFactor(0.75)
            }
                .tag(WatchSetting.TimeadjSelection.gregorian)
            if let chineseCalendar = timeManager.viewModel?.chineseCalendar {
                VStack(spacing: 10) {
                    HStack {
                        Picker("月", selection: timeManager.binding(\.chinendarMonth)) {
                            ForEach(1...chineseCalendar.numberOfMonths, id: \.self) { monthIndex in
                                let dummyChineseDate = ChineseCalendar.ChineseDate(monthIndex: monthIndex, day: 1, in: chineseCalendar)
                                if dummyChineseDate.leap {
                                    Text("閏\(ChineseCalendar.month_chinese_localized[dummyChineseDate.month-1])")
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                } else {
                                    Text(ChineseCalendar.month_chinese_localized[dummyChineseDate.month-1])
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .animation(.default, value: timeManager.chinendarMonth)
                        Picker("日", selection: timeManager.binding(\.chineseDate.day)) {
                            ForEach(1...chineseCalendar.numberOfDaysInMonth, id: \.self) { day in
                                Text("\(ChineseCalendar.day_chinese_localized[day-1])日")
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                        }
                        .animation(.default, value: timeManager.chineseDate)
                    }
                    HStack {
                        Button {
                            timeManager.previousYear()
                        } label: {
                            Label("前年", systemImage: "chevron.backward")
                                .labelStyle(IconCenterStyleLeft())
                        }
                        Button {
                            timeManager.nextYear()
                        } label: {
                            Label("後年", systemImage: "chevron.forward")
                                .labelStyle(IconCenterStyleRight())
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .tag(WatchSetting.TimeadjSelection.chinese)
            }
        }
        .tint(.accentColor)
        .tabViewStyle(.page)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    withAnimation {
                        timeManager.isCurrent = true
                    }
                } label: {
                    Label {
                        Text("今", comment: "Now")
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                .disabled(timeManager.isCurrent)
            }
        }
        .navigationTitle(Text("擇時", comment: "Choose Data & Time"))
        .alert("轉換有誤", isPresented: timeManager.binding(\.presentError)) {
            Button("罷", role: .cancel) {}
        } message: {
            if let chinendarError = timeManager.chinendarError {
                Text("華曆今年無此日：\(chinendarError.leap ? ChineseCalendar.leapLabel_localized : "")\(ChineseCalendar.month_chinese_localized[chinendarError.month-1])\(ChineseCalendar.day_chinese_localized[chinendarError.day-1])日", comment: "Chinendar date not convertible")
            } else {
                Text("")
            }
        }
        .task(id: selectedTab) {
            viewModel.settings.selection = selectedTab
        }
        .task {
            timeManager.setup(viewModel: viewModel)
            selectedTab = viewModel.settings.selection
        }
        .onDisappear {
            viewModel.updateChineseCalendar()
        }
    }
}

#Preview("Datetime Adjust", traits: .modifier(SampleData())) {
    DateTimeAdjust()
}
