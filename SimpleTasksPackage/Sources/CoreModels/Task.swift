//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Foundation
import Sharing
import SQLiteData

public enum TaskStatus: Int, CaseIterable, Codable, Equatable, Identifiable, Sendable, QueryBindable {
    case todo
    case inProgress
    case done
    
    public var id: Self { self }
    
    public var displayText: String {
        switch self {
        case .todo:
            "To Do"
        case .inProgress:
            "In Progress"
        case .done:
            "Done"
        }
    }
}

@Table
public struct Task: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var description: String
    public var status: TaskStatus
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var uploaded: Bool
    public var createdBy: String
    
    public init(id: UUID = .init(), title: String, description: String = "", status: TaskStatus = .todo, sortOrder: Int = 0, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, uploaded: Bool = false, createdBy: String) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.uploaded = uploaded
        self.createdBy = createdBy
    }
}

// MARK: - Database Migration
extension Task: DatabaseMigrating {
    static func migrate(using migrator: inout DatabaseMigrator) throws {
        migrator.registerMigration("Create tasks table") { database in
            try database.create(table: Self.tableName) { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("description", .text).notNull()
                t.column("status", .integer).notNull()
                t.column("sortOrder", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
                t.column("uploaded", .boolean).notNull()
                t.column("createdBy", .text).notNull()
            }
        }
    }
}

extension Task {
    public static var allAvailable: Where<Self> {
        self.where {
            $0.deletedAt.is(nil)
        }
    }
    
    public static var nextOrder: Select<Int?, Task, ()> {
        Task
            .allAvailable
            .where { $0.status.eq(status) }
            .select { $0.sortOrder.max() }
    }
    
    public static var allPendingToSync: Where<Self> {
        Self.all.where { $0.uploaded.eq(false) }
    }
}

extension Task: DatabaseTriggering {
    static func registerTriggers(in database: any DatabaseWriter) throws {
        try database.write { db in
            
            // MARK: - Assign sort order from the total count of rows
            try Task.createTemporaryTrigger(after: .insert { new in
                Task.update {
                    $0.sortOrder = Task.select { $0.count() }
                }
                .where { $0.id.eq(new.id) }
            })
            .execute(db)
            
            // MARK: - Delete trigger
            try Task.createTemporaryTrigger(before: .delete(forEachRow: { old in
                #sql("SELECT \($taskRecordDeleted(old.id))")
            }))
            .execute(db)
            
            // MARK: - Change updatedAt date
            try Task.createTemporaryTrigger(after: .update(touch: { new in
                new.uploaded = false
                new.updatedAt = #sql("datetime('subsec')")
            }, when: { old, new in
                new.status.neq(old.status)
                    .or(new.title.neq(old.title))
                    .or(new.description.neq(old.description))
                    .or(new.sortOrder.neq(old.sortOrder))
                    .or(#sql("\(new.deletedAt) IS NOT \(old.deletedAt)"))
            }))
            .execute(db)
            
            // MARK: - Not Uploaded trigger
            try Task.createTemporaryTrigger(after: .update(forEachRow: { old, new in
                #sql("SELECT \($taskRecordUpdated(new.id))")
            }, when: { old, new in
                new.uploaded.eq(false)
            }))
            .execute(db)
        }
    }
}

@DatabaseFunction
func taskRecordDeleted(id: Task.ID) {
    @Shared(.deletedTaskItems) var deletedItems
    $deletedItems.withLock { $0.yield(id) }
}

@DatabaseFunction
func taskRecordUpdated(id: Task.ID) {
    print("Task record updated for id: \(id)")
    Swift.Task {
        await withErrorReporting {
            @Dependency(\.suspendingClock) var clock
            try await clock.sleep(for: .seconds(1))
            @Dependency(\.defaultDatabase) var database
            let item = try await database.read { db in
                try Task.find(id).fetchOne(db)
            }
            if let item {
                @Shared(.updatedTaskItems) var items
                $items.withLock { $0.yield(item) }
            }
        }
    }
}

extension SharedKey where Self == InMemoryKey<SyncStream<Task.ID>>.Default {
    public static var deletedTaskItems: Self {
        self[.inMemory("deletedTaskItems"), default: .init()]
    }
}

extension SharedKey where Self == InMemoryKey<SyncStream<Task>>.Default {
    public static var updatedTaskItems: Self {
        self[.inMemory("updatedTaskItems"), default: .init()]
    }
}

extension Task {
    public static func move(id: Task.ID, status: TaskStatus, from source: Int, to destination: Int) throws {
        guard source != destination else { return }
        @Dependency(\.defaultDatabase) var database
        try database.write { db in
            // `source`/`destination` are array indices (from SwiftUI's `onMove`),
            // which are not guaranteed to equal the `sortOrder` column values.
            // Resolve the real sort orders of the source and destination items.
            let ordered = try Self.allAvailable
                .where { $0.status.eq(status) }
                .order { $0.sortOrder }
                .fetchAll(db)
            guard
                ordered.indices.contains(source),
                ordered[source].id == id,
                let destinationItem = ordered.indices.contains(destination) ? ordered[destination] : ordered.last
            else { return }

            let sourceOrder = ordered[source].sortOrder
            let destinationOrder = destinationItem.sortOrder

            if sourceOrder < destinationOrder {
                try #sql("""
                UPDATE "\(raw: Task.tableName)"
                SET "sortOrder" = CASE
                    WHEN "id" = \(id) THEN \(destinationOrder)
                    WHEN "sortOrder" > \(sourceOrder)
                        AND "sortOrder" <= \(destinationOrder)
                        THEN "sortOrder" - 1
                    ELSE "sortOrder"
                END
                WHERE "status" = \(status)
                    AND "deletedAt" IS NULL
                    AND (
                        "id" = \(id)
                        OR (
                            "sortOrder" > \(sourceOrder)
                            AND "sortOrder" <= \(destinationOrder)
                        )
                    )
                """)
                .execute(db)
            } else if sourceOrder > destinationOrder {
                try #sql("""
                UPDATE "\(raw: Task.tableName)"
                SET "sortOrder" = CASE
                    WHEN "id" = \(id) THEN \(destinationOrder)
                    WHEN "sortOrder" >= \(destinationOrder)
                        AND "sortOrder" < \(sourceOrder)
                        THEN "sortOrder" + 1
                    ELSE "sortOrder"
                END
                WHERE "status" = \(status)
                    AND "deletedAt" IS NULL
                    AND (
                        "id" = \(id)
                        OR (
                            "sortOrder" >= \(destinationOrder)
                            AND "sortOrder" < \(sourceOrder)
                        )
                    )
                """)
                .execute(db)
            }
        }
    }
}
