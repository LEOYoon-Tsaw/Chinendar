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
            Text("明", comment: "Light theme")
                .lineLimit(1)
                .frame(alignment: .trailing)
                .padding(.horizontal, 5)
            ColorPicker("", selection: $color)
                .labelsHidden()
                .padding(.trailing, 10)
            Divider()
            Text("暗", comment: "dark theme")
                .lineLimit(1)
                .frame(alignment: .trailing)
                .padding(.horizontal, 5)
            ColorPicker("", selection: $darkColor)
                .labelsHidden()

        }
    }
}

struct DecorationSetting: View {
    @Environment(WatchLayout.self) var watchLayout
    @Environment(WatchSetting.self) var watchSetting
    
    var body: some View {
        Form {
            Section(header: Text("透明度", comment: "Transparency sliders")) {
                SliderView(value: watchLayout.binding(\.shadeAlpha), min: 0, max: 1, label: Text("殘圈透明", comment: "Inactive ring opacity"))
                SliderView(value: watchLayout.binding(\.majorTickAlpha), min: 0, max: 1, label: Text("大刻透明", comment: "Major Tick opacity"))
                SliderView(value: watchLayout.binding(\.minorTickAlpha), min: 0, max: 1, label: Text("小刻透明", comment: "Minor Tick opacity"))
            }
            Section(header: Text("明暗主題色", comment: "Watch face colors in light and dark themes")) {
#if os(visionOS)
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("大刻色", comment: "Major tick color"), color: watchLayout.binding(\.majorTickColorDark))
                    Divider()
                    ColorSettingCell(text: Text("小刻色", comment: "Major tick color"), color: watchLayout.binding(\.minorTickColorDark))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("節氣刻", comment: "Major tick color"), color: watchLayout.binding(\.oddSolarTermTickColorDark))
                    Divider()
                    ColorSettingCell(text: Text("中氣刻", comment: "Major tick color"), color: watchLayout.binding(\.evenSolarTermTickColorDark))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("小字", comment: "Major tick color"), color: watchLayout.binding(\.fontColorDark))
                    Divider()
                    ColorSettingCell(text: Text("核", comment: "Major tick color"), color: watchLayout.binding(\.innerColorDark))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("底輪", comment: "Ring background"), color: watchLayout.binding(\.backColorDark))
                }
#else
                ThemedColorSettingCell(text: Text("大刻色", comment: "Major tick color"), color: watchLayout.binding(\.majorTickColor), darkColor: watchLayout.binding(\.majorTickColorDark))
                ThemedColorSettingCell(text: Text("小刻色", comment: "Major tick color"), color: watchLayout.binding(\.minorTickColor), darkColor: watchLayout.binding(\.minorTickColorDark))
                ThemedColorSettingCell(text: Text("節氣刻", comment: "Major tick color"), color: watchLayout.binding(\.oddSolarTermTickColor), darkColor: watchLayout.binding(\.oddSolarTermTickColorDark))
                ThemedColorSettingCell(text: Text("中氣刻", comment: "Major tick color"), color: watchLayout.binding(\.evenSolarTermTickColor), darkColor: watchLayout.binding(\.evenSolarTermTickColorDark))
                ThemedColorSettingCell(text: Text("小字", comment: "Major tick color"), color: watchLayout.binding(\.fontColor), darkColor: watchLayout.binding(\.fontColorDark))
                ThemedColorSettingCell(text: Text("核", comment: "Major tick color"), color: watchLayout.binding(\.innerColor), darkColor: watchLayout.binding(\.innerColorDark))
                ThemedColorSettingCell(text: Text("底輪", comment: "Ring background"), color: watchLayout.binding(\.backColor), darkColor: watchLayout.binding(\.backColorDark))
#endif
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("裝飾", comment: "Add on Setting"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
                watchSetting.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#endif
    }
}

#Preview("Decoration Setting") {
    let watchLayout = WatchLayout()
    let watchSetting = WatchSetting()
    watchLayout.loadStatic()
    return DecorationSetting()
        .environment(watchLayout)
        .environment(watchSetting)
}
