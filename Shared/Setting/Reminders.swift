//
//  Reminders.swift
//  Chinendar
//
//  Created by Leo Liu on 12/25/24.
//

import SwiftUI
import SwiftData
@preconcurrency import UserNotifications

private enum TargetType: CaseIterable {
    case chinendar, event
}
private enum RemindType: CaseIterable {
    case exact, timeInDay, quarterOffset
}

struct ReminderListBulkEdit: View {
    @Binding var show: Bool
    @Binding var reminderList: ReminderList
    let chineseCalendar: ChineseCalendar

    @State private var dayOffset: Int = 0
    @State private var timeInDay: ChineseCalendar.ChineseTime = .init()
    @State private var quarterOffset: Int = 0
    @State private var remindType: RemindType = .exact
    @State private var showConfirmation = false

    var cancelButton: some View {
        Button {
            show = false
        } label: {
            Text("CANCEL")
        }
    }

    var listName: String {
        reminderList.name == AppInfo.defaultName ? String(localized: "DEFAULT_NAME") : reminderList.name
    }

    var timeInDayCalendar: Binding<ChineseCalendar> {
        Binding<ChineseCalendar>(get: {
            var calendar = chineseCalendar
            if let newDate = calendar.find(chineseTime: timeInDay) {
                calendar.update(time: newDate)
            }
            return calendar
        }, set: {
            timeInDay = $0.chineseTime
        })
    }

    var proposedRemindType: Reminder.RemindTime {
        switch remindType {
        case .exact:
                .exact
        case .quarterOffset:
                .quarterOffset(-quarterOffset)
        case .timeInDay:
                .timeInDay(-dayOffset, timeInDay)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("REMIND_TYPE", selection: $remindType) {
                        ForEach(RemindType.allCases, id: \.self) { type in
                            switch type {
                            case .exact:
                                Text("REMIND_EXACT")
                            case .timeInDay:
                                Text("REMIND_SPECIFIC_TIME")
                            case .quarterOffset:
                                Text("REMIND_QUARTER_OFFSET")
                            }
                        }
                    }
                    switch remindType {
                    case .exact:
                        EmptyView()
                    case .timeInDay:
                        HStack {
                            Stepper("REMINDER_DAY_OFFSET", value: $dayOffset, in: 0...15, step: 1)
                            Text("\(dayOffset)DAYS")
                        }
                        HStack {
                            Text("TIME")
                                .lineLimit(1)
                            ChinendarTimePicker(chineseCalendar: timeInDayCalendar)
                                .buttonStyle(.bordered)
                        }
                    case .quarterOffset:
                        HStack {
                            Stepper("REMINDER_QUARTER_OFFSET", value: $quarterOffset, in: 0...100, step: 1)
                            Text("\(quarterOffset)QUARTERS")
                        }
                    }
                } header: {
                    Text("REMIND_TIME")
                }

                Section {
                    Button {
                        showConfirmation = true
                    } label: {
                        Label("APPLY_TO_ALL", systemImage: "checkmark.rectangle.stack.fill")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
#if os(macOS)
            .formStyle(.grouped)
#else
            .navigationBarTitleDisplayMode(.inline)
#endif
            .alert("APPLY_TO_ALL", isPresented: $showConfirmation) {
                Button("CANCEL", role: .cancel) {}
                Button("CONFIRM", role: .destructive) {
                    for index in 0..<reminderList.reminders.count {
                        reminderList.reminders[index].remindTime = proposedRemindType
                    }
                    show = false
                }
            } message: {
                Text("APPLY_TO\(reminderList.reminders.count)ITEMS_IN\(listName)")
            }
            .toolbar {
                cancelButton
            }
            .navigationTitle("BULK_EDIT")
        }
    }
}

struct ReminderListSelector: View {
    @Query(sort: \RemindersData.modifiedDate, order: .reverse) private var dataStack: [RemindersData]
    @Environment(\.modelContext) private var modelContext
    @Binding var show: Bool
    let reminderIDs: Set<UUID>
    @State private var showConfirmation = false
    @State private var showNewConfirmation = false
    @State private var targetGroupID: PersistentIdentifier?
    @State private var newName: String = ""

    var indices: (list: Int?, reminders: [Int]) {
        for i in 0..<dataStack.count where !dataStack[i].isNil {
            var indices: [Int] = []
            for j in 0..<dataStack[i].list!.reminders.count {
                if reminderIDs.contains(dataStack[i].list!.reminders[j].id) {
                    indices.append(j)
                }
            }
            if !indices.isEmpty {
                return (i, indices.sorted(by: >))
            }
        }
        return (list: nil, reminders: [])
    }

    var cancelButton: some View {
        Button {
            show = false
        } label: {
            Text("CANCEL")
        }
    }

    @ViewBuilder var selectionPanel: some View {
        ForEach(dataStack) { group in
            if let data = group.list {
                Button {
                    targetGroupID = group.persistentModelID
                    showConfirmation = true
                } label: {
                    let listName = if data.name == AppInfo.defaultName {
                        String(localized: "DEFAULT_NAME")
                    } else {
                        data.name
                    }
                    HStack {
                        Text(listName)
                            .lineLimit(1)
                        Spacer()
                        Text("\(data.reminders.count)ITEMS")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(indices.list != nil ? group.persistentModelID == dataStack[indices.list!].persistentModelID : false)
            }
        }
        .alert("MOVE_TO", isPresented: $showConfirmation) {
            Button("CANCEL", role: .cancel) {
                targetGroupID = nil
            }
            Button("CONFIRM", role: .destructive) {
                if let group = dataStack.first(where: { $0.persistentModelID == targetGroupID }) {
                    let movedReminders = move()
                    group.list?.reminders.append(contentsOf: movedReminders.reversed())
                    show = false
                }
            }
        } message: {
            if let group = dataStack.first(where: { $0.persistentModelID == targetGroupID }), let data = group.list {
                Text("MOVE:\(reminderIDs.count)TO:\(data.name)")
            } else {
                Text("ERROR")
            }
        }
        Button {
            newName = validName(String(localized: "UNNAMED"))
            showNewConfirmation = true
        } label: {
            Label("CREATE_NEW", systemImage: "plus")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .alert("MOVE_TO", isPresented: $showNewConfirmation) {
            TextField("NEW_NAME", text: $newName)
                .labelsHidden()
            Button("CANCEL", role: .cancel) {
                targetGroupID = nil
            }
            Button("CONFIRM", role: .destructive) {
                let movedReminders = move()
                if !movedReminders.isEmpty {
                    let newList = ReminderList(name: newName, enabled: false, reminders: movedReminders)
                    let newData = RemindersData(newList)
                    modelContext.insert(newData)
                }
                show = false
            }
        } message: {
            Text("MOVE:\(reminderIDs.count)TO:\(newName)")
        }
    }

    var body: some View {
#if os(macOS)
        let content = Form {
            selectionPanel
                .buttonStyle(.plain)
        }
        .formStyle(.grouped)
#else
        let content = List {
            selectionPanel
        }
            .navigationBarTitleDisplayMode(.inline)
#endif
        NavigationStack {
            content
                .toolbar {
                    cancelButton
                }
                .navigationTitle("MOVE_TO")
        }
    }

    func move() -> [Reminder] {
        var movedReminders: [Reminder] = []
        for index in indices.reminders where indices.list != nil && dataStack[indices.list!].list != nil {
            movedReminders.append(dataStack[indices.list!].list!.reminders.remove(at: index))
        }
        return movedReminders.reversed()
    }

    func validateName(_ name: String) -> Bool {
        if name.count > 0 {
            let currentNames = dataStack.compactMap(\.list?.name)
            return currentNames.contains(name)
        } else {
            return false
        }
    }

    func validName(_ name: String) -> String {
        var (baseName, i) = reverseNumberedName(name)
        while validateName(numberedName(baseName, number: i)) {
            i += 1
        }
        return numberedName(baseName, number: i)
    }
}

@MainActor
private final class ReminderModel: Bindable {
    var reminder: Binding<Reminder>
    var chineseCalendar: ChineseCalendar
    var chineseDate: ChineseCalendar.ChineseDateTime {
        didSet {
            reminder.wrappedValue.targetTime = .chinendar(chineseDate)
        }
    }
    var solarTerm: Int {
        didSet {
            reminder.wrappedValue.targetTime = .event(.solarTerm(solarTerm))
        }
    }
    var dayOffset: Int {
        didSet {
            reminder.wrappedValue.remindTime = .timeInDay(-dayOffset, timeInDay)
        }
    }
    var timeInDay: ChineseCalendar.ChineseTime {
        didSet {
            reminder.wrappedValue.remindTime = .timeInDay(-dayOffset, timeInDay)
        }
    }
    var quarterOffset: Int {
        didSet {
            reminder.wrappedValue.remindTime = .quarterOffset(-quarterOffset)
        }
    }

    var targetType: TargetType {
        get {
            switch reminder.wrappedValue.targetTime {
            case .chinendar:
                TargetType.chinendar
            case .event:
                TargetType.event
            }
        } set {
            switch newValue {
            case .chinendar:
                reminder.wrappedValue.targetTime = .chinendar(chineseDate)
            case .event:
                reminder.wrappedValue.targetTime = .event(.solarTerm(solarTerm))
            }
        }
    }

    var remindType: RemindType {
        get {
            switch reminder.wrappedValue.remindTime {
            case .exact:
                RemindType.exact
            case .timeInDay:
                RemindType.timeInDay
            case .quarterOffset:
                RemindType.quarterOffset
            }
        } set {
            switch newValue {
            case .exact:
                reminder.wrappedValue.remindTime = .exact
            case .timeInDay:
                reminder.wrappedValue.remindTime = .timeInDay(-dayOffset, timeInDay)
            case .quarterOffset:
                reminder.wrappedValue.remindTime = .quarterOffset(-quarterOffset)
            }
        }
    }

    var targetCalendar: ChineseCalendar {
        get {
            var calendar = chineseCalendar
            if let newDate = calendar.findNext(chineseDateTime: chineseDate) {
                calendar.update(time: newDate)
            }
            return calendar
        } set {
            chineseDate = newValue.chineseDateTime
        }
    }

    var timeInDayCalendar: ChineseCalendar {
        get {
            var calendar = chineseCalendar
            if let newDate = calendar.find(chineseTime: timeInDay) {
                calendar.update(time: newDate)
            }
            return calendar
        } set {
            timeInDay = newValue.chineseTime
        }
    }

    init(reminder: Binding<Reminder>, chineseCalendar: ChineseCalendar) {
        switch reminder.wrappedValue.targetTime {
        case .chinendar(let date):
            chineseDate = date
            solarTerm = 0
        case .event(.solarTerm(let term)):
            chineseDate = chineseCalendar.chineseDateTime
            solarTerm = term
        }

        switch reminder.wrappedValue.remindTime {
        case .exact:
            self.dayOffset = 0
            self.timeInDay = .init()
            self.quarterOffset = 0
        case .timeInDay(let dayOffset, let time):
            self.dayOffset = -dayOffset
            self.timeInDay = time
            self.quarterOffset = 0
        case .quarterOffset(let quarterOffset):
            self.dayOffset = 0
            self.timeInDay = .init()
            self.quarterOffset = -quarterOffset
        }

        self.reminder = reminder
        self.chineseCalendar = chineseCalendar
    }
}

struct ReminderConfig: View {
    @Binding var reminder: Reminder
    @Binding var reminderList: ReminderList
    let chineseCalendar: ChineseCalendar
    @Environment(ViewModel.self) var viewModel
    @State var showDeletion = false
    @State var showMove = false
    private let reminderModel: ReminderModel

    init(reminder: Binding<Reminder>, reminderList: Binding<ReminderList>, chineseCalendar: ChineseCalendar) {
        self._reminder = reminder
        self._reminderList = reminderList
        self.chineseCalendar = chineseCalendar
        self.reminderModel = ReminderModel(reminder: reminder, chineseCalendar: chineseCalendar)
    }

    var deleteButton: some View {
        Button(role: .destructive) {
            showDeletion = true
        } label: {
            Label("DELETE", systemImage: "trash")
        }
        .tint(.red)
    }

    var moveButton: some View {
        Button {
            showMove = true
        } label: {
            Label("MOVE_TO", systemImage: "folder")
        }
    }

    var body: some View {
#if os(macOS)
        let backButton = ToolbarItem(placement: .navigation) {
            Button {
                if !viewModel.settings.path.isEmpty {
                    viewModel.settings.path.removeLast()
                }
            } label: {
                Image(systemName: "chevron.left")
            }
        }
#endif

        Form {
            Section {
                TextField("REMINDER_NAME", text: $reminder.name)
                Toggle("ENABLED", isOn: $reminder.enabled)
            } header: {
                Text("GENERAL_REMINDER_INFO")
            }

            Section {
                Picker("EVENT_TYPE", selection: reminderModel.binding(\.targetType)) {
                    ForEach(TargetType.allCases, id: \.self) { type in
                        switch type {
                        case .chinendar:
                            Text("CHINENDAR_DATETIME")
                        case .event:
                            Text("ST")
                        }
                    }
                }
                switch reminderModel.targetType {
                case .chinendar:
                    HStack {
                        Text("DATE")
                            .lineLimit(1)
                        ChinendarDatePicker(chineseCalendar: reminderModel.binding(\.targetCalendar))
                        Spacer(minLength: 0)
                            .frame(idealWidth: 10, maxWidth: 20)
                        Text("TIME")
                            .lineLimit(1)
                        ChinendarTimePicker(chineseCalendar: reminderModel.binding(\.targetCalendar))
                    }
                    .buttonStyle(.bordered)
                case .event:
                    Picker("ST", selection: reminderModel.binding(\.solarTerm)) {
                        ForEach(0..<24, id: \.self) { solarterm in
                            Text(ChineseCalendar.solarTermName(for: solarterm)!)
                        }
                    }
                }
            } header: {
                if let nextTime = reminder.nextEvent(in: chineseCalendar) {
                    Text("EVENT_TIME: ") + Text(nextTime, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                } else {
                    Text("EVENT_TIME")
                }
            }

            Section {
                Picker("REMIND_TYPE", selection: reminderModel.binding(\.remindType)) {
                    ForEach(RemindType.allCases, id: \.self) { type in
                        switch type {
                        case .exact:
                            Text("REMIND_EXACT")
                        case .timeInDay:
                            Text("REMIND_SPECIFIC_TIME")
                        case .quarterOffset:
                            Text("REMIND_QUARTER_OFFSET")
                        }
                    }
                }
                switch reminderModel.remindType {
                case .exact:
                    EmptyView()
                case .timeInDay:
                    HStack {
                        Stepper("REMINDER_DAY_OFFSET", value: reminderModel.binding(\.dayOffset), in: 0...15, step: 1)
                        Text("\(reminderModel.dayOffset)DAYS")
                    }
                    HStack {
                        Text("TIME")
                            .lineLimit(1)
                        ChinendarTimePicker(chineseCalendar: reminderModel.binding(\.timeInDayCalendar))
                            .buttonStyle(.bordered)
                    }
                case .quarterOffset:
                    HStack {
                        Stepper("REMINDER_QUARTER_OFFSET", value: reminderModel.binding(\.quarterOffset), in: 0...100, step: 1)
                        Text("\(reminderModel.quarterOffset)QUARTERS")
                    }
                }
            } header: {
                if let nextTime = reminder.nextReminder(in: chineseCalendar) {
                    Text("REMIND_TIME: ") + Text(nextTime, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                } else {
                    Text("REMIND_TIME")
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showMove) {
            ReminderListSelector(show: $showMove, reminderIDs: [reminder.id])
                .presentationSizing(.form)
        }
        .alert("DELETE:\(reminder.name)", isPresented: $showDeletion) {
            Button("CANCEL", role: .cancel) {}
            Button("CONFIRM", role: .destructive) {
                if let index = reminderList.reminders.firstIndex(where: { $0.id == reminder.id }) {
                    reminderList.reminders.remove(at: index)
                    if !viewModel.settings.path.isEmpty {
                        viewModel.settings.path.removeLast()
                    }
                }
            }
        }
        .toolbar {
#if os(macOS)
            backButton
#endif
            ToolbarItem(placement: .primaryAction) {
#if os(macOS) || os(visionOS)
                HStack {
                    moveButton
                    deleteButton
                }
#else
                Menu {
                    moveButton
                    deleteButton
                } label: {
                    Label("MANAGE_LIST", systemImage: "ellipsis.circle")
                }
#endif
            }
        }
        .navigationTitle(reminder.name)
    }
}

struct ReminderGroup: View {
    var remindersData: RemindersData
    let chineseCalendar: ChineseCalendar
    @Environment(\.modelContext) private var modelContext
    @Environment(ViewModel.self) var viewModel
#if os(iOS) || os(visionOS)
    @Environment(\.editMode) var editMode
#else
    @State var editing = false
#endif
    @State var selectedReminder: Set<UUID> = []
    @State var showGroupDeletion = false
    @State var showSelectionDeletion = false
    @State var deletionIndex = IndexSet()
    @State var showSelectionMove = false
    @State var showBulkEdit = false

    var listName: String {
        remindersData.list?.name == AppInfo.defaultName ? String(localized: "DEFAULT_NAME") : remindersData.list!.name
    }

    var editButton: some View {
#if os(iOS) || os(visionOS)
        EditButton()
#else
        Button {
            editing.toggle()
        } label: {
            if editing {
                Label("DONE_EDITING", systemImage: "list.bullet.circle.fill")
            } else {
                Label("EDIT", systemImage: "list.bullet.circle")
            }
        }
#endif
    }

    var newButton: some View {
        Button {
            let newName = String(localized: "UNNAMED")
            let newReminder = Reminder(name: validName(newName), enabled: false, targetTime: .chinendar(chineseCalendar.chineseDateTime), remindTime: .exact)
            remindersData.list?.reminders.insert(newReminder, at: 0)
        } label: {
            Label("CREATE_NEW", systemImage: "plus")
        }
    }

    var moveSelectedButton: some View {
        Button {
            showSelectionMove = true
        } label: {
            Label("MOVE_TO", systemImage: "folder")
        }
        .disabled(selectedReminder.isEmpty)
    }

    var bulkEditButton: some View {
        Button {
            showBulkEdit = true
        } label: {
            Label("BULK_EDIT", systemImage: "checkmark.rectangle.stack")
        }
    }

    var deleteGroupButton: some View {
        Button(role: .destructive) {
            showGroupDeletion = true
        } label: {
            Label("DELETE_GROUP", systemImage: "trash")
        }
        .tint(.red)
    }

    var deleteSelectedButton: some View {
        Button(role: .destructive) {
            deletionIndex = IndexSet(remindersData.list!.reminders.enumerated().filter {
                selectedReminder.contains($0.1.id) }.map(\.offset))
            showSelectionDeletion = true
        } label: {
            Label("DELETE_SELECTED", systemImage: "trash")
        }
        .disabled(selectedReminder.isEmpty)
        .tint(.red)
    }

    var body: some View {
#if os(iOS) || os(visionOS)
        let editing = editMode?.wrappedValue.isEditing ?? false
#else
        let backButton = ToolbarItem(placement: .navigation) {
            Button {
                if !viewModel.settings.path.isEmpty {
                    viewModel.settings.path.removeLast()
                }
            } label: {
                Image(systemName: "chevron.left")
            }
        }
#endif

        if editing {
            let selectionPanel = List(selection: $selectedReminder) {
                if remindersData.list!.reminders.isEmpty {
                    Text("EMPTY_LIST")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(remindersData.list!.reminders) { reminder in
                        HStack {
                            Text(reminder.name)
                                .lineLimit(1)
                                .foregroundStyle(reminder.enabled ? .primary : .secondary)
                            Spacer()
                            if let notifyTime = reminder.nextReminder(in: chineseCalendar) {
                                Text(notifyTime, format: .offset(to: .now, allowedFields: [.day]))
                                    .foregroundStyle(.secondary)
                            }
                        }
#if os(macOS)
                        .padding(.vertical, 5)
#endif
                    }
                    .onMove { from, to in
                        remindersData.list?.reminders.move(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { index in
                        deletionIndex = index
                        showSelectionDeletion = true
                    }
                }
            }
                .toolbar {
    #if os(macOS)
                    backButton
    #endif
                    ToolbarItem(placement: .primaryAction) {
                        HStack {
                            editButton
    #if os(macOS) || os(visionOS)
                            moveSelectedButton
                            deleteSelectedButton
    #else
                            Menu {
                                moveSelectedButton
                                deleteSelectedButton
                            } label: {
                                Label("MANAGE_LIST", systemImage: "ellipsis.circle")
                            }
    #endif
                        }
                    }
                }
                .sheet(isPresented: $showSelectionMove) {
                    ReminderListSelector(show: $showSelectionMove, reminderIDs: selectedReminder)
                        .presentationSizing(.form)
                }
                .alert("DELETE\(deletionIndex.count)ITEMS", isPresented: $showSelectionDeletion) {
                    Button("CANCEL", role: .cancel) {
                        deletionIndex = []
                    }
                    Button("CONFIRM", role: .destructive) {
                        remindersData.list?.reminders.remove(atOffsets: deletionIndex)
                        deletionIndex = []
                    }
                }
                .navigationTitle(listName)
#if os(macOS)
            Form {
                selectionPanel
            }
            .formStyle(.grouped)
#else
            selectionPanel
#endif
        } else {
            Form {
                Section {
                    if remindersData.list?.name == AppInfo.defaultName {
                        Text("DEFAULT_NAME")
                    } else {
                        let reminderListNameBinding = Binding(get: { remindersData.list!.name }, set: { remindersData.list?.name = $0})
                        TextField("REMINDER_NAME", text: reminderListNameBinding)
                    }
                    let reminderListEnabledBinding = Binding(get: { remindersData.list!.enabled }, set: { remindersData.list?.enabled = $0 })
                    Toggle("ENABLED", isOn: reminderListEnabledBinding)
                } header: {
                    Text("GENERAL_REMINDER_INFO")
                }

                if remindersData.list!.reminders.isEmpty {
                    Text("EMPTY_LIST")
                        .foregroundStyle(.secondary)
                } else {
                    Section {
                        ForEach(remindersData.list!.reminders) { reminder in
                            NavigationLink(value: reminder) {
                                HStack {
                                    Text(reminder.name)
                                        .lineLimit(1)
                                        .foregroundStyle(reminder.enabled ? .primary : .secondary)
                                    Spacer()
                                    if let notifyTime = reminder.nextReminder(in: chineseCalendar) {
                                        Text(notifyTime, format: .offset(to: .now, allowedFields: [.day]))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("REMINDERS:\(remindersData.list!.reminders.count)ITEMS")
                    }
                }

            }
            .formStyle(.grouped)
            .alert("DELETE:\(listName)", isPresented: $showGroupDeletion) {
                Button("CANCEL", role: .cancel) {}
                Button("CONFIRM", role: .destructive) {
                    modelContext.delete(remindersData)
                    if !viewModel.settings.path.isEmpty {
                        viewModel.settings.path.removeLast()
                    }
                }
            } message: {
                Text("DELETE\(remindersData.list!.reminders.count)ITEMS")
            }
            .sheet(isPresented: $showBulkEdit) {
                let reminderListBinding = Binding(get: {
                    remindersData.list!
                }, set: {
                    remindersData.list = $0
                })
                ReminderListBulkEdit(show: $showBulkEdit, reminderList: reminderListBinding, chineseCalendar: chineseCalendar)
                    .presentationSizing(.form)
            }
            .navigationDestination(for: Reminder.self) { reminder in
                configView(reminder: reminder)
            }
            .toolbar {
#if os(macOS)
                backButton
#endif
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        editButton
#if os(macOS) || os(visionOS)
                        newButton
                        bulkEditButton
                        deleteGroupButton
#else
                        Menu {
                            newButton
                            bulkEditButton
                            deleteGroupButton
                        } label: {
                            Label("MANAGE_LIST", systemImage: "ellipsis.circle")
                        }
#endif
                    }
                }
            }
            .navigationTitle(listName)
        }
    }

    func validateName(_ name: String) -> Bool {
        if name.count > 0 {
            let currentNames = remindersData.list!.reminders.map(\.name)
            return currentNames.contains(name)
        } else {
            return false
        }
    }

    func validName(_ name: String) -> String {
        var (baseName, i) = reverseNumberedName(name)
        while validateName(numberedName(baseName, number: i)) {
            i += 1
        }
        return numberedName(baseName, number: i)
    }

    @ViewBuilder func configView(reminder: Reminder) -> some View {
        if let index = remindersData.list!.reminders.firstIndex(where: { $0.id == reminder.id }) {
            let reminderListBinding = Binding(get: {
                remindersData.list!
            }, set: {
                remindersData.list = $0
            })
            let reminderBinding = Binding(get: {
                remindersData.list!.reminders[index]
            }, set: {
                remindersData.list!.reminders[index] = $0
            })
            ReminderConfig(reminder: reminderBinding, reminderList: reminderListBinding, chineseCalendar: viewModel.chineseCalendar)
        }
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

    var newGroupButton: some View {
        Button {
            let newName = String(localized: "UNNAMED")
            let newList = ReminderList(name: validName(newName), enabled: false, reminders: [])
            let newData = RemindersData(newList)
            modelContext.insert(newData)
        } label: {
            Label("SAVE_NEW", systemImage: "plus")
        }
    }

    var body: some View {
        Form {
            if !notificationEnabled {
                Section {
                    Button("ENABLE_NOTIFICATIONS") {
                        Task {
                            do {
                                notificationEnabled = try await notificationManager.requestAuthorization()
                            } catch {
                                errorMsg = error
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
#if os(iOS) || os(macOS)
                    .buttonStyle(.plain)
#elseif os(visionOS)
                    .buttonStyle(.automatic)
#endif
                }
            }
            Section {
                if dataStack.isEmpty {
                    Text("EMPTY_LIST")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dataStack) { group in
                        if let data = group.list {
                            let listName = if data.name == AppInfo.defaultName {
                                String(localized: "DEFAULT_NAME")
                            } else {
                                data.name
                            }
                            NavigationLink(value: group) {
                                HStack {
                                    Text(listName)
                                        .lineLimit(1)
                                        .foregroundStyle(data.enabled ? .primary : .secondary)
                                    Spacer()
                                    Text("\(data.reminders.count)ITEMS")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task {
            notificationEnabled = await notificationManager.enabled
        }
        .alert("ERROR", isPresented: hasError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMsg?.localizedDescription ?? "")
        }
        .onAppear {
            initializeRemindersData()
        }
        .toolbar {
            newGroupButton
        }
        .navigationDestination(for: RemindersData.self) { reminderData in
            listView(data: reminderData)
        }
        .navigationTitle("REMINDERS_LIST")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    func validateName(_ name: String) -> Bool {
        if name.count > 0 {
            let currentNames = dataStack.compactMap(\.list?.name)
            return currentNames.contains(name)
        } else {
            return false
        }
    }

    func validName(_ name: String) -> String {
        var (baseName, i) = reverseNumberedName(name)
        while validateName(numberedName(baseName, number: i)) {
            i += 1
        }
        return numberedName(baseName, number: i)
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

    @ViewBuilder func listView(data: RemindersData) -> some View {
        if let index = dataStack.firstIndex(where: { $0.id == data.id }) {
            ReminderGroup(remindersData: dataStack[index], chineseCalendar: viewModel.chineseCalendar)
        }
    }
}

#Preview("Reminders", traits: .modifier(SampleData())) {
    NavigationStack {
        RemindersSetting()
    }
}
