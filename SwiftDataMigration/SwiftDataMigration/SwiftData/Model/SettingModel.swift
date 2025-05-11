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
        var isNotificationEnabled: Bool = false
        
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
