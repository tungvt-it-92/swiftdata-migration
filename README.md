# SwiftData Migration

This project demonstrates how to implement and test **custom upgrade and downgrade migrations** using SwiftData's `SchemaMigrationPlan`.

## 🚀 Features

- Custom migration plans for upgrading from `SchemaV1` to `SchemaV2` and downgrading back to `SchemaV1`.
- Unit tests to validate both upgrade and downgrade migration paths.
- Demonstrates best practices for handling schema changes in SwiftData.
- Shows how to handle **property renaming** during migration.

## 📁 Project Structure
- `SchemaV1.swift`: Defines the initial data model schema.

- `SchemaV2.swift`: Defines the updated data model schema with a renamed property.

- `MigrationPlan.swift`: Contains the custom migration plans for upgrading and downgrading between schema versions.

- `DataMigrationTests.swift`: Unit tests that verify the correctness of the migration logic.

## 🔄 Migration Logic
### ⬆️ Upgrade Migration (SchemaV1 → SchemaV2)
#### Changes:
- **Renamed** property: `isNotificationEnabled` → `isPushNotificationEnabled`
- **Added** new property: `isEnableSyncCalendar` (defaulted to `false`)

```
extension SchemaV2 {
    @Model
    final class SettingModel: Identifiable {
        @Attribute(.unique) var id: UUID
        var isPushNotificationEnabled: Bool = false // rename from `isNotificationEnabled`
        var isEnableSyncCalendar: Bool = false // new

        init(
            id: UUID,
            isPushNotificationEnabled: Bool,
            isEnableSyncCalendar: Bool
        ) {
            self.id = id
            self.isPushNotificationEnabled = isPushNotificationEnabled
            self.isEnableSyncCalendar = isEnableSyncCalendar
        }
    }
}
```

The UpgradeMigrationPlan copies data from the old property into the renamed one and initializes the new field. For implementation see `UpgradeMigrationPlan`.

### ⬇️ Downgrade Migration (SchemaV2 → SchemaV1)
When downgrading:
- `isPushNotificationEnabled` is mapped back to is`NotificationEnabled
- `isEnableSyncCalendar` is discarded
- Keeps ID integrity across migrations

For implementation see `DowngradeMigrationPlan`.

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
            id: existingSettingID,
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
    
    let settingV1 = try! modelContext.fetch(FetchDescriptor<SchemaV1.SettingModel>())
    #expect(settingV1.count == 1)
    #expect(settingV1[0].isNotificationEnabled == true)
    #expect(settingV1[0].id == existingSettingID)
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
    
    // Check renamed property `isPushNotificationEnabled` and new property `isEnableSyncCalendar` value
    let settingV2 = try! modelContext.fetch(FetchDescriptor<SchemaV2.SettingModel>())
    #expect(settingV2.count == 1)
    #expect(settingV2[0].isPushNotificationEnabled == true)
    #expect(settingV2[0].isEnableSyncCalendar == false)
    #expect(settingV1[0].id == existingSettingID)
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
    // Check old property `isNotificationEnabled` value
    let settingV1Downgrade = try! modelContext.fetch(FetchDescriptor<SchemaV1.SettingModel>())
    #expect(settingV1Downgrade.count == 1)
    #expect(settingV1Downgrade[0].isNotificationEnabled == true)
    #expect(settingV1Downgrade[0].id == existingSettingID)
```