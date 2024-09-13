//
//  ColorSetting.swift
//  Chinendar
//
//  Created by Leo Liu on 6/23/23.
//

import SwiftUI

struct ColorSettingCell: View {
    let text: Text
    @Binding var color: CGColor

    var body: some View {
        HStack {
            text
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 10)
            ColorPicker("", selection: $color)
                .labelsHidden()
        }
    }
}

struct ColorSetting: View {
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        Form {
            Section(header: Text("五星", comment: "Planets")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("辰星", comment: ""), color: viewModel.binding(\.baseLayout.planetIndicator.mercury))
                    Divider()
                    ColorSettingCell(text: Text("太白", comment: ""), color: viewModel.binding(\.baseLayout.planetIndicator.venus))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("熒惑", comment: ""), color: viewModel.binding(\.baseLayout.planetIndicator.mars))
                    Divider()
                    ColorSettingCell(text: Text("歲星", comment: ""), color: viewModel.binding(\.baseLayout.planetIndicator.jupiter))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("填星", comment: ""), color: viewModel.binding(\.baseLayout.planetIndicator.saturn))
                    Divider()
                    ColorSettingCell(text: Text("太陰", comment: ""), color: viewModel.binding(\.baseLayout.planetIndicator.moon))
                }
            }

            Section(header: Text("朔望節氣", comment: "Moon phase and Solor terms")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("朔", comment: ""), color: viewModel.binding(\.baseLayout.eclipseIndicator))
                    Divider()
                    ColorSettingCell(text: Text("望", comment: ""), color: viewModel.binding(\.baseLayout.fullmoonIndicator))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("節氣", comment: ""), color: viewModel.binding(\.baseLayout.oddStermIndicator))
                    Divider()
                    ColorSettingCell(text: Text("中氣", comment: ""), color: viewModel.binding(\.baseLayout.evenStermIndicator))
                }
            }

            Section(header: Text("日出入", comment: "Sunrise & Sunset Indicators")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("日出", comment: ""), color: viewModel.binding(\.baseLayout.sunPositionIndicator.sunrise))
                    Divider()
                    ColorSettingCell(text: Text("日中", comment: ""), color: viewModel.binding(\.baseLayout.sunPositionIndicator.noon))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("日入", comment: ""), color: viewModel.binding(\.baseLayout.sunPositionIndicator.sunset))
                    Divider()
                    ColorSettingCell(text: Text("夜中", comment: ""), color: viewModel.binding(\.baseLayout.sunPositionIndicator.midnight))
                }
            }

            Section(header: Text("月出入", comment: "Moonrise & Moonset")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("月出", comment: ""), color: viewModel.binding(\.baseLayout.moonPositionIndicator.moonrise))
                    Divider()
                    ColorSettingCell(text: Text("月中", comment: ""), color: viewModel.binding(\.baseLayout.moonPositionIndicator.highMoon))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("月入", comment: ""), color: viewModel.binding(\.baseLayout.moonPositionIndicator.moonset))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("色塊", comment: "Mark Color settings"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
                viewModel.settings.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#endif
    }
}

#Preview("Color Setting", traits: .modifier(SampleData())) {
    ColorSetting()
}
