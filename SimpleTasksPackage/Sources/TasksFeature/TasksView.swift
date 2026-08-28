//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import CreateEditTaskFeature
import ComposableArchitecture
import CoreModels
import Dependencies
import Foundation
import SwiftUI

public struct TasksView: View {
    @Bindable private var store: StoreOf<TasksFeature>
    @Namespace private var namespace
    
    public init(store: StoreOf<TasksFeature>) {
        self.store = store
    }
    
    public var body: some View {
        List {
            ForEach(store.sections.sections) { (section: TaskSections.Section) in
                Section {
                    ForEach(section.items) { (item: Task) in
                        TaskItemView(task: item) { (action: TasksFeature.TaskActionType) in
                            store.send(.user(.taskButtonTapped(item, action)))
                        }
                        .matchedTransitionSource(id: item.id, in: namespace)
                    }
                    .onMove { indexSet, destination in
                        store.send(.user(.moveAction(section: section.type, source: indexSet, destination: destination)))
                    }
                } header: {
                    Text(section.type.title)
                }
            }
        }
        .navigationTitle("Simple Tasks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.user(.createButtonTapped), animation: .smooth)
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.glassProminent)
            }
            .matchedTransitionSource(id: "newTask", in: namespace)
            
            #if DEBUG
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.user(.seedDataButtonTapped), animation: .smooth)
                } label: {
                    Image(systemName: "leaf.fill")
                }
            }
            #endif
        }
        .sheet(item: $store.scope(\.destination?.createEditTask, action: \.destination.createEditTask)) { createEditTaskStore in
            NavigationStack {
                CreateEditTaskView(store: createEditTaskStore)
            }
            .navigationTransition(.zoom(sourceID: createEditTaskStore.taskID ?? "newTask", in: namespace))
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }
    
    struct TaskItemView: View {
        let task: Task
        var onAction: (TasksFeature.TaskActionType) -> Void
        
        var body: some View {
            Button {
                onAction(.edit)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(task.title)
                    Spacer()
                    Menu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onAction(.delete)
                        }
                        Divider()
                        switch task.status {
                        case .todo:
                            Button("Move to In Progress") {
                                onAction(.moveToInProgress)
                            }
                            Button("Move to Done") {
                                onAction(.moveToDone)
                            }
                        case .inProgress:
                            Button("Move to To Do") {
                                onAction(.moveToTodo)
                            }
                            Button("Move to Done") {
                                onAction(.moveToDone)
                            }
                        case .done:
                            Button("Move to In Progress") {
                                onAction(.moveToInProgress)
                            }
                            Button("Move to To Do") {
                                onAction(.moveToTodo)
                            }
                        }
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    prepareDependencies {
        do {
            try $0.bootstrapDatabase()
            try $0.seedData {
                Task.seedData
            }
        } catch {
            print(error)
        }
    }
    
    return NavigationStack {
        TasksView(store: .init(initialState: .init(), reducer: {
            TasksFeature()
        }))
    }
}
