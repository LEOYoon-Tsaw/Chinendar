//
//  CalendarConfig.swift
//  Chinendar
//
//  Created by Leo Liu on 3/29/24.
//

import SwiftUI
import SwiftData

struct ConfigList: View {
    @Query(sort: \ConfigData.modifiedDate, order: .reverse) private var configs: [ConfigData]
    @Environment(\.modelContext) private var modelContext
    @Environment(ViewModel.self) var viewModel

    @State private var renameAlert = false
    @State private var createAlert = false
    @State private var deleteAlert = false
    @State private var errorAlert = false
#if os(iOS) || os(visionOS)
    @State private var isExporting = false
    @State private var isImporting = false
#endif
    @State private var newName = ""
    @State private var errorMsg = ""
    @State private var target: ConfigData?
    private var invalidName: Bool {
        return !validateName(newName)
    }
    var targetName: String {
        if let name = target?.name {
            if name == AppInfo.defaultName {
                return String(localized: LocalizedStringResource("DEFAULT_NAME"))
            } else {
                return name
            }
        } else {
            return ""
        }
    }
    let newNamePlaceholder: String = String(localized: LocalizedStringResource(stringLiteral: "UNNAMED"))

    var body: some View {
        let newConfig = createNewConfigButton()
        let newConfigConfirm = createConfigConfirmButton()
        let renameConfirm = createRenameConfirmButton()
        let readButton = createReadButton()

        let moreMenu = Menu {
            VStack {
                newConfig
                readButton
            }
            .labelStyle(.titleAndIcon)
        } label: {
            Label("MANAGE_LIST", systemImage: "ellipsis.circle")
        }
        .menuIndicator(.hidden)
        .menuStyle(.automatic)

        Form {
            if configs.count > 0 {
                Section {
#if os(iOS)
                    moreMenu
                        .labelStyle(.titleOnly)
                        .frame(maxWidth: .infinity)
#endif
                    ForEach(configs, id: \.self, content: configView)
                }
            } else {
                Text("EMPTY_LIST")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            removeDuplicates()
        }
        .alert("RENAME", isPresented: $renameAlert) {
            TextField("", text: $newName)
                .labelsHidden()
            renameConfirm
                .disabled(invalidName)
            Button("CANCEL", role: .cancel) { target = nil }
        } message: {
            Text("INVALID_NAME_MSG")
        }
        .alert("NEW_NAME", isPresented: $createAlert) {
            TextField("", text: $newName)
                .labelsHidden()
            newConfigConfirm
                .disabled(invalidName)
            Button("CANCEL", role: .cancel) {}
        } message: {
            Text("INVALID_NAME_MSG")
        }
        .alert((target != nil && !target!.isNil) ? Text("DELETE:\(targetName)") : Text("DELETE_FAILED"), isPresented: $deleteAlert) {
            Button("CANCEL", role: .cancel) { target = nil }
            Button("CONFIRM", role: .destructive) {
                if let target {
                    modelContext.delete(target)
                    do {
                        try modelContext.save()
                        ChinendarShortcut.updateAppShortcutParameters()
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
#if os(iOS) || os(visionOS)
        .fileExporter(isPresented: $isExporting,
                      document: TextDocument(target?.code),
                      contentType: .text,
                      defaultFilename: "\(targetName).txt") { result in
            target = nil
            if case .failure(let error) = result {
                errorMsg = error.localizedDescription
                errorAlert = true
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.text]) { result in
            switch result {
            case .success(let file):
                do {
                    let (name, code) = try read(file: file)
                    let config = ConfigData(name: validName(name), code: code)
                    modelContext.insert(config)
                    try modelContext.save()
                } catch {
                    errorMsg = error.localizedDescription
                    errorAlert = true
                }
            case .failure(let error):
                errorMsg = error.localizedDescription
                errorAlert = true
            }
        }
#endif
        .navigationTitle("CALENDAR_LIST")
#if os(macOS) || os(visionOS)
        .toolbar {
            moreMenu
        }
#elseif os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("DONE") {
                viewModel.settings.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#endif
    }

    @ViewBuilder func configView(config: ConfigData) -> some View {
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

            let nameLabel = Label {
                config.name! == AppInfo.defaultName ? Text("DEFAULT_NAME") : Text(config.name!)
            } icon: {
                Image(systemName: config.name! == viewModel.config.name ? "circle.inset.filled" : "circle")
                    .foregroundStyle(Color.blue)
            }

            let saveButton = Button {
#if os(macOS)
                if !config.isNil {
                    writeFile(name: config.name!, code: config.code!)
                }
#elseif os(iOS) || os(visionOS)
                target = config
                isExporting = true
#endif
            } label: {
                Label("EXPORT", systemImage: "square.and.arrow.up")
            }

            let deleteButton = Button(role: .destructive) {
                target = config
                deleteAlert = true
            } label: {
                Label("DELETE", systemImage: "trash")
            }

            let renameButton = Button {
                target = config
                newName = validName(targetName)
                renameAlert = true
            } label: {
                Label("RENAME", systemImage: "rectangle.and.pencil.and.ellipsis.rtl")
            }

            HighlightButton {
                switchTo(config: config)
            } label: {
                HStack {
                    nameLabel
                    Spacer()
                    dateLabel
                }
            }
            .tint(.primary)
            .labelStyle(.titleAndIcon)
            .contextMenu {
                renameButton
                saveButton
                if config.name != viewModel.config.name {
                    deleteButton
                }
            }
        }
    }

    func createNewConfigButton() -> some View {
        Button {
            newName = validName(newNamePlaceholder)
            createAlert = true
        } label: {
            Label("SAVE_NEW", systemImage: "square.and.pencil")
        }
    }
    func createConfigConfirmButton() -> some View {
        Button("CONFIRM_NAME", role: .destructive) {
            let newConfig = ConfigData(name: newName, code: viewModel.configString())
            modelContext.insert(newConfig)
            viewModel.config.name = newName
            do {
                try modelContext.save()
                ChinendarShortcut.updateAppShortcutParameters()
            } catch {
                errorMsg = error.localizedDescription
                errorAlert = true
            }
        }
    }
    func createRenameConfirmButton() -> some View {
        Button("CONFIRM_NAME", role: .destructive) {
            if let target, !target.isNil {
                let isChangingCurrent = target.name == viewModel.config.name
                target.name = newName
                do {
                    try modelContext.save()
                    ChinendarShortcut.updateAppShortcutParameters()
                } catch {
                    errorMsg = error.localizedDescription
                    errorAlert = true
                }
                if isChangingCurrent {
                    viewModel.config.name = newName
                }
                self.target = nil
            }
        }
    }
    func createReadButton() -> some View {
        Button {
#if os(macOS)
            readFile(handler: handleFile)
#elseif os(iOS) || os(visionOS)
            isImporting = true
#endif
        } label: {
            Label("IMPORT", systemImage: "square.and.arrow.down")
        }
    }

    func switchTo(config: ConfigData) {
        if config.name != viewModel.config.name {
            viewModel.updateConfig(from: config.code!, newName: config.name!)
            viewModel.updateChineseCalendar()
        }
    }

    func validateName(_ name: String) -> Bool {
        if name.count > 0 {
            return !(configs.map { $0.name }.contains(name))
        } else {
            return false
        }
    }

    func validName(_ name: String) -> String {
        var (baseName, i) = reverseNumberedName(name)
        while !validateName(numberedName(baseName, number: i)) {
            i += 1
        }
        return numberedName(baseName, number: i)
    }

    func removeDuplicates() {
        var records = Set<String>()
        for data in configs {
            if data.isNil {
                modelContext.delete(data)
            } else {
                if records.contains(data.name!) {
                    modelContext.delete(data)
                } else {
                    records.insert(data.name!)
                }
            }
        }
    }

#if os(macOS)
    @MainActor
    func handleFile(_ file: URL) throws {
        let configCode = try String(contentsOf: file, encoding: .utf8)
        let name = file.lastPathComponent
        let namePattern = /^([^\.]+)\.?.*$/
        let configName = try namePattern.firstMatch(in: name)?.output.1
        let config = ConfigData(name: validName(configName != nil ? String(configName!) : name), code: configCode)
        modelContext.insert(config)
        try modelContext.save()
    }
#endif
}

#Preview("Configs", traits: .modifier(SampleData())) {
    ConfigList()
}
