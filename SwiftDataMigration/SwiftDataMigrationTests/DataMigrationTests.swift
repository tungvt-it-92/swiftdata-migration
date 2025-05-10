//
//  DataMigrationTests.swift
//  SwiftDataMigrationTests
//

import Foundation
import SwiftData
import Testing

@Suite("DataMigrationTests")
class DataMigrationTests {
    var container: ModelContainer!
    var modelContext: ModelContext!
    var databaseUrl: URL!

    init() {
        do {
            databaseUrl = FileManager.default.temporaryDirectory.appending(component: "test.store")
            container = try SwiftDataSharedContainer().createSharedModelContainer(
                databaseUrl: databaseUrl,
                versionSchema: SchemaV1.self
            )
            modelContext = ModelContext(container)
            loadSchemaV1Data()
        } catch {
            fatalError("Failed to initialize container")
        }
    }

    deinit {
        try? FileManager.default.removeItem(at: self.databaseUrl)
        try? FileManager.default.removeItem(at:
            self.databaseUrl.deletingPathExtension().appendingPathExtension("store-shm")
        )
        try? FileManager.default.removeItem(at:
            self.databaseUrl.deletingPathExtension().appendingPathExtension("store-wal")
        )
        self.container = nil
        self.modelContext = nil
        self.databaseUrl = nil
    }

    private func loadSchemaV1Data() {
        let todo = SchemaV1.TodoModel(
            id: UUID(),
            title: "todo-title",
            isFinished: true,
            createdAt: 1
        )
        modelContext.insert(todo)
        try! modelContext.save()
        
        let setting = SchemaV1.SettingModel(
            id: UUID(),
            isNotificationEnabled: true
        )
        modelContext.insert(setting)
        try! modelContext.save()
    }

    @Test("testMigration") func testMigration() async throws {
        let todos = try! modelContext.fetch(FetchDescriptor<SchemaV1.TodoModel>())
        #expect(todos.count == 1)
        #expect(todos[0].title == "todo-title")
        #expect(todos[0].isFinished == true)
        #expect(todos[0].createdAt == 1)
        
        
        let settingV1 = try! modelContext.fetch(FetchDescriptor<SchemaV1.SettingModel>())
        #expect(settingV1.count == 1)
        #expect(settingV1[0].isNotificationEnabled == true)

        // Simulate upgrade
        container = try! SwiftDataSharedContainer().createSharedModelContainer(
            databaseUrl: databaseUrl,
            versionSchema: SchemaV2.self,
            migrationPlan: UpgradeMigrationPlan.self
        )
        modelContext = ModelContext(container)

        // Check existing data after migration
        let todosV2 = try! modelContext.fetch(FetchDescriptor<SchemaV1.TodoModel>())
        #expect(todosV2.count == 1)
        #expect(todosV2[0].title == "todo-title")
        #expect(todosV2[0].isFinished == true)
        #expect(todosV2[0].createdAt == 1)
        
        // Check new property `isEnableSyncCalendar` value
        let settingV2 = try! modelContext.fetch(FetchDescriptor<SchemaV2.SettingModel>())
        #expect(settingV2.count == 1)
        #expect(settingV2[0].isNotificationEnabled == true)
        #expect(settingV2[0].isEnableSyncCalendar == true)
        
        // Simulate downgrade
        container = try! SwiftDataSharedContainer().createSharedModelContainer(
            databaseUrl: databaseUrl,
            versionSchema: SchemaV1.self,
            migrationPlan: DowngradeMigrationPlan.self
        )
        modelContext = ModelContext(container)
        
        let settingV1Downgrade = try! modelContext.fetch(FetchDescriptor<SchemaV1.SettingModel>())
        #expect(settingV1Downgrade.count == 1)
        #expect(settingV1Downgrade[0].isNotificationEnabled == false) // Change to `false` when executing DowngradeMigrationPlan.migrateV2toV1.didMigrate
    }
}
