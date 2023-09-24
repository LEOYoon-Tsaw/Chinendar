//
//  LayoutSetting.swift
//  Chinese Time iOS
//
//  Created by Leo Liu on 6/23/23.
//

import SwiftUI
import Observation

struct LayoutSettingCell<V: Numeric>: View {
    let text: Text
    @Binding var value: V
    let validation: ((V) -> V)?
    let completion: (() -> Void)?
    @State var tempValue: V
    @FocusState var isFocused: Bool
    
    init(text: Text, value: Binding<V>, validation: ((V) -> V)? = nil, completion: (() -> Void)? = nil) {
        self.text = text
        self._value = value
        self.validation = validation
        self.completion = completion
        self._tempValue = State(initialValue: value.wrappedValue)
    }
    
    var body: some View {
        HStack {
            text
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("", value: $tempValue, formatter: {
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 2
                formatter.minimumFractionDigits = 0
                return formatter
            }())
            .focused($isFocused)
            .autocorrectionDisabled()
            .onSubmit(of: .text) {
                commit()
            }
            .onChange(of: isFocused) { _, newValue in
                if !newValue {
                    commit()
                }
            }
            .task {
                tempValue = value
            }
#if os(iOS)
            .padding(.vertical, 5)
#elseif os(macOS)
            .frame(height: 20)
#endif
            .padding(.leading, 15)
#if os(iOS)
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 10))
#elseif os(macOS)
            .background(in: RoundedRectangle(cornerRadius: 10))
#endif
            .padding(.trailing, 10)
        }
    }
    
    func commit() {
        if let validation = validation {
            tempValue = validation(tempValue)
        }
        value = tempValue
        if let completion = completion {
            completion()
        }
    }
}

#if os(macOS)
@Observable class FontHandler {
    let allFonts = NSFontManager.shared.availableFontFamilies
    var textFontMembers = [String]()
    var centerFontMembers = [String]()
    var textFontSelection: String = "" {
        didSet {
            textFontMembers = populateFontMembers(for: textFontSelection)
            if let first = textFontMembers.first {
                textFontMemberSelection = first
            }
        }
    }
    var textFontMemberSelection: String = ""
    var centerFontSelection: String = "" {
        didSet {
            centerFontMembers = populateFontMembers(for: centerFontSelection)
            if let first = centerFontMembers.first {
                centerFontMemberSelection = first
            }
        }
    }
    var centerFontMemberSelection: String = ""
    
    var textFont: NSFont? {
        get {
            readFont(family: textFontSelection, style: textFontMemberSelection)
        } set {
            if let font = newValue {
                let (textFamily, textMember) = getFontFamilyAndMember(font: font)
                if let textFamily = textFamily {
                    textFontSelection = textFamily
                    textFontMembers = populateFontMembers(for: textFamily)
                    textFontMemberSelection = textMember ?? textFontMembers.first ?? textFontMemberSelection
                }
            }
        }
    }
    
    var centerFont: NSFont? {
        get {
            readFont(family: centerFontSelection, style: centerFontMemberSelection)
        } set {
            if let font = newValue {
                let (centerFamily, centerMember) = getFontFamilyAndMember(font: font)
                if let centerFamily = centerFamily {
                    centerFontSelection = centerFamily
                    centerFontMembers = populateFontMembers(for: centerFamily)
                    centerFontMemberSelection = centerMember ?? centerFontMembers.first ?? centerFontMemberSelection
                }
            }
        }
    }
    
    func populateFontMembers(for fontFamily: String) -> [String] {
        var allMembers = [String]()
        let members = NSFontManager.shared.availableMembers(ofFontFamily: fontFamily)
        for member in members ?? [[Any]]() {
            if let fontType = member[1] as? String {
                allMembers.append(fontType)
            }
        }
        return allMembers
    }
    
    func readFont(family: String, style: String) -> NSFont? {
        let size = NSFont.systemFontSize
        if let font = NSFont(name: "\(family.filter { !$0.isWhitespace })-\(style.filter { !$0.isWhitespace })", size: size) {
            return font
        }
        let members = NSFontManager.shared.availableMembers(ofFontFamily: family) ?? [[Any]]()
        for i in 0..<members.count {
            if let memberName = members[i][1] as? String, memberName == style,
               let weight = members[i][2] as? Int,
               let traits = members[i][3] as? UInt
            {
                return NSFontManager.shared.font(withFamily: family, traits: NSFontTraitMask(rawValue: traits), weight: weight, size: size)
            }
        }
        if let font = NSFont(name: family, size: size) {
            return font
        }
        return nil
    }
    
    func getFontFamilyAndMember(font: NSFont) -> (String?, String?) {
        let family = font.familyName
        let member = font.fontName.split(separator: "-").last.map {String($0)}
        return (family, member)
    }
}
#endif

struct LayoutSetting: View {
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
#if os(macOS)
    static let nameMapping = [
        "space": NSLocalizedString("空格", comment: "Space separator"),
        "dot": NSLocalizedString("・", comment: "・"),
        "none": NSLocalizedString("無", comment: "No separator")
    ]
    @Environment(\.chineseCalendar) var chineseCalendar
    @State var fontHandler = FontHandler()
#endif
    
    var body: some View {
        Form {
#if os(macOS)
            Section(header: Text("狀態欄", comment: "Status Bar setting")) {
                HStack {
                    Toggle("日", isOn: watchLayout.binding(\.statusBar.date))
                    Spacer(minLength: 20)
                    Toggle("時", isOn: watchLayout.binding(\.statusBar.time))
                }
                HStack {
                    Picker("節日", selection: watchLayout.binding(\.statusBar.holiday)) {
                        ForEach(0...2, id: \.self) { Text(String($0)) }
                    }
                    Spacer(minLength: 20)
                    Picker("讀號", selection: watchLayout.binding(\.statusBar.separator)) {
                        ForEach(WatchLayout.StatusBar.Separator.allCases, id: \.self) { Text(LayoutSetting.nameMapping[$0.rawValue]!) }
                    }
                }
            }
            Section(header: Text("字體", comment: "Font selection")) {
                HStack {
                    Picker("小字", selection: $fontHandler.textFontSelection) {
                        ForEach(fontHandler.allFonts, id:\.self) { family in
                            Text(family)
                        }
                    }
                    Picker("麤細", selection: $fontHandler.textFontMemberSelection) {
                        ForEach(fontHandler.textFontMembers, id:\.self) { member in
                            Text(member)
                        }
                    }
                    .labelsHidden()
                }
                
                HStack {
                    Picker("大字", selection: $fontHandler.centerFontSelection) {
                        ForEach(fontHandler.allFonts, id:\.self) { family in
                            Text(family)
                        }
                    }
                    
                    Picker("麤細", selection: $fontHandler.centerFontMemberSelection) {
                        ForEach(fontHandler.centerFontMembers, id:\.self) { member in
                            Text(member)
                        }
                    }
                    .labelsHidden()
                }
            }
                .onChange(of: fontHandler.textFont) { _, _ in
                    if let font = fontHandler.textFont {
                        watchLayout.textFont = font
                    }
                }

                .onChange(of: fontHandler.centerFont) { _, _ in
                    if let font = fontHandler.centerFont {
                        watchLayout.centerFont = font
                    }
                }
#endif
#if os(iOS)
            Section(header: Text("形", comment: "Shape")) {
                LayoutSettingCell(text: watchSetting.vertical ? Text("寬", comment: "Width") : Text("高", comment: "Height"), value: watchLayout.binding(\.watchSize.width)) { max(10.0, $0) }
                LayoutSettingCell(text: watchSetting.vertical ? Text("高", comment: "Height") : Text("寬", comment: "Width"), value: watchLayout.binding(\.watchSize.height)) { max(10.0, $0) }
                LayoutSettingCell(text: Text("圓角比例", comment: "Corner radius ratio"), value: watchLayout.binding(\.cornerRadiusRatio)) { min(1.0, max(0.0, $0)) }
                LayoutSettingCell(text: Text("陰影大小", comment: "Shadow size"), value: watchLayout.binding(\.shadowSize)) { min(0.1, max(0.0, $0)) }
            }
            Section(header: Text("字偏", comment: "Text Shift")) {
                LayoutSettingCell(text: Text("大字平移", comment: "Height"), value: watchLayout.binding(\.centerTextOffset))
                LayoutSettingCell(text: Text("大字縱移", comment: "Height"), value: watchLayout.binding(\.centerTextHOffset))
                LayoutSettingCell(text: Text("小字平移", comment: "Height"), value: watchLayout.binding(\.horizontalTextOffset))
                LayoutSettingCell(text: Text("小字縱移", comment: "Height"), value: watchLayout.binding(\.verticalTextOffset))
            }
#elseif os(macOS)
            Section(header: Text("形", comment: "Shape")) {
                HStack {
                    LayoutSettingCell(text: Text("寬", comment: "Width"), value: watchLayout.binding(\.watchSize.width)) { max(10.0, $0) } completion: {
                        AppDelegate.instance?.watchPanel.panelPosition()
                    }
                    LayoutSettingCell(text: Text("高", comment: "Height"), value: watchLayout.binding(\.watchSize.height)) { max(10.0, $0) } completion: {
                        AppDelegate.instance?.watchPanel.panelPosition()
                    }
                }
                HStack {
                    LayoutSettingCell(text: Text("圓角比例", comment: "Corner radius ratio"), value: watchLayout.binding(\.cornerRadiusRatio)) { min(1.0, max(0.0, $0)) }
                    LayoutSettingCell(text: Text("陰影大小", comment: "Shadow size"), value: watchLayout.binding(\.shadowSize)) { min(0.1, max(0.0, $0)) }
                }
            }
            Section(header: Text("字偏", comment: "Text Shift")) {
                HStack {
                    LayoutSettingCell(text: Text("大字平移", comment: "Height"), value: watchLayout.binding(\.centerTextOffset))
                    LayoutSettingCell(text: Text("大字縱移", comment: "Height"), value: watchLayout.binding(\.centerTextHOffset))
                }
                HStack {
                    LayoutSettingCell(text: Text("小字平移", comment: "Height"), value: watchLayout.binding(\.horizontalTextOffset))
                    LayoutSettingCell(text: Text("小字縱移", comment: "Height"), value: watchLayout.binding(\.verticalTextOffset))
                }
            }
#endif
        }
        .formStyle(.grouped)
        .navigationTitle(Text("佈局", comment: "Layout settings section"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
                watchSetting.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#elseif os(macOS)
        .onChange(of: watchLayout.statusBar) { _, _ in
            if let delegate = AppDelegate.instance {
                delegate.updateStatusBar(dateText: delegate.statusBar(from: chineseCalendar, options: watchLayout))
            }
        }
        .task {
            fontHandler.textFont = watchLayout.textFont
            fontHandler.centerFont = watchLayout.centerFont
        }
#endif
    }
}

#Preview("LayoutSetting") {
    LayoutSetting()
}
