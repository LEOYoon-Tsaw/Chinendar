//
//  ThemesList.swift
//  Chinendar
//
//  Created by Leo Liu on 6/16/23.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
    
    static var readableContentTypes: [UTType] = [.text]
    
    var text: String = ""
    init?(_ text: String?) {
        if let text = text {
            self.text = text
        } else {
            return nil
        }
    }
    
}

private func loadThemes(data: [ThemeData]) -> [String: [ThemeData]] {
    var newThemes = [String: [ThemeData]]()
    for data in data {
        if !data.isNil {
            if newThemes[data.deviceName!] == nil {
                newThemes[data.deviceName!] = [data]
            } else {
                newThemes[data.deviceName!]!.append(data)
            }
        }
    }
    for deviceName in newThemes.keys {
        newThemes[deviceName]!.sort { $0.modifiedDate! > $1.modifiedDate! }
    }
    return newThemes
}

struct ThemesList: View {
    @Query private var dataStack: [ThemeData]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.watchSetting) var watchSetting
    @Environment(\.watchLayout) var watchLayout

    @State private var renameAlert = false
    @State private var createAlert = false
    @State private var switchAlert = false
    @State private var deleteAlert = false
    @State private var revertAlert = false
    @State private var errorAlert = false
#if os(iOS) || os(visionOS)
    @State private var isExporting = false
    @State private var isImporting = false
#endif
    @State private var newName = ""
    @State private var errorMsg = ""
    @State private var target: ThemeData? = nil
    private var invalidName: Bool {
        let diviceName = target?.deviceName ?? currentDeviceName
        return !validateName(newName, onDevice: diviceName)
    }
    private var themes: [String: [ThemeData]] {
        loadThemes(data: dataStack)
    }
    let currentDeviceName = ThemeData.deviceName
    
    var body: some View {
        let newTheme = Button {
            newName = validName(ThemeData.defaultName)
            createAlert = true
        } label: {
            Label("謄錄", systemImage: "square.and.pencil")
        }
        let revertBack = Button(role: .destructive) {
            revertAlert = true
        } label: {
            Label("復原", systemImage: "arrow.clockwise")
        }
        
        let newThemeConfirm = Button(NSLocalizedString("此名甚善", comment: "Confirm adding Settings"), role: .destructive) {
            let newTheme = ThemeData(name: newName, code: WatchLayout.shared.encode())
            modelContext.insert(newTheme)
            do {
                try modelContext.save()
            } catch {
                errorMsg = error.localizedDescription
                errorAlert = true
            }
        }
        
        let renameConfirm = Button(NSLocalizedString("此名甚善", comment: "Confirm adding Settings"), role: .destructive) {
            if let target = target, !target.isNil {
                target.name = newName
                do {
                    try modelContext.save()
                } catch {
                    errorMsg = error.localizedDescription
                    errorAlert = true
                }
                self.target = nil
            }
        }

        let readButton = Button {
#if os(macOS)
            readFile(context: modelContext)
            do {
                try modelContext.save()
            } catch {
                errorMsg = error.localizedDescription
                errorAlert = true
            }
#elseif os(iOS) || os(visionOS)
            isImporting = true
#endif
        } label: {
            Label("讀入", systemImage: "square.and.arrow.down")
        }
        
        let moreMenu = Menu {
            VStack {
                newTheme
                readButton
                revertBack
            }
            .labelStyle(.titleAndIcon)
        } label: {
            Label("經理", systemImage: "ellipsis.circle")
        }
        .menuIndicator(.hidden)
        .menuStyle(.automatic)
        
        Form {
            let deviceNames = themes.keys.sorted(by: {$0 > $1}).sorted(by: {prev, _ in prev == currentDeviceName})
            ForEach(deviceNames, id: \.self) { key in
                Section(key) {
#if os(iOS)
                    if key == currentDeviceName {
                        moreMenu
                            .labelStyle(.titleOnly)
                            .frame(maxWidth: .infinity)
                    }
#endif
                    ForEach(themes[key]!, id: \.self) { theme in
                        if !theme.isNil {
                            
                            let deleteButton = Button(role: .destructive) {
                                target = theme
                                deleteAlert = true
                            } label: {
                                Label("刪", systemImage: "trash")
                            }
                            
                            let renameButton = Button {
                                target = theme
                                newName = validName(theme.name!)
                                renameAlert = true
                            } label: {
                                Label("更名", systemImage: "rectangle.and.pencil.and.ellipsis.rtl")
                            }
                            
                            let applyButton = Button {
                                target = theme
                                switchAlert = true
                            } label: {
                                Label("用", systemImage: "cursorarrow.click.2")
                            }
                            
                            let saveButton = Button {
#if os(macOS)
                                writeFile(theme: theme)
#elseif os(iOS) || os(visionOS)
                                target = theme
                                isExporting = true
#endif
                            } label: {
                                Label("寫下", systemImage: "square.and.arrow.up")
                            }
                            
                            let dateLabel = if Calendar.current.isDate(theme.modifiedDate!, inSameDayAs: .now) {
                                Text(theme.modifiedDate!, style: .time)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(theme.modifiedDate!, style: .date)
                                    .foregroundStyle(.secondary)
                            }
                            
#if os(macOS)
                            HStack {
                                Menu {
                                    applyButton
                                    renameButton
                                    saveButton
                                    deleteButton
                                } label: {
                                    Text(theme.name!)
                                }
                                .menuIndicator(.hidden)
                                .menuStyle(.button)
                                .buttonStyle(.accessoryBar)
                                .labelStyle(.titleAndIcon)
                                Spacer()
                                dateLabel
                            }
#else
                            Menu {
                                applyButton
                                renameButton
                                saveButton
                                deleteButton
                            } label: {
                                HStack {
                                    Text(theme.name!)
                                    Spacer()
                                    dateLabel
                                }
                            }
                            .menuIndicator(.hidden)
                            .menuStyle(.button)
                            .buttonStyle(.borderless)
                            .labelStyle(.titleAndIcon)
                            .tint(.primary)
#endif
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert(NSLocalizedString("更名", comment: "Rename action"), isPresented: $renameAlert) {
            TextField("", text: $newName)
                .labelsHidden()
            renameConfirm
                .disabled(invalidName)
            Button(NSLocalizedString("容吾三思", comment: "Cancel adding Settings"), role: .cancel) { target = nil }
        } message: {
            Text("不得爲空，不得重名", comment: "no blank, no duplicate name")
        }
        .alert(NSLocalizedString("取名", comment: "set a name"), isPresented: $createAlert) {
            TextField("", text: $newName)
                .labelsHidden()
            newThemeConfirm
                .disabled(invalidName)
            Button(NSLocalizedString("容吾三思", comment: "Cancel adding Settings"), role: .cancel) {}
        } message: {
            Text("不得爲空，不得重名", comment: "no blank, no duplicate name")
        }
        .alert((target != nil && !target!.isNil) ? (NSLocalizedString("換爲：", comment: "Confirm to select theme message") + target!.name!) : NSLocalizedString("換不得", comment: "Cannot switch theme"), isPresented: $switchAlert) {
            Button(NSLocalizedString("容吾三思", comment: "Cancel adding Settings"), role: .cancel) { target = nil }
            Button(NSLocalizedString("吾意已決", comment: "Confirm Resetting Settings"), role: .destructive) {
                if let target = target, !target.isNil {
#if os(visionOS)
                    watchLayout.update(from: target.code!, updateSize: false)
#else
                    watchLayout.update(from: target.code!)
#endif
#if os(iOS)
                    WatchConnectivityManager.shared.sendLayout(watchLayout.encode(includeOffset: false))
#elseif os(macOS)
                    if let delegate = AppDelegate.instance {
                        delegate.update()
                        delegate.watchPanel.panelPosition()
                    }
#endif
                    self.target = nil
                }
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
        .alert("復原", isPresented: $revertAlert) {
            Button(NSLocalizedString("容吾三思", comment: "Cancel adding Settings"), role: .cancel) { }
            Button(NSLocalizedString("吾意已決", comment: "Confirm Resetting Settings"), role: .destructive) {
                watchLayout.loadStatic()
            }
        } message: {
            Text("將丢失當前編輯，但不影響存檔", comment: "will lose edit, but saves will be intact")
        }
        .alert("怪哉", isPresented: $errorAlert) {
            Button("罷", role: .cancel) {}
        } message: {
            Text(errorMsg)
        }
#if os(iOS) || os(visionOS)
        .fileExporter(isPresented: $isExporting,
                      document: TextDocument(target?.code),
                      contentType: .text,
                      defaultFilename: target?.name.map {"\($0).txt"}) { result in
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
                    let accessing = file.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            file.stopAccessingSecurityScopedResource()
                        }
                    }
                    let themeCode = try String(contentsOf: file)
                    let name = file.lastPathComponent
                    let namePattern = /^([^\.]+)\.?.*$/
                    let themeName = try namePattern.firstMatch(in: name)?.output.1
                    let theme = ThemeData(name: validName(themeName != nil ? String(themeName!) : name), code: themeCode)
                    modelContext.insert(theme)
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
        .navigationTitle(Text("主題庫", comment: "manage saved themes"))
#if os(macOS) || os(visionOS)
        .toolbar {
            moreMenu
        }
#elseif os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
                watchSetting.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#endif
    }
    
    func validateName(_ name: String, onDevice deviceName: String) -> Bool {
        if name.count > 0 {
            let currentDeviceThemes = themes[deviceName]
            return currentDeviceThemes == nil || !(currentDeviceThemes!.map { $0.name }.contains(name))
        } else {
            return true
        }
    }
    
    func validName(_ name: String, device: String? = nil) -> String {
        func numberedName(_ baseName: String, number: Int) -> String {
            if number <= 1 {
                return baseName
            } else {
                return "\(baseName) \(i)"
            }
        }
        let namePattern = /^(.*) (\d+)$/
        let baseName: String
        var i: Int
        if let match = try? namePattern.firstMatch(in: name) {
            baseName = String(match.output.1)
            i = Int(match.output.2)!
        } else {
            baseName = name
            i = 1
        }
        while !validateName(numberedName(baseName, number: i), onDevice: device ?? currentDeviceName) {
            i += 1
        }
        return numberedName(baseName, number: i)
    }
    
#if os(macOS)
    @MainActor
    func writeFile(theme: ThemeData) {
        guard !theme.isNil else { return }
        let panel = NSSavePanel()
        panel.level = NSWindow.Level.floating
        panel.title = NSLocalizedString("以筆書之", comment: "Save File title")
        panel.allowedContentTypes = [.text]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.allowsOtherFileTypes = false
        panel.message = NSLocalizedString("將主題書於紙上", comment: "Save File message")
        panel.nameFieldLabel = NSLocalizedString("題名", comment: "File name prompt")
        panel.nameFieldStringValue = "\(theme.name!).txt"
        panel.begin { result in
            if result == .OK, let file = panel.url {
                do {
                    try theme.code!.data(using: .utf8)?.write(to: file, options: .atomicWrite)
                } catch {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("寫不出", comment: "Save Failed")
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    alert.beginSheetModal(for: panel)
                }
            }
        }
    }
    
    @MainActor
    func readFile(context: ModelContext) {
        let panel = NSOpenPanel()
        panel.level = NSWindow.Level.floating
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.text]
        panel.title = NSLocalizedString("讀入主題", comment: "Open File title")
        panel.message = NSLocalizedString("選一卷主題讀入", comment: "Open File message")
        panel.begin { result in
            if result == .OK, let file = panel.url {
                do {
                    let themeCode = try String(contentsOf: file)
                    let name = file.lastPathComponent
                    let namePattern = /^([^\.]+)\.?.*$/
                    let themeName = try namePattern.firstMatch(in: name)?.output.1
                    let theme = ThemeData(name: validName(themeName != nil ? String(themeName!) : name), code: themeCode)
                    context.insert(theme)
                    try modelContext.save()
                } catch {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("讀不入", comment: "Load Failed")
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    alert.beginSheetModal(for: panel)
                }
            }
        }
    }
#endif
}

#Preview("Themes") {
    ThemesList()
}
