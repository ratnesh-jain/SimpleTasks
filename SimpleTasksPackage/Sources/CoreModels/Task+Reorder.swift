//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Foundation
import SwiftUI
import SQLiteData

extension Task {
    public static func reorderTasks(
        sourceIDs: [Task.ID],
        droppedTasks: [Task] = [],
        targetSection: TaskSections.SectionType? = nil,
        position: ReorderDifference<Task.ID, TaskSections.SectionType>.Destination.Position = .end
    ) async throws {
        guard !sourceIDs.isEmpty else { return }
        @Dependency(\.defaultDatabase) var database
        
        try await database.write { db in
            for task in droppedTasks {
                let existing = try Task.find(task.id).fetchOne(db)
                if existing == nil {
                    try Task.upsert { task }.execute(db)
                }
            }
            
            let allTasks = try Task.allAvailable
                .order { $0.sortOrder }
                .fetchAll(db)
            
            let movedTasks = sourceIDs.compactMap { id in
                allTasks.first(where: { $0.id == id })
            }
            guard !movedTasks.isEmpty else { return }
            
            let targetStatus: TaskStatus = targetSection?.asTaskStatus ?? movedTasks.first?.status ?? .todo
            var targetSectionTasks = allTasks.filter { $0.status == targetStatus && !sourceIDs.contains($0.id) }
            let insertionIndex: Int
            
            switch position {
            case .before(let targetID):
                if let index = targetSectionTasks.firstIndex(where: { $0.id == targetID }) {
                    insertionIndex = index
                } else {
                    insertionIndex = targetSectionTasks.count
                }
                
            case .end:
                insertionIndex = targetSectionTasks.count
            }
            
            targetSectionTasks.insert(contentsOf: movedTasks, at: insertionIndex)
            
            for (index, task) in targetSectionTasks.enumerated() {
                if task.sortOrder != index || task.status != targetStatus {
                    try Task.find(task.id)
                        .update {
                            $0.sortOrder = index
                            $0.status = targetStatus
                        }
                        .execute(db)
                }
            }
            
            let sourceStatuses = Set(movedTasks.map(\.status)).subtracting([targetStatus])
            for status in sourceStatuses {
                let remainingSectionTasks = allTasks.filter { $0.status == status && !sourceIDs.contains($0.id) }
                for (index, task) in remainingSectionTasks.enumerated() {
                    if task.sortOrder != index {
                        try Task.find(task.id)
                            .update {
                                $0.sortOrder = index
                            }
                            .execute(db)
                    }
                }
            }
        }
    }
}
