//
//  Config.swift
//  Chinendar Watch
//
//  Created by Leo Liu on 3/30/24.
//

import SwiftUI
import SwiftData

struct ConfigList: View {
    @Query(filter: ConfigData.predicate, sort: \ConfigData.modifiedDate, order: .reverse) private var configs: [ConfigData]
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    @State private var target: ConfigData?
    @State private var showSwitch = false

    var body: some View {
        List {
            Section {
                Toggle("SYNC_PHONE", isOn: viewModel.binding(\.watchLayout.syncFromPhone))
            }
            Section {
                let data = try! ConfigData(CalendarConfigure(), name: AppInfo.defaultName)
                Button {
                    target = data
                    showSwitch = true
                } label: {
                    CalendarRow(configData: data, showTime: false)
                }
                .disabled(viewModel.watchLayout.syncFromPhone)
                ForEach(configs, id: \.id) { config in
                    Button {
                        target = config
                        showSwitch = true
                    } label: {
                        CalendarRow(configData: config, showTime: true)
                    }
                    .disabled(viewModel.watchLayout.syncFromPhone)
                }
            }
            .buttonStyle(.plain)
            .switchAlert(isPresented: $showSwitch, config: $target)
        }
        .onAppear {
            cleanup()
        }
        .navigationTitle("CALENDAR_LIST")
    }

    private func cleanup() {
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
}

private struct SwitchAlert: ViewModifier {
    @Environment(ViewModel.self) private var viewModel
    @Binding var isPresented: Bool
    @Binding var configData: ConfigData?

    func body(content: Content) -> some View {
        if let configData {
            content
                .alert(Text("SWITCH_TO:\(configData.nonNilName)"), isPresented: $isPresented) {
                    Button("CANCEL", role: .cancel) { self.configData = nil }
                    Button("CONFIRM", role: .destructive) {
                        if let newConfig = configData.config {
                            viewModel.config = newConfig
                        }
                        self.configData = nil
                    }
                }
        } else {
            content
        }
    }
}

fileprivate extension View {
    func switchAlert(isPresented: Binding<Bool>, config: Binding<ConfigData?>) -> some View {
        self.modifier(SwitchAlert(isPresented: isPresented, configData: config))
    }
}

#Preview("ConfigList", traits: .modifier(SampleData())) {
    ConfigList()
}
