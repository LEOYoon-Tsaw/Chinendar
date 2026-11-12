//
//  DataModel.swift
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
    version.major * 100_0000 + version.minor * 1_0000 + version.patch * 100 + 2
}

private func createContainer(schema: Schema, migrationPlan: any SchemaMigrationPlan.Type, configurations: [ModelConfiguration]) -> ModelContainer {
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
    static let defaultName = String(localized: "__factory_default_name__")
}

@ModelActor
actor DataModel {
    static let shared = DataModel(modelContainer: DataSchema.container)
}

extension DataModel {
    func getReminders() async throws -> [ReminderList] {
        return try RemindersData.load(context: self.modelContext)
    }

    func getAllConfigIntent(ids: [String] = []) async throws -> [ConfigIntent] {
        let fetchDesp = if ids.isEmpty {
            FetchDescriptor(predicate: ConfigData.predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        } else {
            FetchDescriptor(predicate: #Predicate<ConfigData> { entry in
                if entry.id != nil && entry.data != nil {
                    ids.contains(entry.id!)
                } else {
                    false
                }
            }, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        }
        let sharedConfigs = try self.modelContext.fetch(fetchDesp)
        return sharedConfigs.compactMap { config in
            if let id = config.id, let name = config.name, let instance = config.instance {
                ConfigIntent(id: id, name: name, config: instance)
            } else {
                nil
            }
        }
    }

    func getAllThemeIntent(ids: [String] = []) async throws -> [ThemeIntent] {
        let fetchDesp = if ids.isEmpty {
            FetchDescriptor(predicate: ThemeData.predicate, sortBy: [SortDescriptor(\.deviceName), SortDescriptor(\.modifiedDate, order: .reverse)])
        } else {
            FetchDescriptor(predicate: #Predicate<ThemeData> { entry in
                if entry.id != nil && entry.data != nil {
                    ids.contains(entry.id!)
                } else {
                    false
                }
            }, sortBy: [SortDescriptor(\.deviceName), SortDescriptor(\.modifiedDate, order: .reverse)])
        }
        let sharedThemes = try self.modelContext.fetch(fetchDesp)
        return sharedThemes.compactMap { theme in
            if let id = theme.id, let deviceName = theme.deviceName, let name = theme.name, let instance = theme.instance {
                let localizedName = String(localized: "DEVICE\(deviceName)NAME\(name)")
                return ThemeIntent(id: id, name: localizedName, theme: instance)
            } else {
                return nil
            }
        }
    }
}

typealias DataSchema = DataSchemaV8
extension DataSchema {
    static let container = {
        let fullSchema = Schema(versionedSchema: DataSchema.self)
#if DEBUG
        let modelConfig = ModelConfiguration("MainData-debug", schema: fullSchema, groupContainer: .automatic, cloudKitDatabase: .none)
#else
        let modelConfig = ModelConfiguration("MainData", schema: fullSchema, groupContainer: .automatic, cloudKitDatabase: .automatic)
#endif
        return createContainer(schema: fullSchema, migrationPlan: DataMigrationPlan.self, configurations: [modelConfig])
    }()
}

typealias ThemeData = DataSchema.Theme
extension ThemeData: CodableNullableDataModel {
    typealias Model = WatchLayout

    static let version = intVersion(DataSchema.versionIdentifier)
    static let predicate = #Predicate<ThemeData> { entry in
        entry.data != nil
    }

    var isNil: Bool {
        return data == nil || name == nil || deviceName == nil || modifiedDate == nil
    }

    var nonNilName: String { name ?? String(localized: "UNKWOWN_NAME") }
    var nonNilModifiedDate: Date { modifiedDate ?? Date.distantPast }
}

typealias ConfigData = DataSchema.CalendarConfig
extension ConfigData: CodableNullableDataModel {
    typealias Model = CalendarConfigure

    static let version = intVersion(DataSchema.versionIdentifier)
    static let predicate = #Predicate<ConfigData> { entry in
        entry.data != nil
    }

    var isNil: Bool {
        return data == nil || name == nil || modifiedDate == nil
    }

    var nonNilName: String { name ?? String(localized: "UNKWOWN_NAME") }
}

typealias RemindersData = DataSchema.RemindersList
extension RemindersData: Bindable, CodableNullableDataModel {
    typealias Model = ReminderList

    static let version = intVersion(DataSchema.versionIdentifier)
    static let predicate = #Predicate<RemindersData> { entry in
        entry.data != nil
    }

    static func load(context: ModelContext) throws -> [ReminderList] {
        let descriptor = FetchDescriptor(predicate: Self.predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
        if try context.fetchCount(descriptor) > 0 {
            let reminders = try context.fetch(descriptor).compactMap { $0.instance }
            return reminders
        } else {
            return []
        }
    }

    var nonNilList: ReminderList {
        get {
            instance ?? .init(name: String(localized: "UNNAMED"), enabled: false, reminders: [])
        } set {
            instance = newValue
        }
    }

    var isNil: Bool {
        return data == nil || modifiedDate == nil
    }
}

enum DataSchemaV8: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(5, 0, 0)
    }
    static var models: [any PersistentModel.Type] {
        [Theme.self, CalendarConfig.self, RemindersList.self]
    }

    @Model final class CalendarConfig {
        @Attribute(.allowsCloudEncryption) var data: Data?
        @Attribute(.allowsCloudEncryption) var name: String?
        var modifiedDate: Date?
        var version: Int?
        var id: String?

        init(_ config: CalendarConfigure, name: String) throws {
            let encoder = JSONEncoder()
            self.id = UUID().uuidString
            self.data = try encoder.encode(config)
            self.name = name
            self.modifiedDate = .now
            self.version = intVersion(DataSchemaV8.versionIdentifier)
        }
    }

    @Model final class Theme {
        @Attribute(.allowsCloudEncryption) var data: Data?
        @Attribute(.allowsCloudEncryption) var name: String?
        @Attribute(.allowsCloudEncryption) var deviceName: String?
        var modifiedDate: Date?
        var version: Int?
        var id: String?

        init(_ layout: WatchLayout, name: String, deviceName: String) throws {
            let encoder = JSONEncoder()
            self.id = UUID().uuidString
            self.data = try encoder.encode(layout)
            self.name = name
            self.deviceName = deviceName
            self.modifiedDate = .now
            self.version = intVersion(DataSchemaV8.versionIdentifier)
        }
    }

    @Model final class RemindersList {
        @Attribute(.allowsCloudEncryption) var data: Data?
        var modifiedDate: Date?
        var version: Int?
        var id: String?

        init(_ reminderList: ReminderList) throws {
            let encoder = JSONEncoder()
            self.id = UUID().uuidString
            self.data = try encoder.encode(reminderList)
            self.version = intVersion(DataSchemaV8.versionIdentifier)
            self.modifiedDate = .now
        }
    }
}

enum DataSchemaV7: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(4, 0, 0)
    }
    static var models: [any PersistentModel.Type] {
        [Theme.self, CalendarConfig.self, RemindersList.self]
    }

    @Model final class CalendarConfig {
        @Attribute(.allowsCloudEncryption) var data: Data?
        @Attribute(.allowsCloudEncryption) var name: String?
        var modifiedDate: Date?
        var version: Int?

        init(_ config: CalendarConfigure, name: String) throws {
            let encoder = JSONEncoder()
            self.data = try encoder.encode(config)
            self.name = name
            self.modifiedDate = .now
            self.version = intVersion(DataSchemaV7.versionIdentifier)
        }
    }

    @Model final class Theme {
        @Attribute(.allowsCloudEncryption) var data: Data?
        @Attribute(.allowsCloudEncryption) var name: String?
        @Attribute(.allowsCloudEncryption) var deviceName: String?
        var modifiedDate: Date?
        var version: Int?

        init(_ layout: WatchLayout, name: String, deviceName: String) throws {
            let encoder = JSONEncoder()
            self.data = try encoder.encode(layout)
            self.name = name
            self.deviceName = deviceName
            self.modifiedDate = .now
            self.version = intVersion(DataSchemaV7.versionIdentifier)
        }
    }

    @Model final class RemindersList {
        @Attribute(.allowsCloudEncryption) var data: Data?
        var modifiedDate: Date?
        var version: Int?

        init(_ reminderList: ReminderList) throws {
            let encoder = JSONEncoder()
            self.data = try encoder.encode(reminderList)
            self.version = intVersion(DataSchemaV7.versionIdentifier)
            self.modifiedDate = .now
        }
    }
}

enum DataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DataSchemaV7.self, DataSchemaV8.self]
    }

    static var stages: [MigrationStage] { [migrateV7toV8] }

    static let migrateV7toV8 = MigrationStage.custom(
        fromVersion: DataSchemaV7.self,
        toVersion: DataSchemaV8.self,
        willMigrate: nil,
        didMigrate: { context in
            for theme in try context.fetch(FetchDescriptor<DataSchemaV8.Theme>()) where theme.id == nil {
                theme.id = UUID().uuidString
            }
            for config in try context.fetch(FetchDescriptor<DataSchemaV8.CalendarConfig>()) where config.id == nil {
                config.id = UUID().uuidString
            }
            for reminders in try context.fetch(FetchDescriptor<DataSchemaV8.RemindersList>()) where reminders.id == nil {
                reminders.id = UUID().uuidString
            }
            try context.save()
        }
    )
}

@ModelActor
actor LocalDataModel {
    static let shared = LocalDataModel(modelContainer: LocalSchema.container)
}

extension LocalDataModel {
    func updateConfig(config: CalendarConfigure) async throws {
        let localConfig = LocalConfig.load(context: self.modelContext)
        localConfig.instance ?= config
        try self.modelContext.save()
    }

    func getLocalConfigIntent() async -> ConfigIntent {
        let localConfigModel = LocalConfig.load(context: self.modelContext)
        return ConfigIntent(id: localConfigModel.name, name: String(localized: "DEFAULT_NAME"), config: localConfigModel.instance)
    }

    func getLocalThemeIntent() async -> ThemeIntent {
        let localThemeModel = LocalTheme.load(context: self.modelContext)
        return ThemeIntent(id: localThemeModel.name, name: String(localized: "DEFAULT_NAME"), theme: localThemeModel.instance)
    }

    func getLocalConfig() async -> CalendarConfigure {
        let localConfigModel = LocalConfig.load(context: self.modelContext)
        return localConfigModel.instance
    }

    func getLocalTheme() async -> WatchLayout {
        let localThemeModel = LocalTheme.load(context: self.modelContext)
        return localThemeModel.instance
    }

    func getEventWidgetStatus(type: NextEventType) async -> NextEventStatus {
        var descriptor = FetchDescriptor(predicate: #Predicate<EventWidgetStatus> { entry in
            entry.type == type
        }, sortBy: [SortDescriptor(\.updateTime, order: .reverse)])
        descriptor.fetchLimit = 1
        if let statusData = try? self.modelContext.fetch(descriptor).first {
            return statusData.instance
        } else {
            return NextEventStatus(type: type, step: 0, updateTime: .now)
        }
    }

    func updateEventWidgetStatus(type: NextEventType, forward: Bool, updateTime: Date? = nil) async throws {
        var descriptor = FetchDescriptor(predicate: #Predicate<EventWidgetStatus> { entry in
            entry.type == type
        }, sortBy: [SortDescriptor(\.updateTime, order: .reverse)])
        descriptor.fetchLimit = 1
        let time = updateTime ?? .now
        if let statusData = try self.modelContext.fetch(descriptor).first {
            statusData.instance = statusData.instance.navigating(forward: forward, at: time)
        } else {
            let statusData = try EventWidgetStatus(type: type, step: forward ? 1 : -1, updateTime: time)
            self.modelContext.insert(statusData)
        }
        try modelContext.save()
    }

    func pruneEventWidgetStatuses(at time: Date = .now) throws {
        let descriptor = FetchDescriptor<EventWidgetStatus>(sortBy: [SortDescriptor(\.updateTime, order: .reverse)])
        let statuses = try modelContext.fetch(descriptor)
        var seenTypes = Set<NextEventType>()
        for status in statuses {
            let isLatest = seenTypes.insert(status.type).inserted
            if !isLatest || !status.instance.isActive(at: time) {
                modelContext.delete(status)
            }
        }
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}

typealias LocalSchema = LocalSchemaV5
extension LocalSchema {
    static let container = {
        let localSchema = Schema(versionedSchema: LocalSchema.self)
#if DEBUG
        let modelConfig = ModelConfiguration("LocalData-debug", schema: localSchema, groupContainer: .automatic, cloudKitDatabase: .none)
#else
        let modelConfig = ModelConfiguration("LocalData", schema: localSchema, groupContainer: .automatic, cloudKitDatabase: .none)
#endif
        return createContainer(schema: localSchema, migrationPlan: LocalDataMigrationPlan.self, configurations: [modelConfig])
    }()
}

protocol LocalDataModelType: PersistentModel {}

extension LocalDataModelType {
    static fileprivate func _load(context: ModelContext) throws -> Self? {
        var descriptor = FetchDescriptor<Self>()
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

typealias LocalStats = LocalSchema.LocalStats
extension LocalStats: Identifiable, Hashable, LocalDataModelType {
    static let version = intVersion(LocalSchema.versionIdentifier) + 3
    @MainActor static func notLatest() -> Bool {
        let modelContext = LocalSchema.container.mainContext
        if let localStats = try? _load(context: modelContext) {
            let condition = localStats.version < Self.version
            if condition {
                localStats.version = Self.version
            }
            return condition
        } else {
            modelContext.insert(LocalStats(version: Self.version))
            return true
        }
    }

    @MainActor static func experienced() -> Bool {
        let modelContext = LocalSchema.container.mainContext
        if let localStats = try? _load(context: modelContext) {
            localStats.launchCount += 1
            let condition = localStats.creationTime.distance(to: .now) > 3600 * 24 * 5 && localStats.launchCount >= 5
            return condition
        } else {
            modelContext.insert(LocalStats(version: Self.version))
            return false
        }
    }
}

typealias LocalTheme = LocalSchema.LocalTheme
extension LocalTheme: Identifiable, Hashable, LocalDataModelType, CodableDataModel {
    typealias Model = WatchLayout
    static let version = intVersion(LocalSchema.versionIdentifier)

    static func load(context: ModelContext) -> Self {
        if let themeData = try? _load(context: context) {
            return themeData
        } else {
            let themeData = try! Self(.defaultLayout)
            context.insert(themeData)
            return themeData
        }
    }
}

typealias LocalConfig = LocalSchema.LocalCalendarConfig
extension LocalConfig: Identifiable, Hashable, LocalDataModelType, CodableDataModel {
    typealias Model = CalendarConfigure
    static let version = intVersion(LocalSchema.versionIdentifier)

    static func load(context: ModelContext) -> Self {
        if let configData = try? _load(context: context) {
            return configData
        } else {
            let configData = try! Self(.init())
            context.insert(configData)
            return configData
        }
    }
}

typealias EventWidgetStatus = LocalSchema.EventWidgetStatus
extension EventWidgetStatus: LocalDataModelType {
    var instance: NextEventStatus {
        get {
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(NextEventStatus.self, from: data)
            } catch {
                print("Cannot decode \(NextEventStatus.self) from local storage: \(error)")
                return NextEventStatus(type: type, step: 0, updateTime: updateTime)
            }
        } set {
            do {
                let encoder = JSONEncoder()
                data = try encoder.encode(newValue)
                type = newValue.type
                updateTime = newValue.updateTime
            } catch {
                print("Cannot encode \(NextEventStatus.self) new value: \(error)")
            }
        }
    }
}

enum LocalSchemaV5: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(5, 0, 0)
    }
    static var models: [any PersistentModel.Type] {
        [LocalStats.self, LocalTheme.self, LocalCalendarConfig.self, EventWidgetStatus.self]
    }
    typealias LocalStats = LocalSchemaV4.LocalStats
    typealias LocalTheme = LocalSchemaV4.LocalTheme
    typealias LocalCalendarConfig = LocalSchemaV4.LocalCalendarConfig

    @Model final class EventWidgetStatus {
        var data: Data
        var type: NextEventType
        var updateTime: Date

        init(type: NextEventType, step: Int = 0, updateTime: Date = .now) throws {
            let status = NextEventStatus(type: type, step: step, updateTime: updateTime)
            let encoder = JSONEncoder()
            self.data = try encoder.encode(status)
            self.type = type
            self.updateTime = updateTime
        }
    }
}

enum LocalSchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(4, 0, 0)
    }
    static var models: [any PersistentModel.Type] {
        [LocalStats.self, LocalTheme.self, LocalCalendarConfig.self]
    }

    @Model final class LocalStats {
        #Unique<LocalStats>([\.name])

        var name = "__local_stats__"
        var creationTime = Date.now
        var launchCount = 0
        var version: Int

        init(version: Int) {
            self.version = version
        }
    }

    @Model final class LocalCalendarConfig {
        #Unique<LocalCalendarConfig>([\.name])
        static let defaultInstance = CalendarConfigure()

        var name = "__local_calendar_config__"
        var data: Data
        var modifiedDate: Date
        var version: Int
        @Transient var decodedCache: (data: Data, value: CalendarConfigure)?

        init(_ config: CalendarConfigure) throws {
            let encoder = JSONEncoder()
            self.data = try encoder.encode(config)
            self.modifiedDate = .now
            self.version = intVersion(LocalSchemaV4.versionIdentifier)
        }
    }

    @Model final class LocalTheme {
        #Unique<LocalTheme>([\.name])
        static let defaultInstance = WatchLayout()

        var name = "__local_watch_layout__"
        var data: Data
        var modifiedDate: Date
        var version: Int
        @Transient var decodedCache: (data: Data, value: WatchLayout)?

        init(_ layout: WatchLayout) throws {
            let encoder = JSONEncoder()
            self.data = try encoder.encode(layout)
            self.modifiedDate = .now
            self.version = intVersion(LocalSchemaV4.versionIdentifier)
        }
    }
}

enum LocalDataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LocalSchemaV5.self, LocalSchemaV4.self]
    }

    static var stages: [MigrationStage] { [.lightweight(fromVersion: LocalSchemaV4.self, toVersion: LocalSchemaV5.self)] }
}

protocol CodableNullableDataModel: AnyObject {
    associatedtype Model: Codable
    static var version: Int { get }
    var data: Data? { get set }
    var modifiedDate: Date? { get set }
    var version: Int? { get set }
    var instance: Model? { get set }
}

extension CodableNullableDataModel {
    var instance: Model? {
        get {
            let decoder = JSONDecoder()
            do {
                if let data {
                    return try decoder.decode(Model.self, from: data)
                } else {
                    return nil
                }
            } catch {
                print("Cannot decode \(Self.self) from local storage: \(error)")
                return nil
            }
        } set {
            do {
                let encoder = JSONEncoder()
                data = try encoder.encode(newValue)
                modifiedDate = .now
                if (self.version ?? 0) < Self.version {
                    self.version = Self.version
                }
            } catch {
                print("Cannot encode \(Self.self) new value: \(error)")
            }
        }
    }
}

protocol CodableDataModel: AnyObject {
    associatedtype Model: Codable
    static var version: Int { get }
    static var defaultInstance: Model { get }
    var data: Data { get set }
    var modifiedDate: Date { get set }
    var version: Int { get set }
    var instance: Model { get set }
    var decodedCache: (data: Data, value: Model)? { get set }
}

extension CodableDataModel {
    var instance: Model {
        get {
            // Read the persisted property even on cache hits to preserve observation.
            let data = self.data
            if let decodedCache, decodedCache.data == data {
                return decodedCache.value
            }
            let decoder = JSONDecoder()
            do {
                let value = try decoder.decode(Model.self, from: data)
                decodedCache = (data: data, value: value)
                return value
            } catch {
                print("Cannot decode \(Self.self) from local storage: \(error)")
                return Self.defaultInstance
            }
        } set {
            do {
                let encoder = JSONEncoder()
                data = try encoder.encode(newValue)
                modifiedDate = .now
                if self.version < Self.version {
                    self.version = Self.version
                }
            } catch {
                print("Cannot encode \(Self.self) new value: \(error)")
            }
        }
    }
}
