//
//  SettingModel.swift
//  SwiftDataMigration
//

import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    final class SettingModel: Identifiable {
        
        @Attribute(.unique) var id: UUID
        var isNotificationEnabled: Bool
        
        init(id: UUID, isNotificationEnabled: Bool) {
            self.id = id
            self.isNotificationEnabled = isNotificationEnabled
        }
    }
}

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
