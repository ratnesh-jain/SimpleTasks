//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import ComposableArchitecture
import CoreModels
import Foundation
import SwiftUI

public struct CreateEditTaskView: View {
    @Bindable var store: StoreOf<CreateEditTaskFeature>
    
    public init(store: StoreOf<CreateEditTaskFeature>) {
        self.store = store
    }
    
    public var body: some View {
        Form {
            Section {
                TextField("Enter Title", text: $store.task.title, axis: .vertical)
                    .lineLimit(2, reservesSpace: false)
            } header: {
                Text("Title")
            }
            
            Section {
                TextField("Enter Description", text: $store.task.description, axis: .vertical)
                    .lineLimit(5, reservesSpace: true)
            } header: {
                Text("Description")
            }
            
            Section {
                Picker("Select State", selection: $store.task.status) {
                    ForEach(TaskStatus.allCases) { status in
                        Text(status.displayText)
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    store.send(.user(.deleteButtonTapped))
                } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Danger Area")
                    .foregroundStyle(.red)
            }
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        .safeAreaInset(edge: .bottom) {
            Text("Last Edited At: \(store.task.updatedAt.formatted(date: .complete, time: .standard))")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.horizontal)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close", role: .cancel) {
                    store.send(.user(.cancelButtonTapped))
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Save", systemImage: "checkmark") {
                    store.send(.user(.saveButtonTapped))
                }
                .buttonStyle(.glassProminent)
                .disabled(store.task.title.isEmpty)
            }
        }
        .navigationTitle(store.editingScope.title)
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
        CreateEditTaskView(store: .init(initialState: .init()) {
            CreateEditTaskFeature()
        })
    }
}
