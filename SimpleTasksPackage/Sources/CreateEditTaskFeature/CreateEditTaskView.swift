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
            } footer: {
                HStack {
                    Text("Last Edited At:")
                    Spacer()
                    Text(store.task.updatedAt.formatted(date: .complete, time: .standard))
                }
            }
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
