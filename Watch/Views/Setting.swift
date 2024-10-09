//
//  Setting.swift
//  Chinendar
//
//  Created by Leo Liu on 6/26/23.
//

import SwiftUI

struct Setting: View {
    @Environment(ViewModel.self) var viewModel
    @Environment(\.modelContext) var modelContext
    let range: ClosedRange<CGFloat> = 0.3...0.9
    let step: CGFloat = 0.1
    var dualWatch: Binding<Bool> {
        .init(get: { viewModel.watchLayout.dualWatch }, set: { newValue in
            viewModel.watchLayout.dualWatch = newValue
        })
    }
    var cornerRadius: Binding<CGFloat> {
        .init(get: { viewModel.baseLayout.cornerRadiusRatio }, set: { newValue in
            viewModel.baseLayout.cornerRadiusRatio = newValue
        })
    }

    var body: some View {
        List {
            Section {
                Stepper(value: cornerRadius, in: range, step: step) {
                    Text(String(format: "%.1f", cornerRadius.wrappedValue))
                        .font(.title.bold())
                        .fontDesign(.rounded)
                }
                .focusable(false)
            } header: {
                Text("CORNER_RD_RATIO")
            }

            Section {
                NavigationLink {
                    DateTimeAdjust()
                } label: {
                    Text("ALT_TIME")
                }
                NavigationLink {
                    SwitchConfig()
                } label: {
                    Text("CALENDAR_LIST")
                }
                Toggle("SPLIT_DATE_TIME", isOn: dualWatch)
            } footer: {
                Text("WATCH_SETTING_MSG", comment: "Hint for syncing between watch and phone")
            }
        }
        .navigationTitle("SETTINGS")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview("Setting", traits: .modifier(SampleData())) {
    NavigationStack {
        Setting()
    }
}
