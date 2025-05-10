//
//  TodoModel.swift
//  SwiftDataMigration
//

import Foundation
import SwiftData
import AppIntents

extension SchemaV1 {
    @Model
    final class TodoModel: Hashable {
        
        @Attribute(.unique) var id: UUID
        var title: String
        var isFinished: Bool
        var createdAt: TimeInterval
        var scheduledDate: TimeInterval?
        var scheduledAt: TimeInterval?
        var descriptions: String?
        
        var isTaskExpired: Bool {
            return !self.isFinished && self.scheduledAt != nil && self.scheduledAt! < Date.now.timeIntervalSince1970
        }
        
        init(id: UUID,
             title: String,
             isFinished: Bool,
             createdAt: TimeInterval,
             scheduledDate: TimeInterval? = nil,
             scheduledAt: TimeInterval? = nil,
             descriptions: String? = nil
        ) {
            self.id = id
            self.title = title
            self.isFinished = isFinished
            self.createdAt = createdAt
            self.scheduledDate = scheduledDate
            self.scheduledAt = scheduledAt
            self.descriptions = descriptions
        }
    }
}
