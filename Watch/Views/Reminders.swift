//
//  Reminders.swift
//  Chinendar
//
//  Created by Leo Liu on 12/30/24.
//

import SwiftUI
import SwiftData

struct ReminderGroup: View {
    @Binding var reminderList: ReminderList
    let chineseCalendar: ChineseCalendar
    @State var showSelectionDeletion = false
    @State var deletionIndex = IndexSet()

    var body: some View {
        Form {
            Section {
                Toggle("ENABLED", isOn: $reminderList.enabled)
            } header: {
                Text("GENERAL_REMINDER_INFO")
            }

            Section {
                ForEach($reminderList.reminders) { $reminder in
                    Toggle(isOn: $reminder.enabled) {
                        HStack {
                            Text(reminder.name)
                                .lineLimit(2)
                                .foregroundStyle(reminder.enabled ? .primary : .secondary)
                            Spacer()
                            if let notifyTime = reminder.nextReminder(in: chineseCalendar) {
                                Text(notifyTime, format: .offset(to: .now, allowedFields: [.day]))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    deletionIndex = indexSet
                    showSelectionDeletion = true
                }
            } header: {
                Text("REMINDERS:\(reminderList.reminders.count)ITEMS")
            }
        }
        .alert("DELETE\(deletionIndex.count)ITEMS", isPresented: $showSelectionDeletion) {
            Button("CANCEL", role: .cancel) {
                deletionIndex = []
            }
            Button("CONFIRM", role: .destructive) {
                reminderList.reminders.remove(atOffsets: deletionIndex)
                deletionIndex = []
            }
        }
        .navigationTitle(reminderList.name == AppInfo.defaultName ? String(localized: "DEFAULT_NAME") : reminderList.name)
    }
}

struct RemindersSetting: View {
    @Query(sort: \RemindersData.modifiedDate, order: .reverse) private var dataStack: [RemindersData]
    @Environment(\.modelContext) private var modelContext
    @Environment(ViewModel.self) var viewModel
    @State private var errorMsg: Error?
    @State private var notificationEnabled: Bool = false
    let notificationManager = NotificationManager.shared

    private var hasError: Binding<Bool> {
        Binding<Bool>(get: { errorMsg != nil }, set: { if !$0 { errorMsg = nil } })
    }

    var body: some View {
        List {
            if !notificationEnabled {
                Section {
                    Button("ENABLE_NOTIFICATIONS") {
                        Task {
                            do {
                                notificationEnabled = try await notificationManager.requestAuthorization()
                                await notificationManager.addNotifications(chineseCalendar: viewModel.chineseCalendar)
                            } catch {
                                errorMsg = error
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            Section {
                ForEach(dataStack) { data in
                    if let list = data.list {
                        NavigationLink(value: data) {
                            let listName = if list.name == AppInfo.defaultName {
                                String(localized: LocalizedStringResource("DEFAULT_NAME"))
                            } else {
                                list.name
                            }
                            HStack {
                                Text(listName)
                                    .lineLimit(2)
                                    .foregroundStyle(list.enabled ? .primary : .secondary)
                                Spacer()
                                Text("\(list.reminders.count)ITEMS")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .alert("ERROR", isPresented: hasError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMsg?.localizedDescription ?? "")
        }
        .task {
            notificationEnabled = await notificationManager.enabled
        }
        .onAppear {
            initializeRemindersData()
        }
        .navigationDestination(for: RemindersData.self) { reminderData in
            if let index = dataStack.firstIndex(where: { $0.id == reminderData.id }) {
                let listBinding = Binding(get: {
                    dataStack[index].list!
                }, set: {
                    dataStack[index].list = $0
                })
                ReminderGroup(reminderList: listBinding, chineseCalendar: viewModel.chineseCalendar)
            }
        }
        .navigationTitle("REMINDERS_LIST")
    }

    func initializeRemindersData() {
        if dataStack.isEmpty {
            let data = RemindersData(.defaultValue)
            modelContext.insert(data)
        } else {
            let defaultData = dataStack.filter {
                $0.list?.name == AppInfo.defaultName &&
                $0.modifiedDate != nil
            }.sorted {
                $0.modifiedDate! > $1.modifiedDate!
            }
            if defaultData.count > 1 {
                for data in defaultData[1...] {
                    modelContext.delete(data)
                }
            }
            for data in dataStack.filter(\.isNil) {
                modelContext.delete(data)
            }
        }
    }
}

#Preview("Reminders", traits: .modifier(SampleData())) {
    NavigationStack {
        RemindersSetting()
    }
}
