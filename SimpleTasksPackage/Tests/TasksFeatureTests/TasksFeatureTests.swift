import CoreModels
import Foundation
import ComposableArchitecture
import Dependencies
import DependenciesTestSupport
import SQLiteData
import SwiftUI
import Testing
@testable import TasksFeature

@Suite(.dependencies {
    try $0.bootstrapDatabase()
    $0.suspendingClock = .test
    $0.date.now = .init(timeIntervalSince1970: 10000)
})
@MainActor
struct TaskFeatureTests {
    @Test
    func seedTests() async throws {
        let store = TestStoreOf<TasksFeature>(initialState: .init()) {
            TasksFeature()
        }
        await store.send(.user(.seedDataButtonTapped))
        
        try await store.state.$sections.load()
        
        expectNoDifference(store.state.sections.sections.flatMap { $0.items }, Task.seedData)
        
        await store.finish()
    }
    
    @Test(.dependencies {
        try $0.seedData {
            Task.seedData
        }
        $0.uuid = UUIDGenerator { UUID(0) }
    })
    func createNewTaskSheet() async throws {
        let store = TestStoreOf<TasksFeature>(initialState: .init()) {
            TasksFeature()
        }
        await store.send(.user(.createButtonTapped)) {
            $0.destination = .createEditTask(.init())
        }
    }
    
    @Test(.dependencies {
        try $0.seedData {
            Task.seedData
        }
    })
    func deleteAlert() async throws {
        let store = TestStoreOf<TasksFeature>(initialState: .init()) {
            TasksFeature()
        }
        let task = store.state.sections.sections[0].items[0]
        await store.send(.user(.taskButtonTapped(task, .delete))) {
            $0.destination = .alert(.delete(task: task))
        }
    
        await store.send(.destination(.presented(.alert(.deleteTask(task.id))))) {
            $0.destination = nil
        }
    }
}
