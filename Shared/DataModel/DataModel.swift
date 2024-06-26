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
    static let deviceName = UIDevice.current.name
#elseif os(watchOS)
    static let deviceName = WKInterfaceDevice.current().name
#endif
    static let defaultName = "__current_theme__"
}

typealias DataSchema = DataSchemaV4
extension DataSchema {
    static let container = {
        let fullSchema = Schema(versionedSchema: DataSchema.self)
        let modelConfig = ModelConfiguration("Chinendar", schema: fullSchema, groupContainer: .automatic, cloudKitDatabase: .automatic)
        return createContainer(schema: fullSchema, migrationPlan: DataMigrationPlan.self, configurations: [modelConfig])
    }()

    static let context = ModelContext(container)
}

typealias ThemeData = DataSchemaV3.Layout
extension ThemeData {
    static var version: Int {
        intVersion(DataSchema.versionIdentifier)
    }

    static func notLatest() -> Bool {
        let deviceName = AppInfo.deviceName
        let predicate = #Predicate<ThemeData> { data in
            data.deviceName == deviceName && data.version != nil
        }
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        descriptor.fetchLimit = 1
        if let latestEntry = try? DataSchema.context.fetch(descriptor).first {
            if (latestEntry.version ?? 0) < Self.version {
                latestEntry.version = Self.version
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    static func experienced() -> Bool {
        let predicate = #Predicate<ThemeData> { data in
            data.modifiedDate != nil
        }
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate)])
        let counts = try? DataSchema.context.fetchCount(descriptor)
        descriptor.fetchLimit = 1
        let date = try? DataSchema.context.fetch(descriptor).first?.modifiedDate

        if let date = date, let counts = counts, counts > 1, date.distance(to: .now) > 3600 * 24 * 5 {
            return true
        } else {
            return false
        }
    }

    var isNil: Bool {
        return code == nil || name == nil || deviceName == nil || modifiedDate == nil
    }

    func update(code: String) {
        if self.code != code {
            self.code = code
            self.modifiedDate = Date.now
        }
        if (self.version ?? 0) < Self.version {
            self.version = Self.version
        }
    }
}

typealias ConfigData = DataSchemaV4.Config
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
        if (self.version ?? 0) < Self.version {
            self.version = Self.version
        }
    }
}

enum DataSchemaV4: VersionedSchema {
    static let versionIdentifier: Schema.Version = .init(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [DataSchemaV3.Layout.self, Config.self]
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
}

enum DataSchemaV3: VersionedSchema {
    static let versionIdentifier: Schema.Version = .init(1, 2, 1)
    static var models: [any PersistentModel.Type] {
        [Layout.self]
    }

    @Model final class Layout {
        var code: String?
        var deviceName: String?
        var modifiedDate: Date?
        @Attribute(hashModifier: "v3") var name: String?
        var version: Int?

        init(name: String, code: String) {
            self.name = name
            self.deviceName = AppInfo.deviceName
            self.code = code
            self.modifiedDate = Date.now
            self.version = intVersion(DataSchemaV4.versionIdentifier)
        }
    }
}

enum DataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DataSchemaV3.self, DataSchemaV4.self]
    }

    static var stages: [MigrationStage] { [migrateV3toV4] }
    static let migrateV3toV4 = MigrationStage.lightweight(fromVersion: DataSchemaV3.self, toVersion: DataSchemaV4.self)
}

typealias LocalSchema = LocalSchemaV2
extension LocalSchema {
    static let container = {
        let localSchema = Schema(versionedSchema: LocalSchema.self)
        let modelConfig = ModelConfiguration("ChinendarLocal", schema: localSchema, groupContainer: .automatic, cloudKitDatabase: .none)
        return createContainer(schema: localSchema, migrationPlan: LocalDataMigrationPlan.self, configurations: [modelConfig])
    }()

    static let context = ModelContext(container)
}

typealias LocalData = LocalSchema.LocalData
extension LocalData: Identifiable, Hashable {
    static var version: Int {
        intVersion(LocalSchema.versionIdentifier)
    }

    func update(deviceName: String) {
        if self.deviceName != deviceName {
            self.deviceName = deviceName
            self.modifiedDate = Date.now
            self.version = Self.version
        }
    }

    func update(configName: String) {
        if self.configName != configName {
            self.configName = configName
            self.modifiedDate = Date.now
            self.version = Self.version
        }
    }

    static func read(context: ModelContext) -> LocalData? {
        let descriptor = FetchDescriptor(sortBy: [SortDescriptor(\LocalData.modifiedDate, order: .reverse)])
        do {
            let records = try context.fetch(descriptor)
            for record in records {
                return record
            }
        } catch {
            return nil
        }
        return nil
    }

    static func write(context: ModelContext, deviceName: String? = nil, configName: String? = nil) throws {
        let descriptor = FetchDescriptor(sortBy: [SortDescriptor(\LocalData.modifiedDate, order: .reverse)])
        let records = try context.fetch(descriptor)
        var found = false
        for record in records {
            if !found {
                if let deviceName = deviceName {
                    record.update(deviceName: deviceName)
                }
                if let configName = configName {
                    record.update(configName: configName)
                }
                found = true
            } else {
                context.delete(record)
            }
        }
        if !found {
            let record = LocalData(deviceName: deviceName, configName: configName)
            context.insert(record)
        }
        try context.save()
    }
}

enum LocalSchemaV2: VersionedSchema {
    static let versionIdentifier: Schema.Version = .init(2, 1, 0)
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

enum LocalSchemaV1: VersionedSchema {
    static let versionIdentifier: Schema.Version = .init(1, 1, 0)
    static var models: [any PersistentModel.Type] {
        [LocalData.self]
    }

    @Model final class LocalData {
        var deviceName: String?
        var modifiedDate: Date?
        var version: Int?

        init(deviceName: String) {
            self.deviceName = deviceName
            self.modifiedDate = Date.now
            self.version = intVersion(LocalSchemaV1.versionIdentifier)
        }
    }
}

enum LocalDataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LocalSchemaV1.self, LocalSchemaV2.self]
    }

    static var stages: [MigrationStage] { [migrateV1toV2] }
    static let migrateV1toV2 = MigrationStage.lightweight(fromVersion: LocalSchemaV1.self, toVersion: LocalSchemaV2.self)
}
