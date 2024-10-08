//
//  SwitchConfig.swift
//  Chinendar Watch
//
//  Created by Leo Liu on 3/30/24.
//

import SwiftUI
import SwiftData

struct SwitchConfig: View {
    @Query(sort: \ConfigData.modifiedDate, order: .reverse) private var configs: [ConfigData]
    @Environment(ViewModel.self) var viewModel
    @Environment(\.modelContext) var modelContext
    @State private var deleteAlert = false
    @State private var errorAlert = false
    @State private var errorMsg = ""
    @State private var target: ConfigData?

    var body: some View {
        List {
            if configs.count > 0 {
                ForEach(configs, id: \.self) { config in
                    if !config.isNil {
                        let chineseDate: String = {
                            var calConfig = CalendarConfigure()
                            calConfig.update(from: config.code!)
                            let calendar = ChineseCalendar(time: viewModel.chineseCalendar.time,
                                                           timezone: calConfig.effectiveTimezone,
                                                           location: viewModel.location,
                                                           globalMonth: calConfig.globalMonth, apparentTime: calConfig.apparentTime,
                                                           largeHour: calConfig.largeHour)
                            var displayText = [String]()
                            displayText.append(calendar.dateString)
                            let holidays = calendar.holidays
                            displayText.append(contentsOf: holidays[..<min(holidays.count, 1)])
                            displayText.append(calendar.hourString + calendar.quarterString)
                            return displayText.joined(separator: " ")
                        }()

                        let dateLabel = Text(String(chineseDate.reversed()))
                            .foregroundStyle(.secondary)
                            .font(.caption)

                        let nameLabel = switch (config.name! == AppInfo.defaultName, config.name! == viewModel.config.name) {
                        case (true, true):
                            Label("DEFAULT_NAME", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        case (true, false):
                            Label("DEFAULT_NAME", systemImage: "circle")
                                .foregroundStyle(Color.primary)
                        case (false, true):
                            Label(config.name!, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        case (false, false):
                            Label(config.name!, systemImage: "circle")
                                .foregroundStyle(Color.primary)
                        }

                        Button {
                            viewModel.config.update(from: config.code!, newName: config.name!)
                            viewModel.updateChineseCalendar()
                        } label: {
                            VStack {
                                nameLabel
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                dateLabel
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .deleteDisabled(config.name! == viewModel.config.name)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        target = configs[index]
                        deleteAlert = true
                    }
                }
            } else {
                Text("EMPTY_LIST")
            }
        }
        .alert((target != nil && !target!.isNil) ? LocalizedStringKey("DELETE:\(target!.name!)") : LocalizedStringKey("DELETE_FAILED"), isPresented: $deleteAlert) {
            Button("CANCEL", role: .cancel) { target = nil }
            Button("CONFIRM", role: .destructive) {
                if let target {
                    modelContext.delete(target)
                    do {
                        try modelContext.save()
                    } catch {
                        errorMsg = error.localizedDescription
                        errorAlert = true
                    }
                }
            }
        }
        .alert("ERROR", isPresented: $errorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMsg)
        }
        .navigationTitle("CALENDAR_LIST")
    }
}

#Preview("SwitchConfig", traits: .modifier(SampleData())) {
    SwitchConfig()
}
