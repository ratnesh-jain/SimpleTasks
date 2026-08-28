//
//  SimpleTasks.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import CoreModels
import ComposableArchitecture
import SwiftUI
import TasksFeature

@main
struct SimpleTasks: App {
    let store: StoreOf<TasksFeature>
    
    init() {
        withErrorReporting {
            try prepareDependencies {
                try $0.bootstrapDatabase()
            }
        }
        
        store = .init(initialState: .init()) {
            TasksFeature()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TasksView(store: store)
            }
        }
    }
}
