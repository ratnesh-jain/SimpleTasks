//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import CreateEditTaskFeature
import ComposableArchitecture
import CoreModels
import Foundation
import NetworkStatusService
import SQLiteData
import Sharing
import SwiftUI

@Reducer
public struct TasksFeature: Sendable {
    public enum TaskActionType: Equatable {
        case edit
        case delete
        case moveToTodo
        case moveToInProgress
        case moveToDone
    }
    
    @Reducer
    public enum Destination {
        case createEditTask(CreateEditTaskFeature)
        case alert(AlertState<TasksFeature.Action.AlertAction>)
    }
    
    @ObservableState
    public struct State: Equatable {
        @Fetch(TaskSectionsRequest(), animation: .smooth) var sections: TaskSections = .init()
        @SharedReader(.isNetworkReachable) var isNetworkReachable
        
        @Presents var destination: Destination.State?
        public init() {}
    }
    
    public enum Action: Equatable {
        public enum AlertAction: Equatable {
            case deleteTask(Task.ID)
        }
        
        public enum UserAction: Equatable {
            case createButtonTapped
            case taskButtonTapped(Task, TaskActionType)
            case seedDataButtonTapped
            case moveAction(section: TaskSections.SectionType, source: IndexSet, destination: Int)
            case dropItems([Task], toSection: TaskSections.SectionType)
            case reorderAction(ReorderDifference<Task.ID, TaskSections.SectionType>)
            case dropAction([Task], destination: ReorderDifference<Task.ID, TaskSections.SectionType>.Destination?)
        }
        
        case destination(PresentationAction<Destination.Action>)
        case user(UserAction)
    }
    
    @Dependency(\.defaultDatabase) private var database
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .destination(.presented(.alert(.deleteTask(let taskID)))):
                return .run { send in
                    try await database.write { db in
                        try Task.find(taskID).update(set: {
                            $0.deletedAt = #bind(Date.now)
                        }).execute(db)
                    }
                }
                
            case .destination:
                return .none
                
            case .user(.createButtonTapped):
                state.destination = .createEditTask(.init())
                return .none
                                
            case .user(.taskButtonTapped(let task, let actionType)):
                switch actionType {
                case .delete:
                    state.destination = .alert(.init(title: {
                        TextState("Are you sure you want to delete '\(task.title)'?")
                    }, actions: {
                        ButtonState(role: .destructive, action: .deleteTask(task.id)) {
                            TextState("Yes, Delete!")
                        }
                    }, message: {
                        TextState("This will be an irreversible action.")
                    }))
                    return .none
                    
                case .edit:
                    state.destination = .createEditTask(.init(task: task))
                    return .none
                    
                case .moveToDone:
                    return .run { send in
                        try await database.write { db in
                            try Task.find(task.id).update {
                                $0.status = TaskStatus.done
                            }
                            .execute(db)
                        }
                    }
                    
                case .moveToTodo:
                    return .run { send in
                        try await database.write { db in
                            try Task.find(task.id).update {
                                $0.status = TaskStatus.todo
                            }
                            .execute(db)
                        }
                    }
                    
                case .moveToInProgress:
                    return .run { send in
                        try await database.write { db in
                            try Task.find(task.id).update {
                                $0.status = TaskStatus.inProgress
                            }
                            .execute(db)
                        }
                    }
                }
                
            case .user(.seedDataButtonTapped):
                return .run { send in
                    try await database.write { db in
                        try db.seed {
                            Task.seedData
                        }
                    }
                }
                
            case .user(.moveAction(let sectionType, let source, let destination)):
                guard
                    let sectionIndex = state.sections.sections.firstIndex(where: { $0.type == sectionType }),
                    let movedTask = state.sections.sections[sectionIndex].items[safe: source.first ?? -1]
                else { return .none }
                
                return .run { send in
                    try Task.move(id: movedTask.id, status: sectionType.asTaskStatus, from: source.first!, to: destination)
                }
                
            case .user(.dropItems(let items, let section)):
                return .run { send in
                    try await Task.reorderTasks(
                        sourceIDs: items.map(\.id),
                        droppedTasks: items,
                        targetSection: section,
                        position: .end
                    )
                }
                
            case .user(.reorderAction(let reorderDifference)):
                return .run { send in
                    try await Task.reorderTasks(
                        sourceIDs: reorderDifference.sources,
                        targetSection: reorderDifference.destination.collectionID,
                        position: reorderDifference.destination.position
                    )
                }
                
            case .user(.dropAction(let tasks, let destination)):
                return .run { send in
                    try await Task.reorderTasks(
                        sourceIDs: tasks.map(\.id),
                        droppedTasks: tasks,
                        targetSection: destination?.collectionID,
                        position: destination?.position ?? .end
                    )
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension TasksFeature.Destination.State: Equatable {}
extension TasksFeature.Destination.Action: Equatable {}
