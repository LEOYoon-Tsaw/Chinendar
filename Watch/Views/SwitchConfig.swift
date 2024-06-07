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
    @Environment(CalendarConfigure.self) var calendarConfigure
    @Environment(LocationManager.self) var locationManager
    @Environment(ChineseCalendar.self) var chineseCalendar
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
                            let calConfig = CalendarConfigure(from: config.code!)
                            let calendar = ChineseCalendar(time: chineseCalendar.time, timezone: calConfig.effectiveTimezone,
                                                           location: calConfig.location(locationManager: locationManager),
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

                        let nameLabel = switch (config.name! == AppInfo.defaultName, config.name! == calendarConfigure.name) {
                        case (true, true):
                            Label("常用", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        case (true, false):
                            Label("常用", systemImage: "circle")
                                .foregroundStyle(Color.primary)
                        case (false, true):
                            Label(config.name!, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        case (false, false):
                            Label(config.name!, systemImage: "circle")
                                .foregroundStyle(Color.primary)
                        }

                        Button {
                            calendarConfigure.update(from: config.code!, newName: config.name!)
                            chineseCalendar.update(timezone: calendarConfigure.effectiveTimezone,
                                                   location: calendarConfigure.location(locationManager: locationManager),
                                                   globalMonth: calendarConfigure.globalMonth, apparentTime: calendarConfigure.apparentTime,
                                                   largeHour: calendarConfigure.largeHour)
                        } label: {
                            VStack {
                                nameLabel
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                dateLabel
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .deleteDisabled(config.name! == calendarConfigure.name)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        target = configs[index]
                        deleteAlert = true
                    }
                }
            } else {
                Text("混沌初開，萬物未成")
            }
        }
        .alert((target != nil && !target!.isNil) ? (NSLocalizedString("刪：", comment: "Confirm to delete theme message") + target!.name!) : NSLocalizedString("刪不得", comment: "Cannot delete theme"), isPresented: $deleteAlert) {
            Button(NSLocalizedString("容吾三思", comment: "Cancel adding Settings"), role: .cancel) { target = nil }
            Button(NSLocalizedString("吾意已決", comment: "Confirm Resetting Settings"), role: .destructive) {
                if let target = target {
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
        .alert("怪哉", isPresented: $errorAlert) {
            Button("罷", role: .cancel) {}
        } message: {
            Text(errorMsg)
        }
    }
}

#Preview("SwitchConfig") {
    let chineseCalendar = ChineseCalendar(compact: true)
    let locationManager = LocationManager()
    let calendarConfigure = CalendarConfigure()

    return SwitchConfig()
        .modelContainer(DataSchema.container)
        .environment(chineseCalendar)
        .environment(locationManager)
        .environment(calendarConfigure)
}
