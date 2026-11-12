//
//  LayoutSetting.swift
//  Chinendar
//
//  Created by Leo Liu on 6/23/23.
//

import SwiftUI
import Observation
#if os(macOS)
import CoreText
#endif

struct LayoutSetting: View {
    @Environment(ViewModel.self) var viewModel
    static let nameMapping = [
        " ": LocalizedStringKey("SPACE"),
        "・": LocalizedStringKey("・"),
        "": LocalizedStringKey("NONE"),
        ", ": LocalizedStringKey("COMMA")
    ]
#if os(macOS)
    @State var fontHandler = FontHandler()
#endif

    var body: some View {
        Form {
            Section("LANGUAGE") {
                Toggle("CHINENDAR_DISPLAY_IN_NATIVE", isOn: viewModel.binding(\.baseLayout.nativeLanguage))
            }
            Section("STATUS_BAR") {
                HStack(spacing: 20) {
                    Toggle("DATE", isOn: viewModel.binding(\.watchLayout.statusBar.date))
                    Divider()
                    Toggle("TIME", isOn: viewModel.binding(\.watchLayout.statusBar.time))
                }
#if os(iOS)
                holidayPicker
                separatorPicker
#else
                HStack(spacing: 20) {
                    holidayPicker
                    Divider()
                    separatorPicker
                }
#endif
            }
#if os(macOS)
            Section("FONT") {
                if fontHandler.isLoaded {
                    HStack(spacing: 20) {
                        Picker("TEXT_FONT", selection: $fontHandler.textFontSelection) {
                            ForEach(fontHandler.allFonts, id: \.self) { family in
                                Text(family)
                            }
                        }
                        Divider()
                        Picker("FONT_WEIGHT", selection: $fontHandler.textFontMemberSelection) {
                            ForEach(fontHandler.textFontMembers, id: \.self) { member in
                                Text(member)
                            }
                        }
                        .labelsHidden()
                    }

                    HStack(spacing: 20) {
                        Picker("CENTER_TEXT_FONT", selection: $fontHandler.centerFontSelection) {
                            ForEach(fontHandler.allFonts, id: \.self) { family in
                                Text(family)
                            }
                        }
                        Divider()
                        Picker("FONT_WEIGHT", selection: $fontHandler.centerFontMemberSelection) {
                            ForEach(fontHandler.centerFontMembers, id: \.self) { member in
                                Text(member)
                            }
                        }
                        .labelsHidden()
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
                .onChange(of: fontHandler.textFont) { previousFont, font in
                    if previousFont != nil, let font, font.fontName != viewModel.watchLayout.textFont.fontName {
                        viewModel.watchLayout.textFont = font
                    }
                }

                .onChange(of: fontHandler.centerFont) { previousFont, font in
                    if previousFont != nil, let font, font.fontName != viewModel.watchLayout.centerFont.fontName {
                        viewModel.watchLayout.centerFont = font
                    }
                }
#endif
#if os(iOS)
            Section("SHAPE") {
                LayoutSettingCell(text: viewModel.settings.vertical ? Text("WIDTH") : Text("HEIGHT"), value: viewModel.binding(\.baseLayout.offsets.watchSize.width)) { max(10.0, $0) }
                LayoutSettingCell(text: viewModel.settings.vertical ? Text("HEIGHT") : Text("WIDTH"), value: viewModel.binding(\.baseLayout.offsets.watchSize.height)) { max(10.0, $0) }
                SliderView(value: viewModel.binding(\.baseLayout.offsets.cornerRadiusRatio), min: 0, max: 1, label: Text("CORNER_RD_RATIO"))
                SliderView(value: viewModel.binding(\.baseLayout.colors.shadowSize), min: 0, max: 0.1, label: Text("SHADOW_SIZE"))
            }
            Section(header: Text("TEXT_OFFSET")) {
                LayoutSettingCell(text: Text("CENTER_TEXT_H_OFFSET"), value: viewModel.binding(\.baseLayout.offsets.centerTextOffset.width))
                LayoutSettingCell(text: Text("CENTER_TEXT_V_OFFSET"), value: viewModel.binding(\.baseLayout.offsets.centerTextOffset.height))
                LayoutSettingCell(text: Text("TEXT_H_OFFSET"), value: viewModel.binding(\.baseLayout.offsets.textOffset.width))
                LayoutSettingCell(text: Text("TEXT_V_OFFSET"), value: viewModel.binding(\.baseLayout.offsets.textOffset.height))
            }
#elseif os(macOS) || os(visionOS)
            Section("SHAPE") {
#if os(macOS)
                HStack(spacing: 20) {
                    LayoutSettingCell(text: Text("WIDTH"), value: viewModel.binding(\.baseLayout.offsets.watchSize.width)) { max(10.0, $0) }
                    Divider()
                    LayoutSettingCell(text: Text("HEIGHT"), value: viewModel.binding(\.baseLayout.offsets.watchSize.height)) { max(10.0, $0) }
                }
#endif
                SliderView(value: viewModel.binding(\.baseLayout.offsets.cornerRadiusRatio), min: 0, max: 1, label: Text("CORNER_RD_RATIO"))
                SliderView(value: viewModel.binding(\.baseLayout.colors.shadowSize), min: 0, max: 0.1, label: Text("SHADOW_SIZE"))
            }
            Section("TEXT_OFFSET") {
                HStack(spacing: 20) {
                    LayoutSettingCell(text: Text("CENTER_TEXT_H_OFFSET"), value: viewModel.binding(\.baseLayout.offsets.centerTextOffset.width))
                    Divider()
                    LayoutSettingCell(text: Text("CENTER_TEXT_V_OFFSET"), value: viewModel.binding(\.baseLayout.offsets.centerTextOffset.height))
                }
                HStack(spacing: 20) {
                    LayoutSettingCell(text: Text("TEXT_H_OFFSET"), value: viewModel.binding(\.baseLayout.offsets.textOffset.width))
                    Divider()
                    LayoutSettingCell(text: Text("TEXT_V_OFFSET"), value: viewModel.binding(\.baseLayout.offsets.textOffset.height))
                }
            }
#endif
        }
        .formStyle(.grouped)
        .navigationTitle("LAYOUTS")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                viewModel.settings.presentSetting = false
            } label: {
                Label("DONE", systemImage: "checkmark")
            }
            .fontWeight(.semibold)
        }
#elseif os(macOS)
        .task {
            await fontHandler.load(textFont: viewModel.watchLayout.textFont, centerFont: viewModel.watchLayout.centerFont)
        }
#endif
    }

    var holidayPicker: some View {
        Picker("NUMBER_OF_HOLIDAY", selection: viewModel.binding(\.watchLayout.statusBar.holiday)) {
            ForEach(0...2, id: \.self) { Text(String($0)) }
        }
    }

    var separatorPicker: some View {
        Picker("SEPARATOR", selection: viewModel.binding(\.watchLayout.statusBar.separator)) {
            ForEach(StatusBar.Separator.allCases, id: \.self) { separator in
                if let label = LayoutSetting.nameMapping[separator.rawValue] {
                    Text(label)
                } else {
                    Text(separator.rawValue)
                }
            }
        }
    }
}

struct LayoutSettingCell<V: Numeric>: View {
    let text: Text
    @Binding var value: V
    let validation: ((V) -> V)?
    @State var tempValue: V
    @FocusState var isFocused: Bool

    init(text: Text, value: Binding<V>, validation: ((V) -> V)? = nil) {
        self.text = text
        self._value = value
        self.validation = validation
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
#if os(iOS) || os(visionOS)
            .keyboardType(.decimalPad)
#endif
            .focused($isFocused)
            .autocorrectionDisabled()
            .onSubmit(of: .text) {
                commit()
            }
            .onChange(of: isFocused) {
                if !isFocused {
                    commit()
                }
            }
            .onAppear {
                tempValue = value
            }
#if os(iOS)
            .padding(.vertical, 5)
#elseif os(macOS)
            .frame(height: 20)
#elseif os(visionOS)
            .frame(height: 40)
#endif
            .padding(.leading, 15)
#if os(iOS) || os(visionOS)
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(.hoverEffect, .rect(cornerRadius: 10, style: .continuous))
            .hoverEffect()
#elseif os(macOS)
            .background(in: RoundedRectangle(cornerRadius: 10))
#endif
        }
    }

    func commit() {
        if let validation {
            tempValue = validation(tempValue)
        }
        value = tempValue
    }
}

#if os(macOS)
@MainActor
@Observable final class FontHandler {
    static let systemFontName = NSFont.systemFont(ofSize: NSFont.systemFontSize).familyName ?? "MissingSstemFont"
    private(set) var allFonts = [String]()
    private(set) var isLoaded = false
    private var fontMembers = [String: [Member]]()
    var textFontSelection = "" {
        didSet {
            textFontMemberSelection = textFontMembers.first ?? ""
        }
    }
    var textFontMemberSelection = ""
    var centerFontSelection = "" {
        didSet {
            centerFontMemberSelection = centerFontMembers.first ?? ""
        }
    }
    var centerFontMemberSelection = ""

    var textFontMembers: [String] {
        fontMembers[textFontSelection]?.map(\.style) ?? []
    }

    var centerFontMembers: [String] {
        fontMembers[centerFontSelection]?.map(\.style) ?? []
    }

    var textFont: NSFont? {
        readFont(family: textFontSelection, style: textFontMemberSelection)
    }

    var centerFont: NSFont? {
        readFont(family: centerFontSelection, style: centerFontMemberSelection)
    }

    func load(textFont: NSFont, centerFont: NSFont) async {
        isLoaded = false
        let textSelection = Selection(font: textFont)
        let centerSelection = Selection(font: centerFont)
        guard let catalog = try? await Self.loadCatalog(systemFamily: Self.systemFontName, selections: [textSelection, centerSelection]), !Task.isCancelled else { return }
        fontMembers = catalog.members
        allFonts = catalog.families
        textFontSelection = textSelection.family
        textFontMemberSelection = textSelection.member.style
        centerFontSelection = centerSelection.family
        centerFontMemberSelection = centerSelection.member.style
        isLoaded = true
    }

    private func readFont(family: String, style: String) -> NSFont? {
        guard isLoaded, let member = fontMembers[family]?.first(where: { $0.style == style }) else { return nil }
        return NSFont(name: member.postScriptName, size: NSFont.systemFontSize)
    }

    private struct Member: Sendable {
        let style: String
        let postScriptName: String
    }

    private struct Selection: Sendable {
        let family: String
        let member: Member

        @MainActor init(font: NSFont) {
            family = font.familyName ?? FontHandler.systemFontName
            member = Member(style: font.fontDescriptor.object(forKey: .face) as? String ?? "Regular", postScriptName: font.fontName)
        }
    }

    private struct Catalog: Sendable {
        var families: [String]
        var members: [String: [Member]]
    }

    @concurrent
    private static func loadCatalog(systemFamily: String, selections: [Selection]) async throws -> Catalog {
        try Task.checkCancellation()
        // Core Text font management is thread-safe; only the selected NSFonts are created on the main actor.
        let collection = CTFontCollectionCreateFromAvailableFonts([kCTFontCollectionRemoveDuplicatesOption: true] as CFDictionary)
        let availableFamilies = CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []
        var catalog = Catalog(families: [systemFamily] + availableFamilies.filter { $0 != systemFamily }, members: [:])
        var descriptors = CTFontCollectionCreateMatchingFontDescriptors(collection) as? [CTFontDescriptor] ?? []
        // The system family and a selected hidden font may be absent from the visible-font collection.
        for family in Set([systemFamily] + selections.map(\.family)) {
            try Task.checkCancellation()
            descriptors += CTFontCollectionCreateMatchingFontDescriptorsForFamily(collection, family as CFString, nil) as? [CTFontDescriptor] ?? []
            if !catalog.families.contains(family) {
                catalog.families.append(family)
            }
        }
        for descriptor in descriptors {
            try Task.checkCancellation()
            guard let family = CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute) as? String,
                  let style = CTFontDescriptorCopyAttribute(descriptor, kCTFontStyleNameAttribute) as? String,
                  let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String,
                  !(catalog.members[family]?.contains(where: { $0.style == style }) ?? false) else { continue }
            catalog.members[family, default: []].append(Member(style: style, postScriptName: name))
        }
        for selection in selections {
            var members = catalog.members[selection.family] ?? []
            if let index = members.firstIndex(where: { $0.style == selection.member.style }) {
                members[index] = selection.member
            } else {
                members.append(selection.member)
            }
            catalog.members[selection.family] = members
        }
        try Task.checkCancellation()
        return catalog
    }
}
#endif

#if DEBUG
#Preview("LayoutSetting", traits: .modifier(SampleData())) {
    NavigationStack {
        LayoutSetting()
    }
}
#endif
