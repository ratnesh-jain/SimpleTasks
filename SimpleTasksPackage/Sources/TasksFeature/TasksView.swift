//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import AppUserInterfaceUtilities
import CreateEditTaskFeature
import ComposableArchitecture
import CoreModels
import Dependencies
import Foundation
import NetworkStatusService
import SyncService
import SwiftUI

public struct TasksView: View {
    @Bindable private var store: StoreOf<TasksFeature>
    @Namespace private var namespace
    
    public init(store: StoreOf<TasksFeature>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(store.sections.sections) { (section: TaskSections.Section) in
                    Section {
                        LazyVStack(spacing: 0) {
                            if section.items.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "checklist")
                                        .font(.title)
                                    Text("Drag Items here")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 132)
                                .foregroundStyle(.secondary)
                                .contentShape(.rect)
                                .dropDestination(for: Task.self) { tasks, location in
                                    store.send(.user(.dropItems(tasks, toSection: section.type)), animation: .smooth)
                                    return true
                                }
                            } else {
                                ForEach(section.items) { item in
                                    TaskItemView(task: item, namespace: namespace) { action in
                                        store.send(.user(.taskButtonTapped(item, action)))
                                    }
                                    .padding()
                                    .overlay(alignment: .bottom) {
                                        if item.id != section.items.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .reorderable(collectionID: section.type)
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color(.separator), style: .init(lineWidth: 1, dash: [10, 5]))
                                .padding(2)
                        }
                        .clipShape(.rect(cornerRadius: 24, style: .continuous))
                    } header: {
                        Text(section.type.title)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.secondary)
                            .padding([.horizontal, .top])
                    }
                }
            }
            .reorderContainer(for: Task.self, in: TaskSections.SectionType.self, move: { difference in
                store.send(.user(.reorderAction(difference)))
            })
            .dragContainer(for: Task.self) { itemIds in
                @Dependency(\.defaultDatabase) var database
                return (try? database.read { db in
                    try Task.find(itemIds).fetchAll(db)
                }) ?? []
            }
            .dragConfiguration(DragConfiguration(allowMove: true))
            .dropDestination(for: Task.self, action: { tasks, session in
                let destination = session.reorderDestination(for: Task.self, in: TaskSections.SectionType.self)
                store.send(.user(.dropAction(tasks, destination: destination)))
            })
            .padding()
        }
        .searchable(text: $store.searchText)
        .scrollContentBackground(.hidden)
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
        .overlay {
            if store.sections.isEmpty && store.searchText.isEmpty {
                ContentUnavailableView {
                    Label("No Tasks", systemImage: "checklist")
                } description: {
                    Text("Create new task")
                } actions: {
                    Button("Create Task", systemImage: "checkmark") {
                        store.send(.user(.createButtonTapped), animation: .smooth)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                }
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            HStack {
                Circle()
                    .fill(store.isNetworkReachable ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(store.isNetworkReachable ? "Connected" : "Disconnected")
                    .contentTransition(.numericText())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .animation(.smooth, value: store.isNetworkReachable)
        })
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
                if store.sections.isEmpty {
                    Button {
                        store.send(.user(.seedDataButtonTapped), animation: .smooth)
                    } label: {
                        Image(systemName: "leaf.fill")
                    }
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
        let namespace: Namespace.ID
        var onAction: (TasksFeature.TaskActionType) -> Void
        
        var body: some View {
            Button {
                onAction(.edit)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    if task.status == .done {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor.secondary)
                    }
                    Text(task.title)
                        .foregroundStyle(task.status == .done ? .secondary : .primary)
                        .matchedTransitionSource(id: task.id, in: namespace)
                    Spacer()
                    Menu {
                        Button("Edit", systemImage: "square.and.pencil") {
                            onAction(.edit)
                        }
                        Divider()
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            onAction(.delete)
                        }
                        .tint(.red)
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
                            .foregroundStyle(Color.accentColor)
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
        
        $0.networkStatusService = .pulsating(seconds: 2)
        $0.syncService.start()
    }
    
    return NavigationStack {
        TasksView(store: .init(initialState: .init(), reducer: {
            TasksFeature()
        }))
    }
}
