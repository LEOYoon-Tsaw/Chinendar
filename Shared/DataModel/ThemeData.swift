//
//  Layout.swift
//  Chinese Time
//
//  Created by Leo Liu on 7/7/23.
//
//

import Foundation
import SwiftData
#if os(macOS)
import SystemConfiguration
#elseif os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

typealias ThemeData = DataSchemaV2.Layout

extension ThemeData: Identifiable, Hashable {
    static var version: Int {
        intVersion(DataSchemaV2.versionIdentifier)
    }
    
#if os(macOS)
        static let groupId = Bundle.main.object(forInfoDictionaryKey: "GroupID") as! String
#elseif os(iOS)
        static let groupId = "group.ChineseTime"
#elseif os(watchOS)
        static let groupId = "group.ChineseTime.Watch"
#endif
        
#if os(macOS)
        static let deviceName = SCDynamicStoreCopyComputerName(nil, nil).map { String($0) } ?? "Mac"
#elseif os(iOS)
        @MainActor static let deviceName = UIDevice.current.name
#elseif os(watchOS)
        static let deviceName = WKInterfaceDevice.current().name
#endif
    
    static let defaultName = NSLocalizedString("Default", comment: "Default save file name")
    
    static let container = {
        let fullSchema = Schema(versionedSchema: DataSchemaV2.self)
        let baseUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ThemeData.groupId)!
#if os(macOS)
        let url = baseUrl.appendingPathComponent("ChineseTime")
#else
        let url = baseUrl.appendingPathComponent("ChineseTime.sqlite")
#endif
        let modelConfig = ModelConfiguration("ChineseTime", schema: fullSchema, url: url, cloudKitDatabase: .private("iCloud.YLiu.ChineseTime"))
        return createContainer(schema: fullSchema, migrationPlan: DataMigrationPlan.self, configurations: [modelConfig])
    }()
    
    static let context = ModelContext(ThemeData.container)
    
    static func latestVersion() -> Int {
        let deviceName = ThemeData.deviceName
        let predicate = #Predicate<ThemeData> { data in
            data.deviceName == deviceName
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        var version = 0
        do {
            let records = try ThemeData.context.fetch(descriptor)
            for record in records {
                if !record.isNil {
                    version = record.version ?? version
                    break
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        return version
    }
    
    var isNil: Bool {
        return code == nil || name == nil || deviceName == nil || modifiedDate == nil
    }
    
    func update(code: String) {
        if self.code != code {
            self.code = code
            self.modifiedDate = Date.now
            self.version = ThemeData.version
        }
    }
}

private func intVersion(_ version: Schema.Version) -> Int {
    version.major * 100_0000 + version.minor * 1_0000 + version.patch * 100 + 0
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

enum DataSchemaV2: VersionedSchema {
    static let versionIdentifier: Schema.Version = .init(1, 1, 0)
    static var models: [any PersistentModel.Type] {
        [Layout.self]
    }
    
    @Model final class Layout {
        var code: String?
        var deviceName: String?
        var modifiedDate: Date?
        var name: String?
        var version: Int?
        
        init(name: String, code: String) {
            self.name = name
            self.deviceName = Layout.deviceName
            self.code = code
            self.modifiedDate = Date.now
            self.version = intVersion(DataSchemaV2.versionIdentifier)
        }
    }
}

enum DataSchemaV1: VersionedSchema {
    static let versionIdentifier: Schema.Version = .init(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Layout.self]
    }
    
    @Model final class Layout {
        var code: String?
        var deviceName: String?
        var modifiedDate: Date?
        var name: String?
        
        init(name: String, deviceName: String, code: String) {
            self.name = name
            self.deviceName = deviceName
            self.code = code
            self.modifiedDate = Date.now
        }
    }
}

enum DataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DataSchemaV1.self, DataSchemaV2.self]
    }
    
    static var stages: [MigrationStage] { [migrateV1toV2] }
    
    static let migrateV1toV2 = MigrationStage.lightweight(fromVersion: DataSchemaV1.self, toVersion: DataSchemaV2.self)
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

typealias LocalData = LocalSchemaV1.LocalData

extension LocalData: Identifiable, Hashable {
    static var version: Int {
        intVersion(LocalSchemaV1.versionIdentifier)
    }
    
    static let container = {
        let localSchema = Schema(versionedSchema: LocalSchemaV1.self)
        let modelConfig = ModelConfiguration("ChineseTimeLocal", schema: localSchema, groupContainer: .identifier(ThemeData.groupId), cloudKitDatabase: .none)
        return createContainer(schema: localSchema, migrationPlan: nil, configurations: [modelConfig])
    }()
    
    static let context = ModelContext(LocalData.container)
    
    func update(deviceName: String) {
        if self.deviceName != deviceName {
            self.deviceName = deviceName
            self.modifiedDate = Date.now
            self.version = LocalData.version
        }
    }
    
    static func read() throws -> LocalData? {
        let context = LocalData.context
        let descriptor = FetchDescriptor(sortBy: [SortDescriptor(\LocalData.modifiedDate, order: .reverse)])
        let records = try context.fetch(descriptor)
        for record in records {
            return record
        }
        return nil
    }
    
    static func write(deviceName: String) throws {
        let context = LocalData.context
        let descriptor = FetchDescriptor(sortBy: [SortDescriptor(\LocalData.modifiedDate, order: .reverse)])
        let records = try context.fetch(descriptor)
        var found = false
        for record in records {
            if !found {
                record.update(deviceName: deviceName)
                found = true
            } else {
                context.delete(record)
            }
        }
        if !found {
            let record = LocalData(deviceName: deviceName)
            context.insert(record)
        }
        try context.save()
    }
}
