//
//  DateTimeAdjust.swift
//  Chinendar
//
//  Created by Leo Liu on 6/26/23.
//

import SwiftUI
import Observation

@Observable fileprivate class TimeManager {
    var chineseCalendar: ChineseCalendar?
    var watchSetting: WatchSetting?
    
    var time: Date {
        get {
            watchSetting?.displayTime ?? chineseCalendar?.time ?? .now
        } set {
            if abs(newValue.distance(to: .now)) > 1 {
                watchSetting?.displayTime = newValue
            } else {
                watchSetting?.displayTime = nil
            }
            chineseCalendar?.update(time: watchSetting?.displayTime ?? .now)
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
            chineseCalendar?.update(time: watchSetting?.displayTime ?? .now)
        }
    }
    
    func setup(watchSetting: WatchSetting, chineseCalendar: ChineseCalendar) {
        self.watchSetting = watchSetting
        self.chineseCalendar = chineseCalendar
    }
}

struct DateTimeAdjust: View {
    @Environment(\.watchSetting) var watchSetting
    @Environment(\.chineseCalendar) var chineseCalendar
    @State private var timeManager = TimeManager()
    
    var body: some View {
        VStack(spacing: 10) {
            DatePicker(selection: $timeManager.time, in: ChineseCalendar.start...ChineseCalendar.end, displayedComponents: [.date]) {
                Text("日", comment: "Date")
            }
            .animation(.smooth, value: timeManager.time)
            .minimumScaleFactor(0.75)
            DatePicker(selection: $timeManager.time, displayedComponents: [.hourAndMinute]) {
                Text("時", comment: "Time")
            }
            .animation(.smooth, value: timeManager.time)
            .minimumScaleFactor(0.75)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    withAnimation {
                        timeManager.isCurrent = true
                    }
                }) {
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
        .task {
            timeManager.setup(watchSetting: watchSetting, chineseCalendar: chineseCalendar)
        }
        .onDisappear {
            chineseCalendar.update(time: watchSetting.displayTime ?? Date.now)
        }
    }
}


#Preview("Datetime Adjust") {
    DateTimeAdjust()
}
