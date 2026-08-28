//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Foundation
import SQLiteData

public enum TaskStatus: Int, Codable, Equatable, Sendable, QueryBindable {
    case todo
    case inProgress
    case done
}

@Table
public struct Task: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var description: String
    public var status: TaskStatus
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var uploaded: Bool
    public var createdBy: String
    
    public init(id: UUID = .init(), title: String, description: String = "", status: TaskStatus = .todo, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, uploaded: Bool = false, createdBy: String) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
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
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("uploaded", .boolean).notNull()
                t.column("createdBy", .text).notNull()
            }
        }
        migrator.registerMigration("Add column 'deletedAt' to 'tasks'") { database in
            try database.alter(table: Self.tableName) { t in
                t.add(column: "deletedAt", .datetime)
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
}

// MARK: - Seed Data
extension Task {
    public static var seedData: [Task] {
        [
            Task(
                id: UUID(0),
                title: "Design home screen",
                description: "Sketch out the initial layout for the home screen in Figma.",
                status: .todo,
                createdBy: "Ratnesh"
            ),
            Task(
                id: UUID(1),
                title: "Write project kickoff doc",
                description: "Draft the scope and goals for the next release.",
                status: .inProgress,
                createdBy: "Ratnesh"
            ),
            Task(
                id: UUID(2),
                title: "Review pull requests",
                description: "Go through the open PRs and leave feedback.",
                status: .inProgress,
                createdBy: "Ratnesh"
            ),
            Task(
                id: UUID(3),
                title: "Set up CI pipeline",
                description: "Configure the build and test jobs on GitHub Actions.",
                status: .done,
                createdBy: "Ratnesh"
            ),
            Task(
                id: UUID(4),
                title: "Ship v1.0",
                description: "Submit the first release to the App Store.",
                status: .done,
                createdBy: "Ratnesh"
            ),
        ]
    }
}

// MARK: - Task Sections

public struct TaskSections: Equatable, Sendable {
    public enum SectionType: Equatable, Identifiable, Sendable {
        case todo
        case inProgress
        case done
        
        public var id: Self { self }
        
        public var title: String {
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
    
    public struct Section: Equatable, Identifiable, Sendable {
        public var type: SectionType
        public var items: [Task]
        
        public var id: SectionType { self.type }
        
        public init(type: SectionType, items: [Task]) {
            self.type = type
            self.items = items
        }
        
        public var isEmpty: Bool {
            self.items.isEmpty
        }
    }
    
    public var sections: [Section]
    
    public init(sections: [Section] = []) {
        self.sections = sections
    }
    
    public var isEmpty: Bool {
        self.sections.isEmpty
    }
}

public struct TaskSectionsRequest: FetchKeyRequest, Equatable {
    public init() {}
    
    public func fetch(_ db: Database) throws -> TaskSections {
        let todoItems = try Task.allAvailable.where { $0.status.eq(TaskStatus.todo) }.fetchAll(db)
        let inProgressItems = try Task.allAvailable.where { $0.status.eq(TaskStatus.inProgress) }.fetchAll(db)
        let completedItems = try Task.allAvailable.where { $0.status.eq(TaskStatus.done) }.fetchAll(db)
        
        let todoSection = TaskSections.Section(type: .todo, items: todoItems)
        let inProgressSection = TaskSections.Section(type: .inProgress, items: inProgressItems)
        let completedSection = TaskSections.Section(type: .done, items: completedItems)
        
        return TaskSections(sections: [todoSection, inProgressSection, completedSection])
    }
}
