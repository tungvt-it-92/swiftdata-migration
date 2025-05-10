//
//  SchemaV1.swift
//  SwiftDataMigration
//
import SwiftData
import Foundation

enum SchemaV2: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            // V1
            SchemaV1.TodoModel.self,
            // V2
            SchemaV2.SettingModel.self
        ]
    }
    
    static let versionIdentifier = Schema.Version(2, 0, 0)
}
