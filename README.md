# SwiftData Migration

This project demonstrates how to implement and test **custom upgrade and downgrade migrations** using SwiftData's `SchemaMigrationPlan`.  

## 🚀 Features

- Custom migration plans for upgrading from `SchemaV1` to `SchemaV2` and downgrading back to `SchemaV1`.
- Unit tests to validate both upgrade and downgrade migration paths.
- Demonstrates best practices for handling schema changes in SwiftData.

## 📁 Project Structure
- `SchemaV1.swift`: Defines the initial data model schema.

- `SchemaV2.swift`: Defines the updated data model schema with additional properties.

- `MigrationPlan.swift`: Contains the custom migration plans for upgrading and downgrading between schema versions.

- `DataMigrationTests.swift`: Unit tests that verify the correctness of the migration logic.

## 🔄 Migration Logic
### ⬆️ Upgrade Migration (SchemaV1 → SchemaV2)
- Add new property `isEnableSyncCalendar` to existing `SettingModel`
```
extension SchemaV2 {
    @Model
    final class SettingModel: Identifiable {
        @Attribute(.unique) var id: UUID
        var isNotificationEnabled: Bool
        var isEnableSyncCalendar: Bool = true

        init(
            id: UUID,
            isNotificationEnabled: Bool,
            isEnableSyncCalendar: Bool = false
        ) {
            self.id = id
            self.isNotificationEnabled = isNotificationEnabled
            self.isEnableSyncCalendar = isEnableSyncCalendar
        }
    }
}
```

When upgrading, the migration plan sets the new property `isEnableSyncCalendar` to `true` for existing records. For implementation see `UpgradeMigrationPlan`.

### ⬇️ Downgrade Migration (SchemaV2 → SchemaV1)
During downgrade, the migration plan sets the `isNotificationEnabled` property to `false` to maintain data consistency. For implementation see `DowngradeMigrationPlan`.

## 🧪 Test Logic Explanation
The `DataMigrationTests` suite verifies the correctness of both upgrade and downgrade migration.

### Test Flow: `testMigration`

#### 1. Initialize SchemaV1 Store
```
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
```

#### 2. Verify Initial V1 State
```
       let todos = try! modelContext.fetch(FetchDescriptor<SchemaV1.TodoModel>())
        #expect(todos.count == 1)
        #expect(todos[0].title == "todo-title")
        #expect(todos[0].isFinished == true)
        #expect(todos[0].createdAt == 1)
```

#### 3. Simulate Upgrade to SchemaV2
```
        // Simulate upgrade
        container = try! SwiftDataSharedContainer().createSharedModelContainer(
            databaseUrl: databaseUrl,
            versionSchema: SchemaV2.self,
            migrationPlan: UpgradeMigrationPlan.self
        )
        modelContext = ModelContext(container)
```

#### 4. Verify Upgraded V2 State
```
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
```

#### 5. Simulate Downgrade to SchemaV1
```
        // Simulate downgrade
        container = try! SwiftDataSharedContainer().createSharedModelContainer(
            databaseUrl: databaseUrl,
            versionSchema: SchemaV1.self,
            migrationPlan: DowngradeMigrationPlan.self
        )
        modelContext = ModelContext(container)
```

#### 6. Verify Downgraded V1 State
Confirm isNotificationEnabled is set to false, as defined in the downgrade logic.
```
    let settingV1Downgrade = try! modelContext.fetch(FetchDescriptor<SchemaV1.SettingModel>())
    #expect(settingV1Downgrade.count == 1)
    #expect(settingV1Downgrade[0].isNotificationEnabled == false)
```