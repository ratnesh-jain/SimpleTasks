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
import Synchronization

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
    
    public static var alwaysOffline: NetworkStatusService {
        NetworkStatusService {
            let (stream, continuation) = AsyncStream<Bool>.makeStream()
            continuation.yield(false)
            @Shared(.isNetworkReachable) var isNetworkReachable
            $isNetworkReachable.withLock { $0 = false }
            return stream
        }
    }
    
    public static var alwaysOnline: NetworkStatusService {
        NetworkStatusService {
            let (stream, continuation) = AsyncStream<Bool>.makeStream()
            continuation.yield(true)
            @Shared(.isNetworkReachable) var isNetworkReachable
            $isNetworkReachable.withLock { $0 = true }

            return stream
        }
    }
    
    public static func pulsating(seconds: TimeInterval = 5) -> NetworkStatusService {
        NetworkStatusService {
            let (stream, continuation) = AsyncStream<Bool>.makeStream()
            @Dependency(\.suspendingClock) var clock
            let state: Mutex<Bool> = .init(true)
            Swift.Task {
                await withErrorReporting {
                    while true {
                        try await clock.sleep(for: .seconds(seconds))
                        let next = state.withLock { $0 }
                        state.withLock({$0 = !next})
                        continuation.yield(!next)
                        @Shared(.isNetworkReachable) var isNetworkReachable
                        $isNetworkReachable.withLock { $0 = !next }
                    }
                }
            }
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
