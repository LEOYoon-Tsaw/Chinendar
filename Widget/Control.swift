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
                Label("LAUNCH_CHINENDAR", image: .appChinendar)
            }
        }
        .displayName("LAUNCH_CHINENDAR")
        .description("LAUNCH_CHINENDAR_MSG")
    }
}

struct OpenApp: OpenIntent {
    static let title = LocalizedStringResource("LAUNCH_CHINENDAR")

    @Parameter(title: "SELECT_CALENDAR")
    var target: ConfigIntent
}
