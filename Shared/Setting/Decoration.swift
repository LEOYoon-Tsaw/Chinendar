//
//  Decoration.swift
//  Chinendar
//
//  Created by Leo Liu on 1/16/24.
//

import SwiftUI

struct SliderView: View {
    @Binding var value: CGFloat
    @State var currentValue: CGFloat = 0
    let min: CGFloat
    let max: CGFloat
    let label: Text

    var body: some View {
#if os(iOS) || os(visionOS)
        VStack {
            HStack {
                label
                Spacer()

                let formatter: NumberFormatter = {
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 2
                    formatter.minimumFractionDigits = 0
                    return formatter
                }()
                Text(formatter.string(from: NSNumber(value: currentValue)) ?? "")
                    .frame(alignment: .trailing)
            }
            Slider(value: $currentValue, in: min...max, step: 0.01) { editing in
                if !editing {
                    value = currentValue
                }
            }
            .labelsHidden()
        }
        .onAppear {
            currentValue = value
        }
#elseif os(macOS)
        HStack {
            label
                .frame(maxWidth: 150, alignment: .leading)
            Slider(value: $currentValue, in: min...max, step: 0.01) { editing in
                if !editing {
                    value = currentValue
                }
            }
            .labelsHidden()

            let formatter: NumberFormatter = {
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 2
                formatter.minimumFractionDigits = 0
                return formatter
            }()
            Text(formatter.string(from: NSNumber(value: currentValue)) ?? "")
                .frame(maxWidth: 40, alignment: .trailing)
        }
        .onAppear {
            currentValue = value
        }
#endif
    }
}

struct ThemedColorSettingCell: View {
    let text: Text
    @Binding var color: CGColor
    @Binding var darkColor: CGColor

    var body: some View {
        HStack {
            text
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 10)
            Text("LIGHT")
                .lineLimit(1)
                .frame(alignment: .trailing)
                .padding(.horizontal, 5)
            ColorPicker("", selection: $color)
                .labelsHidden()
                .padding(.trailing, 10)
            Divider()
            Text("DARK")
                .lineLimit(1)
                .frame(alignment: .trailing)
                .padding(.horizontal, 5)
            ColorPicker("", selection: $darkColor)
                .labelsHidden()

        }
    }
}

struct DecorationSetting: View {
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        Form {
            Section("TRANSPARENCY") {
                SliderView(value: viewModel.binding(\.baseLayout.shadeAlpha), min: 0, max: 1, label: Text("OFF_RING_OPACITY"))
                SliderView(value: viewModel.binding(\.baseLayout.majorTickAlpha), min: 0, max: 1, label: Text("MJ_TICK_OPACITY"))
                SliderView(value: viewModel.binding(\.baseLayout.minorTickAlpha), min: 0, max: 1, label: Text("MN_TICK_OPACITY"))
            }
            Section("COLOR_IN_L/D") {
#if os(visionOS)
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("MJ_TICK_COLOR"), color: viewModel.binding(\.baseLayout.majorTickColorDark))
                    Divider()
                    ColorSettingCell(text: Text("MN_TICK_COLOR"), color: viewModel.binding(\.baseLayout.minorTickColorDark))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("ODD_ST_TICK_COLOR"), color: viewModel.binding(\.baseLayout.oddSolarTermTickColorDark))
                    Divider()
                    ColorSettingCell(text: Text("EVEN_ST_TICK_COLOR"), color: viewModel.binding(\.baseLayout.evenSolarTermTickColorDark))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("TEXT_COLOR"), color: viewModel.binding(\.baseLayout.fontColorDark))
                    Divider()
                    ColorSettingCell(text: Text("CENTER_BACK_COLOR"), color: viewModel.binding(\.baseLayout.innerColorDark))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("RING_BACK_COLOR"), color: viewModel.binding(\.baseLayout.backColorDark))
                }
#else
                ThemedColorSettingCell(text: Text("MJ_TICK_COLOR"), color: viewModel.binding(\.baseLayout.majorTickColor), darkColor: viewModel.binding(\.baseLayout.majorTickColorDark))
                ThemedColorSettingCell(text: Text("MN_TICK_COLOR"), color: viewModel.binding(\.baseLayout.minorTickColor), darkColor: viewModel.binding(\.baseLayout.minorTickColorDark))
                ThemedColorSettingCell(text: Text("ODD_ST_TICK_COLOR"), color: viewModel.binding(\.baseLayout.oddSolarTermTickColor), darkColor: viewModel.binding(\.baseLayout.oddSolarTermTickColorDark))
                ThemedColorSettingCell(text: Text("EVEN_ST_TICK_COLOR"), color: viewModel.binding(\.baseLayout.evenSolarTermTickColor), darkColor: viewModel.binding(\.baseLayout.evenSolarTermTickColorDark))
                ThemedColorSettingCell(text: Text("TEXT_COLOR"), color: viewModel.binding(\.baseLayout.fontColor), darkColor: viewModel.binding(\.baseLayout.fontColorDark))
                ThemedColorSettingCell(text: Text("CENTER_BACK_COLOR"), color: viewModel.binding(\.baseLayout.innerColor), darkColor: viewModel.binding(\.baseLayout.innerColorDark))
                ThemedColorSettingCell(text: Text("RING_BACK_COLOR"), color: viewModel.binding(\.baseLayout.backColor), darkColor: viewModel.binding(\.baseLayout.backColorDark))
#endif
            }
        }
        .formStyle(.grouped)
        .navigationTitle("ADDON_COLORS")
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

#Preview("Decoration Setting", traits: .modifier(SampleData())) {
    DecorationSetting()
}
