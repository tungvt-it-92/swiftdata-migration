//
//  SchemaV2.swift
//  SwiftDataMigration
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [
            SchemaV1.TodoModel.self,
            SchemaV1.SettingModel.self,
        ]
    }
    
    static let versionIdentifier = Schema.Version(1, 0, 0)
}
