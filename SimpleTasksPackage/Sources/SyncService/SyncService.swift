//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Dependencies
import DependenciesMacros
import FirebaseService
import Foundation

@DependencyClient
public struct SyncService: Sendable {
    public var start: @Sendable () -> Void
}

extension SyncService: DependencyKey {
    public static var liveValue: SyncService {
        let impl = SyncServiceImpl()
        return SyncService {
            impl.start()
        }
    }
}

extension DependencyValues {
    public var syncService: SyncService {
        get { self[SyncService.self] }
        set { self[SyncService.self] = newValue }
    }
}
