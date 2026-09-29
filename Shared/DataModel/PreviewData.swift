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
        let modelConfig = ModelConfiguration("Chinendar", schema: fullSchema, isStoredInMemoryOnly: true, groupContainer: .none, cloudKitDatabase: .none)
        let container = try ModelContainer(for: fullSchema, configurations: [modelConfig])
        var layout = WatchLayout.defaultLayout
#if os(iOS) || os(macOS) || os(visionOS)
        layout.statusBar.date = true
        layout.statusBar.time = true
#endif
        let defaultTheme = try ThemeData(layout, name: "My Favorate", deviceName: AppInfo.deviceName)
        let defaultConfig = try ConfigData(CalendarConfigure(), name: "My Favorate")
        let defaultReminders = try RemindersData(ReminderList.defaultValue)
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
