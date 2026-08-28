//
//  TaskSections.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Foundation
import SQLiteData

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
        let todoItems = try Task.allAvailable
            .where { $0.status.eq(TaskStatus.todo) }
            .order { $0.sortOrder }
            .fetchAll(db)
        let inProgressItems = try Task.allAvailable
            .where { $0.status.eq(TaskStatus.inProgress) }
            .order { $0.sortOrder }
            .fetchAll(db)
        let completedItems = try Task.allAvailable
            .where { $0.status.eq(TaskStatus.done) }
            .order { $0.sortOrder }
            .fetchAll(db)
        
        let todoSection = TaskSections.Section(type: .todo, items: todoItems)
        let inProgressSection = TaskSections.Section(type: .inProgress, items: inProgressItems)
        let completedSection = TaskSections.Section(type: .done, items: completedItems)
        
        return TaskSections(sections: [todoSection, inProgressSection, completedSection])
    }
}

extension TaskSections.SectionType {
    public var asTaskStatus: TaskStatus {
        switch self {
        case .todo: .todo
        case .inProgress: .inProgress
        case .done: .done
        }
    }
}
