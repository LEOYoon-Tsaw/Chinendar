//
//  DateTimeAdjust.swift
//  Chinendar
//
//  Created by Leo Liu on 6/26/23.
//

import SwiftUI
import Observation

struct DateTimeAdjust: View {
    @Environment(ViewModel.self) var viewModel
    @State private var displayTime: Date = .now
    @State private var current = true

    var body: some View {
        let chineseCalendar = Binding<ChineseCalendar>(get: {
            var calendar = viewModel.chineseCalendar
            calendar.update(time: displayTime)
            return calendar
        }, set: {
            displayTime = $0.time
        })

        TabView(selection: viewModel.binding(\.settings.selection)) {
            VStack(spacing: 10) {
                DatePicker(selection: $displayTime, in: ChineseCalendar.start...ChineseCalendar.end, displayedComponents: [.date]) {
                    Text("DATE")
                }
                .minimumScaleFactor(0.75)
                DatePicker(selection: $displayTime, in: ChineseCalendar.start...ChineseCalendar.end, displayedComponents: [.hourAndMinute]) {
                    Text("TIME")
                }
                .minimumScaleFactor(0.75)
            }
                .tag(WatchSetting.TimeadjSelection.gregorian)

            ChinendarPickerPanel(chineseCalendar: chineseCalendar)
                .tag(WatchSetting.TimeadjSelection.chinese)
        }
        .tint(.accentColor)
        .tabViewStyle(.page)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    withAnimation {
                        current = true
                        displayTime = .now
                    }
                } label: {
                    Label {
                        Text("NOW")
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                .disabled(current)
            }
        }
        .navigationTitle("DATETIME_PICKER")
        .onChange(of: displayTime, initial: false) {
            if abs(displayTime.timeIntervalSinceNow) > 14.4 {
                current = false
            }
        }
        .onChange(of: viewModel.chineseCalendar.time, initial: true) {
            current = viewModel.settings.displayTime == nil
            if current {
                displayTime = viewModel.chineseCalendar.time
            } else {
                displayTime = viewModel.settings.displayTime!
            }
        }
        .onDisappear {
            viewModel.settings.displayTime = if current {
                nil
            } else {
                displayTime
            }
            viewModel.updateChineseCalendar()
        }
    }
}

#Preview("Datetime Adjust", traits: .modifier(SampleData())) {
    NavigationStack {
        DateTimeAdjust()
    }
}
