//
//  PreviewData.swift
//  Chinendar
//
//  Created by Leo Liu on 6/16/24.
//

import SwiftData
import SwiftUI

struct SampleData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let fullSchema = Schema(versionedSchema: DataSchema.self)
        let modelConfig = ModelConfiguration("Chinendar", schema: fullSchema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: fullSchema, configurations: [modelConfig])
        let defaultTheme = ThemeData(deviceName: AppInfo.deviceName, name: AppInfo.defaultName, code: ThemeData.staticLayoutCode)
        let defaultConfig = ConfigData(name: AppInfo.defaultName, code: CalendarConfigure().encode())
        let defaultReminders = RemindersData(ReminderList.defaultValue)
        container.mainContext.insert(defaultReminders)
        container.mainContext.insert(defaultTheme)
        container.mainContext.insert(defaultConfig)
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        let viewModel = ViewModel.shared
        content
            .modelContainer(context)
            .environment(viewModel)
    }
 }
