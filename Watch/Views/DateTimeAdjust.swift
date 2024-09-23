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
    
    func setup(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var chineseCalendar: ChineseCalendar {
        get {
            viewModel?.chineseCalendar ?? .init()
        } set {
            viewModel?.settings.displayTime = newValue.time
            update()
        }
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

            ChinendarPickerPanel(chineseCalendar: timeManager.binding(\.chineseCalendar))
                .tag(WatchSetting.TimeadjSelection.chinese)
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
