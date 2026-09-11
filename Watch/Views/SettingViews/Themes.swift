//
//  Themes.swift
//  Chinendar
//
//  Created by Leo Liu on 1/21/25.
//

import SwiftUI
import SwiftData

struct ThemesList: View {
    @Query(filter: ThemeData.predicate, sort: [SortDescriptor(\ThemeData.deviceName), SortDescriptor(\ThemeData.modifiedDate, order: .reverse)], animation: .easeInOut, sectionBy: \.deviceName) private var dataStack: SectionedResults<ThemeData, String>
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    private let currentDeviceName = AppInfo.deviceName
    private var sections: [ResultsSection<ThemeData, String>] {
        _dataStack.sections.sorted { lhs, _ in
            lhs.title == currentDeviceName
        }
    }

    @State private var target: ThemeData?
    @State private var showSwitch = false

    var body: some View {
        List {
            Section {
                Toggle("SYNC_PHONE", isOn: viewModel.binding(\.watchLayout.syncFromPhone))
                if !viewModel.watchLayout.syncFromPhone {
                    Button {
                        let data = try! ThemeData(WatchLayout.defaultLayout, name: AppInfo.defaultName, deviceName: currentDeviceName)
                        target = data
                        showSwitch = true
                    } label: {
                        Text(AppInfo.defaultName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            ForEach(sections, id: \.id) { section in
                ThemeGroup(groupName: section.title, themes: section, isCurrentDevice: section.title == currentDeviceName)
            }
        }
        .animation(.easeInOut, value: viewModel.watchLayout.syncFromPhone)
        .switchAlert(isPresented: $showSwitch, theme: $target, isCurrentDevice: true)
        .onAppear {
            cleanup()
        }
        .navigationTitle("THEME_LIST")
    }

    private func cleanup() {
        var records = Set<[String]>()
        for section in _dataStack.sections {
            for data in section {
                if data.isNil {
                    modelContext.delete(data)
                } else {
                    if records.contains([data.name!, data.deviceName!]) {
                        modelContext.delete(data)
                    } else {
                        records.insert([data.name!, data.deviceName!])
                    }
                }
            }
        }
    }
}

struct ThemeGroup: View {
    @Environment(ViewModel.self) private var viewModel
    let groupName: String
    let themes: ResultsSection<ThemeData, String>
    let isCurrentDevice: Bool

    @State private var target: ThemeData?
    @State private var showSwitch = false

    var body: some View {
        Section {
            ForEach(themes, id: \.id) { theme in
                Button {
                    target = theme
                    showSwitch = true
                } label: {
                    ThemeRow(theme: theme)
                }
                .disabled(viewModel.watchLayout.syncFromPhone)
            }
        } header: {
            Text(groupName)
        }
        .buttonStyle(.plain)
        .switchAlert(isPresented: $showSwitch, theme: $target, isCurrentDevice: isCurrentDevice)
    }
}

struct ThemeRow: View {
    @Environment(ViewModel.self) private var viewModel
    let theme: ThemeData

    var body: some View {
        Button {
            viewModel.watchLayout ?= theme.instance
        } label: {
            Text(theme.nonNilName)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SwitchAlert: ViewModifier {
    @Environment(ViewModel.self) private var viewModel
    @Binding var isPresented: Bool
    @Binding var theme: ThemeData?
    let isCurrentDevice: Bool

    func body(content: Content) -> some View {
        if let theme {
            content
                .alert(Text("SWITCH_TO:\(theme.nonNilName)"), isPresented: $isPresented) {
                    Button("CANCEL", role: .cancel) { self.theme = nil }
                    Button("CONFIRM", role: .destructive) {
                        if let newLayout = theme.instance {
                            if isCurrentDevice {
                                viewModel.watchLayout = newLayout
                            } else {
                                viewModel.baseLayout = newLayout.baseLayout
                            }
                        }
                        self.theme = nil
                    }
                }
        } else {
            content
        }
    }
}

fileprivate extension View {
    func switchAlert(isPresented: Binding<Bool>, theme: Binding<ThemeData?>, isCurrentDevice: Bool) -> some View {
        self.modifier(SwitchAlert(isPresented: isPresented, theme: theme, isCurrentDevice: isCurrentDevice))
    }
}

#Preview("Themes", traits: .modifier(SampleData())) {
    ThemesList()
}
