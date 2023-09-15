//
//  ColorSetting.swift
//  Chinese Time iOS
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
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
    
    var body: some View {
        Form {
            Section(header: Text("五星", comment: "Planets")) {
                HStack() {
                    ColorSettingCell(text: Text("辰", comment: "Mercury Indicator"), color: watchLayout.binding(\.planetIndicator[0]))
                    Spacer(minLength: 30)
                    ColorSettingCell(text: Text("太白", comment: "Venus Indicator"), color: watchLayout.binding(\.planetIndicator[1]))
                }
                HStack() {
                    ColorSettingCell(text: Text("熒惑", comment: "Mars Indicator"), color: watchLayout.binding(\.planetIndicator[2]))
                    Spacer(minLength: 30)
                    ColorSettingCell(text: Text("歲", comment: "Jupiter Indicator"), color: watchLayout.binding(\.planetIndicator[3]))
                }
                HStack() {
                    ColorSettingCell(text: Text("鎮", comment: "Saturn Indicator"), color: watchLayout.binding(\.planetIndicator[4]))
                    Spacer(minLength: 30)
                    ColorSettingCell(text: Text("月", comment: "Moon position Indicator"), color: watchLayout.binding(\.planetIndicator[5]))
                }
            }
            
            Section(header: Text("朔望節氣", comment: "Moon phase and Solor terms")) {
                HStack {
                    ColorSettingCell(text: Text("朔", comment: "New Moon Indicator"), color: watchLayout.binding(\.eclipseIndicator))
                    Spacer(minLength: 30)
                    ColorSettingCell(text: Text("望", comment: "Full Moon Indicator"), color: watchLayout.binding(\.fullmoonIndicator))
                }
                HStack {
                    ColorSettingCell(text: Text("節氣", comment: "Odd Solar Term Indicator"), color: watchLayout.binding(\.oddStermIndicator))
                    Spacer(minLength: 30)
                    ColorSettingCell(text: Text("中氣", comment: "Even Solar Term Indicator"), color: watchLayout.binding(\.evenStermIndicator))
                }
            }
            
            Section(header: Text("日出入", comment: "Sunrise & Sunset Indicators")) {
                HStack {
                    ColorSettingCell(text: Text("日出", comment: "Sunrise Indicator"), color: watchLayout.binding(\.sunPositionIndicator[1]))
                    Spacer(minLength: 30)
                    ColorSettingCell(text: Text("日中", comment: "Noon Indicator"), color: watchLayout.binding(\.sunPositionIndicator[2]))
                }
                HStack {
                    ColorSettingCell(text: Text("日入", comment: "Sunset Indicator"), color: watchLayout.binding(\.sunPositionIndicator[3]))
                    Spacer(minLength: 30)
                    ColorSettingCell(text: Text("夜中", comment: "Midnight Indicator"), color: watchLayout.binding(\.sunPositionIndicator[0]))
                }
            }
            
            Section(header: Text("月出入", comment: "Moonrise & Moonset")) {
                HStack {
                    ColorSettingCell(text: Text("月出", comment: "Moonrise Indicator"), color: watchLayout.binding(\.moonPositionIndicator[0]))
                    Spacer(minLength: 30)
                    ColorSettingCell(text: Text("月中", comment: "Lunar noon Indicator"), color: watchLayout.binding(\.moonPositionIndicator[1]))
                }
                HStack {
                    ColorSettingCell(text: Text("月入", comment: "Moonset Indicator"), color: watchLayout.binding(\.moonPositionIndicator[2]))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("色塊", comment: "Mark Color settings"))
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

#Preview("Color Setting") {
    ColorSetting()
}
