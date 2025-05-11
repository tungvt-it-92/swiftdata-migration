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
    private var existingSettingID = UUID()

    init() {
        databaseUrl = FileManager.default.temporaryDirectory.appending(component: "test.store")
        do {
            cleanUp(databaseUrl: databaseUrl)
            container = try SwiftDataSharedContainer().createSharedModelContainer(
                databaseUrl: databaseUrl,
                versionSchema: SchemaV1.self
            )
            modelContext = ModelContext(container)
            loadSchemaV1Data()
        } catch {
            cleanUp(databaseUrl: databaseUrl)
            fatalError("Failed to initialize container")
        }
    }
    
    private func cleanUp(databaseUrl: URL) {
        try? FileManager.default.removeItem(at: databaseUrl)
        try? FileManager.default.removeItem(at:databaseUrl.deletingPathExtension().appendingPathExtension("store-shm"))
        try? FileManager.default.removeItem(at:databaseUrl.deletingPathExtension().appendingPathExtension("store-wal"))
        modelContext = nil
        container = nil
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
            id: existingSettingID,
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
        #expect(settingV1[0].id == existingSettingID)

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
        
        // Check renamed property `isPushNotificationEnabled` and new property `isEnableSyncCalendar` value
        let settingV2 = try! modelContext.fetch(FetchDescriptor<SchemaV2.SettingModel>())
        #expect(settingV2.count == 1)
        #expect(settingV2[0].isPushNotificationEnabled == true)
        #expect(settingV2[0].isEnableSyncCalendar == false)
        #expect(settingV2[0].id == existingSettingID)
        
        // Simulate downgrade
        container = try! SwiftDataSharedContainer().createSharedModelContainer(
            databaseUrl: databaseUrl,
            versionSchema: SchemaV1.self,
            migrationPlan: DowngradeMigrationPlan.self
        )
        modelContext = ModelContext(container)
        
        // Check old property `isNotificationEnabled` value
        let settingV1Downgrade = try! modelContext.fetch(FetchDescriptor<SchemaV1.SettingModel>())
        #expect(settingV1Downgrade.count == 1)
        #expect(settingV1Downgrade[0].isNotificationEnabled == true)
        #expect(settingV1Downgrade[0].id == existingSettingID)
    }
}
