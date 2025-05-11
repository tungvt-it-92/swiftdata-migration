//
//  MigrationPlan.swift
//  SwiftDataMigration
//
import SwiftData
import Foundation

extension MigrationStage: @unchecked @retroactive Sendable {}
extension Schema.Version: @unchecked @retroactive Sendable {}

struct SettingModelBackup: Sendable {
    let id: UUID
    let isNotificationEnabled: Bool
    
    init(id: UUID, isNotificationEnabled: Bool) {
        self.id = id
        self.isNotificationEnabled = isNotificationEnabled
    }
}

enum UpgradeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            migrateV1toV2
        ]
    }
    
    nonisolated(unsafe) static var settingBackup: SettingModelBackup? = nil

    // MARK: Migration Stages
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            Log.debug("willMigrate")
            if let existingSetting = (try? context.fetch(FetchDescriptor<SchemaV1.SettingModel>()))?.first {
                settingBackup = SettingModelBackup(id: existingSetting.id, isNotificationEnabled: existingSetting.isNotificationEnabled)
            }
        },
        didMigrate: { context in
            Log.debug("didMigrate")
            let settings = try context.fetch(FetchDescriptor<SchemaV2.SettingModel>())
            
            if let setting  = settings.first, let backup = settingBackup {
                setting.isPushNotificationEnabled = backup.isNotificationEnabled
                setting.id = backup.id
                
                try context.save()
            }
        }
    )
}

enum DowngradeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self
        ]
    }
    
    static var stages: [MigrationStage] {
        [
            migrateV2toV1
        ]
    }
    nonisolated(unsafe) static var settingBackup: SettingModelBackup? = nil
    
    // MARK: Migration Stages
    static let migrateV2toV1 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV1.self,
        willMigrate: { context in
            if let existingSetting = (try? context.fetch(FetchDescriptor<SchemaV2.SettingModel>()))?.first {
                settingBackup = SettingModelBackup(id: existingSetting.id, isNotificationEnabled: existingSetting.isPushNotificationEnabled)
            }
            Log.debug("willMigrate")
        },
        didMigrate: { context in
            Log.debug("didMigrate")
            let settings = try context.fetch(FetchDescriptor<SchemaV1.SettingModel>())
            
            if let setting  = settings.first, let backup = settingBackup {
                setting.isNotificationEnabled = backup.isNotificationEnabled
                setting.id = backup.id
                
                try context.save()
            }
        }
    )
}
