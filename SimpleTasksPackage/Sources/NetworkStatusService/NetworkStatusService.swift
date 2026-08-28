//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import CoreModels
import Dependencies
import DependenciesMacros
import Foundation
import Network
import Sharing

@DependencyClient
public struct NetworkStatusService: Sendable {
    public var networkStatusStream: @Sendable () -> AsyncStream<Bool> = { .finished }
}

extension NetworkStatusService: DependencyKey {
    public static var liveValue: NetworkStatusService {
        NetworkStatusService {
            let (stream, continuation) = AsyncStream<Bool>.makeStream()
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                let isReachable = path.status == .satisfied
                continuation.yield(isReachable)
                @Shared(.isNetworkReachable) var isNetworkReachable
                $isNetworkReachable.withLock { $0 = isReachable }
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

extension SharedKey where Self == InMemoryKey<Bool>.Default {
    public static var isNetworkReachable: Self {
        self[.inMemory("isNetworkReachable"), default: false]
    }
}
