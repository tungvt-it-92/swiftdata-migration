//
//  SwiftDataSharedContainer.swift
//  SwiftDataMigration
//

import SwiftData
import Foundation

struct SwiftDataSharedContainer {
    static let shared = SwiftDataSharedContainer()
    var sharedModelContainer: ModelContainer?
    
    func createSharedModelContainer(
        databaseUrl: URL,
        versionSchema: VersionedSchema.Type = SchemaV2.self,
        migrationPlan: (SchemaMigrationPlan.Type)? = nil,
        tryCount: Int = 2
    ) throws -> ModelContainer {
        do {
            let schema = Schema(versionedSchema: versionSchema)
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                url: databaseUrl,
                cloudKitDatabase: .none
            )
            
            let container = try ModelContainer(
                for: schema,
                migrationPlan: migrationPlan,
                configurations: [modelConfiguration]
            )
            Log.debug("get sharedModelContainer \(String(describing: container.migrationPlan))")
            
            return container
        } catch is SwiftDataError {
            if tryCount < 2 {
                let schema = Schema(versionedSchema: SchemaV1.self)
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    url: databaseUrl,
                    cloudKitDatabase: .none
                )
                _ = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                Log.debug("Created containerV1")
                Log.debug("try to create sharedModelContainer again tryCount: \(tryCount)")
                return try createSharedModelContainer(databaseUrl: databaseUrl, tryCount: tryCount + 1)
            }
        } catch {
            throw error
        }
        
        throw NSError(domain: "SwiftDataSharedContainer", code: 0)
    }
}
