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
    
    @ObservableState
    public struct State: Equatable {
        var task: Task
        var editingScope: Scope
        public var taskID: String?
        
        public init(task: Task? = nil) {
            self.taskID = task?.id.uuidString
            self.task = task ?? Task(title: "", createdBy: "Ratnesh")
            self.editingScope = task == nil ? .new : .edit
        }
    }
    
    public enum Action: Equatable, BindableAction {
        public enum UserAction: Equatable {
            case cancelButtonTapped
            case saveButtonTapped
        }
        
        case binding(BindingAction<State>)
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
                
            case .user(.cancelButtonTapped):
                return .run { send in
                    await dismiss()
                }
                
            case .user(.saveButtonTapped):
                let task = state.task
                return .run { send in
                    try await database.write { db in
                        try Task.upsert { task }.execute(db)
                    }
                    await dismiss()
                }
            }
        }
    }
}
