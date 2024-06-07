//
//  ThemesList.swift
//  Chinendar
//
//  Created by Leo Liu on 6/16/23.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if os(macOS)
struct DynamicButtonStyle: ButtonStyle {
    var prominent: Bool
    @Environment(\.isEnabled) var isEnabled
    @ScaledMetric(relativeTo: .body) var size: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        let color = isEnabled ? Color.primary : Color.secondary
        configuration.label
            .padding(size)
            .overlay(
                RoundedRectangle(cornerRadius: size * 1.5)
                    .stroke(color.opacity(prominent ? 1 : 0), lineWidth: 1)
                    .fill(color.opacity(prominent ? 0.1 : 0))
            )
            .scaleEffect(configuration.isPressed && isEnabled ? 0.99 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: prominent)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
#endif

struct HighlightButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State var hover = false

    var body: some View {
        let button = Button {
            action()
        } label: {
            label()
        }
            .onHover { over in
                hover = over
            }
#if os(macOS)
        button
            .buttonStyle(DynamicButtonStyle(prominent: hover))
#else
        button
            .buttonStyle(.borderless)
#endif
    }
}

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

    static let readableContentTypes: [UTType] = [.text]

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
    for data in data where !data.isNil {
        if newThemes[data.deviceName!] == nil {
            newThemes[data.deviceName!] = [data]
        } else {
            newThemes[data.deviceName!]!.append(data)
        }
    }
    for deviceName in newThemes.keys {
        newThemes[deviceName]!.sort { $0.modifiedDate! > $1.modifiedDate! }
    }
    return newThemes
}

func numberedName(_ baseName: String, number: Int) -> String {
    if number <= 1 {
        return baseName
    } else {
        return "\(baseName) \(number)"
    }
}

func reverseNumberedName(_ name: String) -> (String, Int) {
    let namePattern = /^(.*) (\d+)$/
    if let match = try? namePattern.firstMatch(in: name) {
        return (String(match.output.1), Int(match.output.2)!)
    } else {
        return (name, 1)
    }
}

func read(file: URL) throws -> (name: String, code: String) {
    let accessing = file.startAccessingSecurityScopedResource()
    defer {
        if accessing {
            file.stopAccessingSecurityScopedResource()
        }
    }
    let code = try String(contentsOf: file)
    let nameComponent = file.lastPathComponent
    let namePattern = /^([^\.]+)\.?.*$/
    let name = try namePattern.firstMatch(in: nameComponent)?.output.1
    let actualName = if let name = name {
        String(name)
    } else {
        nameComponent
    }
    return (name: actualName, code: code)
}

#if os(macOS)
@MainActor
func writeFile(name: String, code: String) {
    let panel = NSSavePanel()
    panel.level = NSWindow.Level.floating
    panel.title = NSLocalizedString("以筆書之", comment: "Save File title")
    panel.allowedContentTypes = [.text]
    panel.canCreateDirectories = true
    panel.isExtensionHidden = false
    panel.allowsOtherFileTypes = false
    panel.message = NSLocalizedString("將主題書於紙上", comment: "Save File message")
    panel.nameFieldLabel = NSLocalizedString("題名", comment: "File name prompt")
    panel.nameFieldStringValue = "\(name).txt"
    panel.begin { result in
        if result == .OK, let file = panel.url {
            do {
                try code.data(using: .utf8)?.write(to: file, options: .atomicWrite)
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
func readFile(handler: @escaping (URL) throws -> Void) {
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
                try handler(file)
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

struct ThemesList: View {
    @Query(sort: \ThemeData.modifiedDate, order: .reverse) private var dataStack: [ThemeData]
    @Environment(\.modelContext) private var modelContext
    @Environment(WatchSetting.self) var watchSetting
    @Environment(WatchLayout.self) var watchLayout

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
    @State private var target: ThemeData?
    var targetName: String {
        if let name = target?.name {
            if name == AppInfo.defaultName {
                return NSLocalizedString("常用", comment: "")
            } else {
                return name
            }
        } else {
            return ""
        }
    }
    private var invalidName: Bool {
        let diviceName = target?.deviceName ?? currentDeviceName
        return !validateName(newName, onDevice: diviceName)
    }
    private var themes: [String: [ThemeData]] {
        loadThemes(data: dataStack)
    }
    let currentDeviceName = AppInfo.deviceName

    var body: some View {
        let newTheme = Button {
            newName = validName(NSLocalizedString("佚名", comment: "unnamed"))
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
            let newTheme = ThemeData(name: newName, code: watchLayout.encode())
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
            readFile(handler: handleFile)
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
            if dataStack.count > 0 {
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
                                let dateLabel = if Calendar.current.isDate(theme.modifiedDate!, inSameDayAs: .now) {
                                    Text(theme.modifiedDate!, style: .time)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(theme.modifiedDate!, style: .date)
                                        .foregroundStyle(.secondary)
                                }

                                let saveButton = Button {
#if os(macOS)
                                    if !theme.isNil {
                                        writeFile(name: theme.name!, code: theme.code!)
                                    }
#elseif os(iOS) || os(visionOS)
                                    target = theme
                                    isExporting = true
#endif
                                } label: {
                                    Label("寫下", systemImage: "square.and.arrow.up")
                                }

                                let deleteButton = Button(role: .destructive) {
                                    target = theme
                                    deleteAlert = true
                                } label: {
                                    Label("刪", systemImage: "trash")
                                }

                                let renameButton = Button {
                                    target = theme
                                    newName = validName(theme.name!, device: theme.deviceName!)
                                    renameAlert = true
                                } label: {
                                    Label("更名", systemImage: "rectangle.and.pencil.and.ellipsis.rtl")
                                }

                                let nameLabel = if theme.name! != AppInfo.defaultName {
                                    Text(theme.name!)
                                } else {
                                    Text("常用")
                                }

                                HighlightButton {
                                    if theme.name! != AppInfo.defaultName || theme.deviceName! != AppInfo.deviceName {
                                        target = theme
                                        switchAlert = true
                                    }
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
                                    saveButton
                                    if theme.name! != AppInfo.defaultName {
                                        renameButton
                                    }
                                    if theme.name! != AppInfo.defaultName || theme.deviceName! != AppInfo.deviceName {
                                        deleteButton
                                    }
                                } preview: {
                                    let themeLayout = {
                                        let layout = WatchLayout()
                                        layout.update(from: theme.code!)
                                        return layout
                                    }()
                                    Icon(watchLayout: themeLayout, preview: true)
                                        .frame(width: 120, height: 120)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("混沌初開，萬物未成")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            removeDuplicates()
        }
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
        .alert((target != nil && !target!.isNil) ? (NSLocalizedString("換爲：", comment: "Confirm to select theme message") + targetName) : NSLocalizedString("換不得", comment: "Cannot switch theme"), isPresented: $switchAlert) {
            Button(NSLocalizedString("容吾三思", comment: "Cancel adding Settings"), role: .cancel) { target = nil }
            Button(NSLocalizedString("吾意已決", comment: "Confirm Resetting Settings"), role: .destructive) {
                if let target = target, !target.isNil {
#if os(visionOS)
                    watchLayout.update(from: target.code!, updateSize: false)
#else
                    watchLayout.update(from: target.code!)
#endif
#if os(macOS)
                    if let delegate = AppDelegate.instance {
                        delegate.update()
                        delegate.watchPanel.panelPosition()
                    }
#endif
                    self.target = nil
                }
            }
        }
        .alert((target != nil && !target!.isNil) ? (NSLocalizedString("刪：", comment: "Confirm to delete theme message") + targetName) : NSLocalizedString("刪不得", comment: "Cannot delete theme"), isPresented: $deleteAlert) {
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
                    let theme = ThemeData(name: validName(name), code: code)
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
            return false
        }
    }

    func validName(_ name: String, device: String? = nil) -> String {
        var (baseName, i) = reverseNumberedName(name)
        while !validateName(numberedName(baseName, number: i), onDevice: device ?? currentDeviceName) {
            i += 1
        }
        return numberedName(baseName, number: i)
    }

    func removeDuplicates() {
        var records = Set<String>()
        for data in dataStack {
            if data.isNil {
                modelContext.delete(data)
            } else {
                if records.contains("deviceName: \(data.deviceName!), themeName: \(data.name!)") {
                    modelContext.delete(data)
                } else {
                    records.insert("deviceName: \(data.deviceName!), themeName: \(data.name!)")
                }
            }
        }
    }

#if os(macOS)
    @MainActor
    func handleFile(_ file: URL) throws {
        let themeCode = try String(contentsOf: file)
        let name = file.lastPathComponent
        let namePattern = /^([^\.]+)\.?.*$/
        let themeName = try namePattern.firstMatch(in: name)?.output.1
        let theme = ThemeData(name: validName(themeName != nil ? String(themeName!) : name), code: themeCode)
        modelContext.insert(theme)
        try modelContext.save()
    }
#endif
}

#Preview("Themes") {
    let watchLayout = WatchLayout()
    let watchSetting = WatchSetting()
    watchLayout.loadStatic()
    return ThemesList()
        .modelContainer(DataSchema.container)
        .environment(watchLayout)
        .environment(watchSetting)
}
