//
//  SwiftUIView.swift
//  Chinese Time iOS
//
//  Created by Leo Liu on 6/16/23.
//

import SwiftUI
import SwiftData

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
    @State private var newName = ""
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
            Label(NSLocalizedString("謄錄", comment: "Save current layout button"), systemImage: "plus")
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(Color.green)
        }
        
        let newThemeConfirm = Button(NSLocalizedString("此名甚善", comment: "Confirm adding Settings"), role: .destructive) {
            let newTheme = ThemeData(name: newName, code: WatchLayout.shared.encode())
            modelContext.insert(newTheme)
            do {
                try modelContext.save()
            } catch {
                print("Save failed. \(error.localizedDescription)")
            }
        }
        
        let renameConfirm = Button(NSLocalizedString("此名甚善", comment: "Confirm adding Settings"), role: .destructive) {
            if let target = target, !target.isNil {
                target.name = newName
                do {
                    try modelContext.save()
                } catch {
                    print("Save failed. \(error.localizedDescription)")
                }
                self.target = nil
            }
        }
#if os(macOS)
        let readButton = Button {
            readFile(context: modelContext)
            do {
                try modelContext.save()
            } catch {
                print("Save failed. \(error.localizedDescription)")
            }
        } label: {
            Label(NSLocalizedString("讀入", comment: "Load from file button"), systemImage: "square.and.arrow.down")
        }
#endif
        
        Form {
#if os(iOS)
            Section {
                newTheme
            }
#endif
            let deviceNames = themes.keys.sorted(by: {$0 > $1}).sorted(by: {prev, _ in prev == currentDeviceName})
            ForEach(deviceNames, id: \.self) { key in
                Section(key) {
                    ForEach(themes[key]!, id: \.self) { theme in
                        if !theme.isNil {
                            
                            let deleteButton = Button {
                                target = theme
                                deleteAlert = true
                            } label: {
                                Label(NSLocalizedString("刪", comment: "Delete action"), systemImage: "trash")
                            }
                                .tint(Color.red)
                            
                            let renameButton = Button {
                                target = theme
                                newName = validName(theme.name!)
                                renameAlert = true
                            } label: {
                                Label(NSLocalizedString("更名", comment: "Rename action"), systemImage: "rectangle.and.pencil.and.ellipsis.rtl")
                            }
                                .tint(Color.indigo)
                            
#if os(macOS)
                            let saveButton = Button {
                                writeFile(theme: theme)
                            } label: {
                                Label(NSLocalizedString("寫下", comment: "Save to file button"), systemImage: "square.and.arrow.up")
                            }
#endif
                            
                            HStack {
                                Button {
                                    target = theme
                                    switchAlert = true
                                } label: {
                                    Text(theme.name!)
                                }
#if os(iOS)
                                .buttonStyle(.borderless)
#elseif os(macOS)
                                .buttonStyle(.bordered)
#endif
                                .foregroundStyle(Color.primary)
                                
#if os(iOS)
                                .swipeActions(edge: .trailing) {
                                    deleteButton
                                }
                                .swipeActions(edge: .leading) {
                                    renameButton
                                }
#elseif os(macOS)
                                .contextMenu {
                                    Button {
                                        target = theme
                                        switchAlert = true
                                    } label: {
                                        Label(NSLocalizedString("用", comment: "Switch to this"), systemImage: "cursorarrow.click.2")
                                    }
                                        .labelStyle(.titleAndIcon)
                                    renameButton
                                        .labelStyle(.titleAndIcon)
                                    deleteButton
                                        .labelStyle(.titleAndIcon)
                                    saveButton
                                        .labelStyle(.titleAndIcon)
                                }
#endif
                                Spacer()
                                if Calendar.current.isDate(theme.modifiedDate!, inSameDayAs: .now) {
                                    Text(theme.modifiedDate!, style: .time)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(theme.modifiedDate!, style: .date)
                                        .foregroundStyle(.secondary)
                                }
#if os(macOS)
                                Menu {
                                    renameButton
                                    deleteButton
                                    saveButton
                                } label: {
                                    Image(systemName: "ellipsis")
                                }
                                .menuIndicator(.hidden)
                                .menuStyle(.button)
                                .buttonStyle(.borderless)
                                .labelStyle(.titleAndIcon)
#endif
                            }
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
                    watchLayout.update(from: target.code!)
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
        .alert((target != nil && !target!.isNil) ? (NSLocalizedString("刪：", comment: "Confirm to delete theme message") + target!.name!) : NSLocalizedString("刪不得", comment: "Cannot switch theme"), isPresented: $deleteAlert) {
            Button(NSLocalizedString("容吾三思", comment: "Cancel adding Settings"), role: .cancel) { target = nil }
            Button(NSLocalizedString("吾意已決", comment: "Confirm Resetting Settings"), role: .destructive) {
                if let target = target {
                    modelContext.delete(target)
                    do {
                        try modelContext.save()
                    } catch {
                        print("Save failed. \(error.localizedDescription)")
                    }
                }
            }
        }
        .navigationTitle(Text("主題庫", comment: "manage saved themes"))
#if os(macOS)
        .toolbar {
            Menu {
                newTheme
                readButton
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuIndicator(.hidden)
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .labelStyle(.titleAndIcon)
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
        let namePattern = /^(.*) (\d+)$/
        let baseName: String
        var i: Int
        if let match = try? namePattern.firstMatch(in: name) {
            baseName = String(match.output.1)
            i = Int(match.output.2)!
        } else {
            baseName = name
            i = 2
        }
        while !validateName("\(baseName) \(i)", onDevice: device ?? currentDeviceName) {
            i += 1
        }
        return "\(baseName) \(i)"
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
