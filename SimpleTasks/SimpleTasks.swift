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
import Firebase
import FirebaseServiceLive
import SyncService

@main
struct SimpleTasks: App {
    let store: StoreOf<TasksFeature>
    
    init() {
        withErrorReporting {
            try prepareDependencies {
                try $0.bootstrapDatabase()
            }
        }
        
        FirebaseApp.configure()
        
        store = .init(initialState: .init()) {
            TasksFeature()
        }
        
        @Dependency(\.syncService) var syncService
        syncService.start()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TasksView(store: store)
            }
            .tint(.green)
        }
    }
}
