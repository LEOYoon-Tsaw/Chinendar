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
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
    
    var body: some View {
        Form {
            Section(header: Text("五星", comment: "Planets")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("辰", comment: ""), color: watchLayout.binding(\.planetIndicator[0]))
                    Divider()
                    ColorSettingCell(text: Text("太白", comment: ""), color: watchLayout.binding(\.planetIndicator[1]))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("熒惑", comment: ""), color: watchLayout.binding(\.planetIndicator[2]))
                    Divider()
                    ColorSettingCell(text: Text("歲", comment: ""), color: watchLayout.binding(\.planetIndicator[3]))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("填", comment: ""), color: watchLayout.binding(\.planetIndicator[4]))
                    Divider()
                    ColorSettingCell(text: Text("月", comment: ""), color: watchLayout.binding(\.planetIndicator[5]))
                }
            }
            
            Section(header: Text("朔望節氣", comment: "Moon phase and Solor terms")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("朔", comment: ""), color: watchLayout.binding(\.eclipseIndicator))
                    Divider()
                    ColorSettingCell(text: Text("望", comment: ""), color: watchLayout.binding(\.fullmoonIndicator))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("節氣", comment: ""), color: watchLayout.binding(\.oddStermIndicator))
                    Divider()
                    ColorSettingCell(text: Text("中氣", comment: ""), color: watchLayout.binding(\.evenStermIndicator))
                }
            }
            
            Section(header: Text("日出入", comment: "Sunrise & Sunset Indicators")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("日出", comment: ""), color: watchLayout.binding(\.sunPositionIndicator[1]))
                    Divider()
                    ColorSettingCell(text: Text("日中", comment: ""), color: watchLayout.binding(\.sunPositionIndicator[2]))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("日入", comment: ""), color: watchLayout.binding(\.sunPositionIndicator[3]))
                    Divider()
                    ColorSettingCell(text: Text("夜中", comment: ""), color: watchLayout.binding(\.sunPositionIndicator[0]))
                }
            }
            
            Section(header: Text("月出入", comment: "Moonrise & Moonset")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("月出", comment: ""), color: watchLayout.binding(\.moonPositionIndicator[0]))
                    Divider()
                    ColorSettingCell(text: Text("月中", comment: ""), color: watchLayout.binding(\.moonPositionIndicator[1]))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("月入", comment: ""), color: watchLayout.binding(\.moonPositionIndicator[2]))
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
