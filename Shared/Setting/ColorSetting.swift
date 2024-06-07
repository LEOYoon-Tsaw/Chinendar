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
    @Environment(WatchLayout.self) var watchLayout
    @Environment(WatchSetting.self) var watchSetting

    var body: some View {
        Form {
            Section(header: Text("五星", comment: "Planets")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("辰", comment: ""), color: watchLayout.binding(\.planetIndicator.mercury))
                    Divider()
                    ColorSettingCell(text: Text("太白", comment: ""), color: watchLayout.binding(\.planetIndicator.venus))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("熒惑", comment: ""), color: watchLayout.binding(\.planetIndicator.mars))
                    Divider()
                    ColorSettingCell(text: Text("歲", comment: ""), color: watchLayout.binding(\.planetIndicator.jupiter))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("填", comment: ""), color: watchLayout.binding(\.planetIndicator.saturn))
                    Divider()
                    ColorSettingCell(text: Text("月", comment: ""), color: watchLayout.binding(\.planetIndicator.moon))
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
                    ColorSettingCell(text: Text("日出", comment: ""), color: watchLayout.binding(\.sunPositionIndicator.sunrise))
                    Divider()
                    ColorSettingCell(text: Text("日中", comment: ""), color: watchLayout.binding(\.sunPositionIndicator.noon))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("日入", comment: ""), color: watchLayout.binding(\.sunPositionIndicator.sunset))
                    Divider()
                    ColorSettingCell(text: Text("夜中", comment: ""), color: watchLayout.binding(\.sunPositionIndicator.midnight))
                }
            }

            Section(header: Text("月出入", comment: "Moonrise & Moonset")) {
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("月出", comment: ""), color: watchLayout.binding(\.moonPositionIndicator.moonrise))
                    Divider()
                    ColorSettingCell(text: Text("月中", comment: ""), color: watchLayout.binding(\.moonPositionIndicator.highMoon))
                }
                HStack(spacing: 20) {
                    ColorSettingCell(text: Text("月入", comment: ""), color: watchLayout.binding(\.moonPositionIndicator.moonset))
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
    let watchLayout = WatchLayout()
    let watchSetting = WatchSetting()
    watchLayout.loadStatic()
    return ColorSetting()
        .environment(watchLayout)
        .environment(watchSetting)

}
