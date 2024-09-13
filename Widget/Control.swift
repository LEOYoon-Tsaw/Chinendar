//
//  Control.swift
//  Chinendar
//
//  Created by Leo Liu on 8/9/24.
//

import WidgetKit
import SwiftUI
import AppIntents

struct OpenAppButton: ControlWidget {
    static let kind: String = "OpenCinendar"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "Yuncao-Liu.ChineseTime.OpenCinendar"
        ) {
            ControlWidgetButton(action: OpenApp()) {
                Label("打開華曆", image: .appChinendar)
            }
        }
        .displayName("打開華曆")
        .description("打開華曆查看當前日時")
    }
}

struct OpenApp: OpenIntent {
    static var title: LocalizedStringResource { "打開華曆" }
    
    @Parameter(title: "選日曆")
    var target: ConfigIntent
}
