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
            Section("PLANETS") {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("MERCURY"), color: viewModel.binding(\.baseLayout.planetIndicator.mercury))
                    Divider()
                    ColorSettingCell(text: Text("VENUS"), color: viewModel.binding(\.baseLayout.planetIndicator.venus))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("MARS"), color: viewModel.binding(\.baseLayout.planetIndicator.mars))
                    Divider()
                    ColorSettingCell(text: Text("JUPYTER"), color: viewModel.binding(\.baseLayout.planetIndicator.jupiter))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("SATURN"), color: viewModel.binding(\.baseLayout.planetIndicator.saturn))
                    Divider()
                    ColorSettingCell(text: Text("MOON"), color: viewModel.binding(\.baseLayout.planetIndicator.moon))
                }
            }

            Section("MP_&_ST") {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("NEW_MOON"), color: viewModel.binding(\.baseLayout.eclipseIndicator))
                    Divider()
                    ColorSettingCell(text: Text("FULL_MOON"), color: viewModel.binding(\.baseLayout.fullmoonIndicator))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("ODD_ST"), color: viewModel.binding(\.baseLayout.oddStermIndicator))
                    Divider()
                    ColorSettingCell(text: Text("EVEN_ST"), color: viewModel.binding(\.baseLayout.evenStermIndicator))
                }
            }

            Section("SUNRISE_SET") {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("SUNRISE"), color: viewModel.binding(\.baseLayout.sunPositionIndicator.sunrise))
                    Divider()
                    ColorSettingCell(text: Text("NOON"), color: viewModel.binding(\.baseLayout.sunPositionIndicator.noon))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("SUNSET"), color: viewModel.binding(\.baseLayout.sunPositionIndicator.sunset))
                    Divider()
                    ColorSettingCell(text: Text("MID_NIGHT"), color: viewModel.binding(\.baseLayout.sunPositionIndicator.midnight))
                }
            }

            Section("MOONRISE_SET") {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("MOONRISE"), color: viewModel.binding(\.baseLayout.moonPositionIndicator.moonrise))
                    Divider()
                    ColorSettingCell(text: Text("LUNAR_NOON"), color: viewModel.binding(\.baseLayout.moonPositionIndicator.highMoon))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("MOONSET"), color: viewModel.binding(\.baseLayout.moonPositionIndicator.moonset))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("COLOR_MARKS")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("DONE") {
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
