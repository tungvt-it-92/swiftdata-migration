//
//  MigrationPlan.swift
//  SwiftDataMigration
//
import SwiftData

extension MigrationStage: @unchecked @retroactive Sendable {}
extension Schema.Version: @unchecked @retroactive Sendable {}

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
    
    // MARK: Migration Stages
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { _ in
            Log.debug("willMigrate")
        },
        didMigrate: { context in
            Log.debug("didMigrate")
            let settings = try context.fetch(FetchDescriptor<SchemaV2.SettingModel>())
            
            if let setting  = settings.first {
                setting.isEnableSyncCalendar = true
                try context.save()
                Log.debug("Set isEnableSyncCalendar = true")
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
    
    // MARK: Migration Stages
    static let migrateV2toV1 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV1.self,
        willMigrate: { _ in
            Log.debug("willMigrate")
        },
        didMigrate: { context in
            Log.debug("didMigrate")
            let settings = try context.fetch(FetchDescriptor<SchemaV1.SettingModel>())
            
            if let setting  = settings.first {
                setting.isNotificationEnabled = false
                try context.save()
                Log.debug("Set isNotificationEnabled = false")
            }
        }
    )
}
