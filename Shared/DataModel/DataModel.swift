//
//  ThemeData.swift
//  Chinendar
//
//  Created by Leo Liu on 7/7/23.
//
//

import Foundation
import SwiftData
import CoreData
#if os(macOS)
import SystemConfiguration
#elseif os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(visionOS)
import VisionKit
#endif

private func intVersion(_ version: Schema.Version) -> Int {
    version.major * 100_0000 + version.minor * 1_0000 + version.patch * 100 + 1
}

private func createContainer(schema: Schema, migrationPlan: SchemaMigrationPlan.Type? = nil, configurations: [ModelConfiguration]) -> ModelContainer {
    do {
        return try ModelContainer(for: schema, migrationPlan: migrationPlan, configurations: configurations)
    } catch {
        print(error.localizedDescription)
        do {
            return try ModelContainer(for: schema, configurations: configurations)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

struct AppInfo {
#if os(macOS)
    static let deviceName = SCDynamicStoreCopyComputerName(nil, nil).map { String($0) } ?? "Mac"
#elseif os(iOS) || os(visionOS)
    @MainActor static let deviceName = UIDevice.current.name
#elseif os(watchOS)
    static let deviceName = WKInterfaceDevice.current().name
#endif
    static let defaultName = "__current_theme__"
}

@ModelActor
actor DataModel {
    static let shared = DataModel(modelContainer: DataSchema.container)

    func update(id: PersistentIdentifier, code: String) {
        guard let record = self[id, as: ThemeData.self] else { return }
        if record.code != code {
            record.code = code
            record.modifiedDate = Date.now
        }
        if (record.version ?? 0) < ThemeData.version {
            record.version = record.version
        }
        do {
            try modelContext.save()
        } catch {
            print("Error saving data: \(error.localizedDescription)")
        }
    }

    func allConfigNames() throws -> [String] {
        let descriptor = FetchDescriptor<ConfigData>(sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        let configs = try modelContext.fetch(descriptor)
        return configs.compactMap { $0.name }
    }
}

typealias DataSchema = DataSchemaV5
extension DataSchema {
    static let container = {
        let fullSchema = Schema(versionedSchema: DataSchema.self)
        let modelConfig = ModelConfiguration("Chinendar", schema: fullSchema, groupContainer: .automatic, cloudKitDatabase: .automatic)
        return createContainer(schema: fullSchema, migrationPlan: DataMigrationPlan.self, configurations: [modelConfig])
    }()
}

typealias ThemeData = DataSchema.Layout
extension ThemeData {
    static var version: Int {
        intVersion(DataSchema.versionIdentifier)
    }

    static let staticLayoutCode: String = {
        let filePath = Bundle.main.path(forResource: "layout", ofType: "txt")!
        let defaultLayout = try! String(contentsOfFile: filePath, encoding: .utf8)
        return defaultLayout
    }()

    var isNil: Bool {
        return code == nil || name == nil || deviceName == nil || modifiedDate == nil
    }

    @MainActor static func notLatest() -> Bool {
        let modelContext = DataSchema.container.mainContext
        let deviceName = AppInfo.deviceName
        let predicate = #Predicate<ThemeData> { data in
            data.deviceName == deviceName && data.version != nil
        }
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        descriptor.fetchLimit = 1
        if let latestEntry = try? modelContext.fetch(descriptor).first {
            if (latestEntry.version ?? 0) < ThemeData.version {
                latestEntry.version = ThemeData.version
                try? modelContext.save()
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }

    @MainActor static func experienced() -> Bool {
        let modelContext = DataSchema.container.mainContext
        let predicate = #Predicate<ThemeData> { data in
            data.modifiedDate != nil
        }
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate)])
        let counts = try? modelContext.fetchCount(descriptor)
        descriptor.fetchLimit = 1
        let date = try? modelContext.fetch(descriptor).first?.modifiedDate

        if let date, let counts, counts > 1, date.distance(to: .now) > 3600 * 24 * 5 {
            return true
        } else {
            return false
        }
    }

    private static func fetchDefault(context: ModelContext, deviceName: String?) -> ThemeData? {
        let defaultName = AppInfo.defaultName

        let predicate = #Predicate<ThemeData> { data in
            if let deviceName {
                data.name == defaultName && data.deviceName == deviceName
            } else {
                data.name == defaultName
            }
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        var resultTheme: ThemeData?
        do {
            let themes = try context.fetch(descriptor)
            for theme in themes {
                if !theme.isNil && resultTheme == nil {
                    resultTheme = theme
                } else {
                    context.delete(theme)
                }
            }
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
        return resultTheme
    }

    @MainActor static func loadDefault() -> String {
        let modelContext = DataSchema.container.mainContext
        return fetchDefault(context: modelContext, deviceName: AppInfo.deviceName)?.code ?? Self.staticLayoutCode
    }
    static func loadLocalDefault() -> String {
        let modelContext = DataModel.shared.modelExecutor.modelContext
        return fetchDefault(context: modelContext, deviceName: LocalData.deviceName)?.code ?? Self.staticLayoutCode
    }

    @MainActor static func saveDefault(layout: String) {
        let modelContext = DataSchema.container.mainContext
        if let themeData = fetchDefault(context: modelContext, deviceName: AppInfo.deviceName) {
            themeData.code = layout
        } else {
            let themeData = ThemeData(deviceName: AppInfo.deviceName, name: AppInfo.defaultName, code: layout)
            modelContext.insert(themeData)
        }
        do {
            try modelContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}

typealias ConfigData = DataSchema.Config
extension ConfigData {
    static var version: Int {
        intVersion(DataSchema.versionIdentifier)
    }

    var isNil: Bool {
        return code == nil || name == nil || modifiedDate == nil
    }

    func update(code: String, name: String? = nil) {
        if self.code != code {
            self.code = code
            self.modifiedDate = Date.now
        }
        if let name {
            self.name = name
        }
        if (self.version ?? 0) < Self.version {
            self.version = Self.version
        }
    }

    private static func fetch(name: String, context: ModelContext) -> ConfigData? {
        let predicate = #Predicate<ConfigData> { data in
            data.name == name
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        var resultConfig: ConfigData?
        do {
            let configs = try context.fetch(descriptor)
            for config in configs {
                if !config.isNil && resultConfig == nil {
                    resultConfig = config
                } else {
                    context.delete(config)
                }
            }
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
        return resultConfig
    }

    static func load(name: String, context: ModelContext) -> (name: String, code: String)? {
        if let configData = fetch(name: name, context: context), let name = configData.name, let code = configData.code {
            return (name: name, code: code)
        } else {
            return nil
        }
    }

    @MainActor static func loadDefault() -> (name: String, code: String)? {
        let modelContext = DataSchema.container.mainContext
        return load(name: LocalData.configName ?? AppInfo.defaultName, context: modelContext)
    }
    static func loadLocalDefault() -> (name: String, code: String)? {
        let modelContext = DataModel.shared.modelExecutor.modelContext
        return load(name: LocalData.configName ?? AppInfo.defaultName, context: modelContext)
    }

    @MainActor static func save(name: String, config: String) {
        let modelContext = DataSchema.container.mainContext
        if let configData = fetch(name: name, context: modelContext) {
            configData.code = config
        } else {
            let configData = ConfigData(name: name, code: config)
            modelContext.insert(configData)
        }
        do {
            try modelContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}

enum DataSchemaV5: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(3, 0, 0)
    }
    static var models: [any PersistentModel.Type] {
        [Layout.self, Config.self]
    }

    @Model final class Config {
        @Attribute(.allowsCloudEncryption) var code: String?
        var modifiedDate: Date?
        @Attribute(.allowsCloudEncryption) var name: String?
        var version: Int?

        init(name: String, code: String) {
            self.name = name
            self.code = code
            self.modifiedDate = Date.now
            self.version = intVersion(DataSchemaV4.versionIdentifier)
        }
    }

    @Model final class Layout {
        var code: String?
        var deviceName: String?
        var modifiedDate: Date?
        var name: String?
        var version: Int?

        init(deviceName: String, name: String, code: String) {
            self.name = name
            self.deviceName = deviceName
            self.code = code
            self.modifiedDate = Date.now
            self.version = intVersion(DataSchemaV4.versionIdentifier)
        }
    }
}

enum DataSchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(2, 0, 0)
    }
    static var models: [any PersistentModel.Type] {
        [Layout.self, Config.self]
    }

    @Model final class Config {
        @Attribute(.allowsCloudEncryption) var code: String?
        var modifiedDate: Date?
        @Attribute(.allowsCloudEncryption) var name: String?
        var version: Int?

        init(name: String, code: String) {
            self.name = name
            self.code = code
            self.modifiedDate = Date.now
            self.version = intVersion(DataSchemaV4.versionIdentifier)
        }
    }

    @Model final class Layout {
        var code: String?
        var deviceName: String?
        var modifiedDate: Date?
        @Attribute(hashModifier: "v3") var name: String?
        var version: Int?

        init(deviceName: String, name: String, code: String) {
            self.name = name
            self.deviceName = deviceName
            self.code = code
            self.modifiedDate = Date.now
            self.version = intVersion(DataSchemaV4.versionIdentifier)
        }
    }
}

enum DataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DataSchemaV5.self, DataSchemaV4.self]
    }

    static var stages: [MigrationStage] { [migrateV4toV5] }
    static var migrateV4toV5: MigrationStage {
        .lightweight(fromVersion: DataSchemaV4.self, toVersion: DataSchemaV5.self)
    }
}

@ModelActor
actor LocalDataModel {
    static let shared = LocalDataModel(modelContainer: LocalSchema.container)
}

typealias LocalSchema = LocalSchemaV3
extension LocalSchema {
    static let container = {
        let localSchema = Schema(versionedSchema: LocalSchema.self)
        let modelConfig = ModelConfiguration("ChinendarLocal", schema: localSchema, groupContainer: .automatic, cloudKitDatabase: .none)
        return createContainer(schema: localSchema, migrationPlan: LocalDataMigrationPlan.self, configurations: [modelConfig])
    }()
}

typealias LocalData = LocalSchema.LocalData
extension LocalData: Identifiable, Hashable {
    static var version: Int {
        intVersion(LocalSchema.versionIdentifier)
    }
    static var deviceName: String? {
        getRecord()?.deviceName
    }
    static var configName: String? {
        getRecord()?.configName
    }

    private static func getRecord() -> LocalData? {
        var descriptor = FetchDescriptor(sortBy: [SortDescriptor(\LocalData.modifiedDate, order: .reverse)])
        descriptor.fetchLimit = 1
        do {
            let records = try LocalDataModel.shared.modelExecutor.modelContext.fetch(descriptor)
            if let record = records.first {
                return record
            }
        } catch {
            print("Error fetching local data: \(error.localizedDescription)")
        }
        return nil
    }

    static func update(deviceName: String? = nil, configName: String? = nil) {
        let localRecord = getRecord()
        if let deviceName {
            localRecord?.deviceName = deviceName
        }
        if let configName {
            localRecord?.configName = configName
        }
        do {
            try LocalDataModel.shared.modelExecutor.modelContext.save()
        } catch {
            print("Error saving local data: \(error.localizedDescription)")
        }
    }
}

enum LocalSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(3, 0, 0)
    }
    static var models: [any PersistentModel.Type] {
        [LocalData.self]
    }

    @Model final class LocalData {
        #Unique<LocalData>([\.unique])

        var unique = 1
        var deviceName: String?
        var configName: String?
        var modifiedDate: Date?
        var version: Int?

        init(deviceName: String?, configName: String?) {
            self.deviceName = deviceName
            self.configName = configName
            self.modifiedDate = Date.now
            self.version = intVersion(LocalSchema.versionIdentifier)
        }
    }
}

enum LocalSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(2, 1, 0)
    }
    static var models: [any PersistentModel.Type] {
        [LocalData.self]
    }

    @Model final class LocalData {
        var deviceName: String?
        var configName: String?
        var modifiedDate: Date?
        var version: Int?

        init(deviceName: String?, configName: String?) {
            self.deviceName = deviceName
            self.configName = configName
            self.modifiedDate = Date.now
            self.version = intVersion(LocalSchemaV2.versionIdentifier)
        }
    }
}

enum LocalDataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LocalSchemaV3.self, LocalSchemaV2.self]
    }

    static var stages: [MigrationStage] { [migrateV2toV3] }
    static var migrateV2toV3: MigrationStage {
        .lightweight(fromVersion: LocalSchemaV2.self, toVersion: LocalSchemaV3.self)
    }
}
