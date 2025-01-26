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
    @State fileprivate var dateManager = DateManager()

    var body: some View {
        TabView(selection: viewModel.binding(\.settings.selection)) {
            VStack(spacing: 10) {
                DatePicker(selection: dateManager.binding(\.time), in: ChineseCalendar.start...ChineseCalendar.end, displayedComponents: [.date]) {
                    Text("DATE")
                }
                .minimumScaleFactor(0.75)
                DatePicker(selection: dateManager.binding(\.time), in: ChineseCalendar.start...ChineseCalendar.end, displayedComponents: [.hourAndMinute]) {
                    Text("TIME")
                }
                .minimumScaleFactor(0.75)
            }
                .tag(WatchSetting.TimeadjSelection.gregorian)

            ChinendarPickerPanel(chineseCalendar: dateManager.binding(\.chineseCalendar))
                .tag(WatchSetting.TimeadjSelection.chinese)
        }
        .tint(.accentColor)
        .tabViewStyle(.page)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    withAnimation {
                        dateManager.isCurrent = true
                    }
                } label: {
                    Label("NOW", systemImage: "clock.arrow.circlepath")
                }
                .disabled(dateManager.isCurrent)
            }
        }
        .navigationTitle("DATETIME_PICKER")
        .onAppear {
            dateManager.setup(viewModel: viewModel)
        }
    }
}

@MainActor
@Observable private final class DateManager: Bindable {
    var viewModel: ViewModel?

    func setup(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var chineseCalendar: ChineseCalendar {
        get {
            viewModel?.chineseCalendar ?? .init()
        } set {
            viewModel?.settings.displayTime = newValue.time
        }
    }

    var time: Date {
        get {
            viewModel?.settings.displayTime ?? viewModel?.chineseCalendar.time ?? .now
        } set {
            if abs(newValue.distance(to: .now)) > 14.4 {
                viewModel?.settings.displayTime = newValue
            }
        }
    }

    var isCurrent: Bool {
        get {
            return viewModel?.settings.displayTime == nil
        } set {
            if newValue {
                viewModel?.settings.displayTime = nil
            } else {
                viewModel?.settings.displayTime = viewModel?.chineseCalendar.time
            }
        }
    }
}

#Preview("Datetime Adjust", traits: .modifier(SampleData())) {
    NavigationStack {
        DateTimeAdjust()
    }
}
