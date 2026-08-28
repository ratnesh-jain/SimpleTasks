//
//  SyncStream.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Foundation

public final class SyncStream<Element: Sendable>: Sendable {
    public let stream: AsyncStream<Element>
    let continuation: AsyncStream<Element>.Continuation
    
    public init() {
        let (stream, continuation) = AsyncStream<Element>.makeStream()
        self.stream = stream
        self.continuation = continuation
    }
    
    public func yield(_ element: Element) {
        continuation.yield(element)
    }
}
