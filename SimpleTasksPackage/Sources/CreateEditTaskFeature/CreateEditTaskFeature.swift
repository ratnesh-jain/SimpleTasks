//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import ComposableArchitecture
import CoreModels
import Foundation
import SQLiteData

@Reducer
public struct CreateEditTaskFeature: Sendable {
    public enum Scope: Equatable {
        case new
        case edit
        
        var title: String {
            switch self {
            case .new:
                "New Task"
            case .edit:
                "Edit Task"
            }
        }
    }
    
    @Reducer
    public enum Destination {
        case alert(AlertState<CreateEditTaskFeature.Action.AlertAction>)
    }
    
    @ObservableState
    public struct State: Equatable {
        var task: Task
        var editingScope: Scope
        public var taskID: String?
        
        @Presents var destination: Destination.State?
        
        public init(task: Task? = nil) {
            self.taskID = task?.id.uuidString
            self.task = task ?? Task(title: "", createdBy: "Ratnesh")
            self.editingScope = task == nil ? .new : .edit
        }
    }
    
    public enum Action: Equatable, BindableAction {
        public enum AlertAction: Equatable {
            case delete(Task.ID)
        }
        
        public enum UserAction: Equatable {
            case cancelButtonTapped
            case deleteButtonTapped
            case saveButtonTapped
        }
        
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case user(UserAction)
    }
    
    @Dependency(\.defaultDatabase) private var database
    @Dependency(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
                
            case .destination(.presented(.alert(.delete(let taskID)))):
                return .run { send in
                    try await database.write { db in
                        try Task.find(taskID).update { $0.deletedAt = #bind(Date.now) }.execute(db)
                    }
                    await dismiss()
                }
                
            case .destination:
                return .none
                
            case .user(.cancelButtonTapped):
                return .run { send in
                    await dismiss()
                }
                
            case .user(.deleteButtonTapped):
                state.destination = .alert(.init(title: {
                    TextState("Are you sure you want to delete '\(state.task.title)'?")
                }, actions: {
                    ButtonState(role: .destructive, action: .delete(state.task.id)) {
                        TextState("Yes, Delete!")
                    }
                }, message: {
                    TextState("This will be irreversible action.")
                }))
                return .none
                
            case .user(.saveButtonTapped):
                let storedTask = state.task
                return .run { send in
                    try await database.write { db in
                        try Task.upsert { storedTask }.execute(db)
                    }
                    await dismiss()
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension CreateEditTaskFeature.Destination.State: Equatable {}
extension CreateEditTaskFeature.Destination.Action: Equatable {}
