//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Dependencies
import DependenciesMacros
import Foundation
import Network

@DependencyClient
public struct NetworkStatusService: Sendable {
    public var networkStatusStream: @Sendable () -> AsyncStream<Bool> = { .finished }
}

extension NetworkStatusService: DependencyKey {
    public static var liveValue: NetworkStatusService {
        NetworkStatusService {
            let (stream, continuation) = AsyncStream<Bool>.makeStream()
            let monitor = NWPathMonitor(requiredInterfaceType: .cellular)
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
            monitor.start(queue: .main)
            return stream
        }
    }
}

extension DependencyValues {
    public var networkStatusService: NetworkStatusService {
        get { self[NetworkStatusService.self] }
        set { self[NetworkStatusService.self] = newValue }
    }
}
