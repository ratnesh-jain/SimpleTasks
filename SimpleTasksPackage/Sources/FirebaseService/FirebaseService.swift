//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Dependencies
import DependenciesMacros
import Foundation

public enum ChangeType: Sendable {
    case added
    case modified
    case removed
}

public struct ChangedDocument: Sendable {
    public var changeType: ChangeType
    public var data: any (Decodable & Sendable)
    
    public init(changeType: ChangeType, data: any (Decodable & Sendable)) {
        self.changeType = changeType
        self.data = data
    }
}

public struct FirestoreDocument: Sendable {
    public var document: any Decodable & Sendable
    
    public init(document: any Decodable & Sendable) {
        self.document = document
    }
    
    public func asItem<T: Decodable & Sendable>(_ type: T.Type = T.self) -> T? {
        self.document as? T
    }
}

@DependencyClient
public struct FirebaseService: Sendable {
    public var logEvent: @Sendable (_ name: String, _ parameters: [String: String]) async -> Void
    public var fetchItems: @Sendable (_ collectionName: String, _ documentType: sending (Decodable & Sendable).Type) async throws -> [FirestoreDocument]
    public var fetchItemsByIDs: @Sendable (_ collectionName: String, _ documentIDs: [String], _ documentType: (Decodable & Sendable).Type) async throws -> [FirestoreDocument]
    public var deleteItem: @Sendable (_ collectionName: String, _ documentID: String) async throws -> Void
    public var deleteItemsWhere: @Sendable (_ collectionName: String, _ key: String, _ ids: [String]) async throws -> Void
    public var updateItem: @Sendable (_ collectionName: String, _ documentID: String, _ document: any (Codable)) throws -> Void
    public var collectionUpdateStream: @Sendable (_ collectionName: String, _ documentType: (Decodable & Sendable).Type) -> AsyncStream<ChangedDocument> = { _, _ in .finished }
    public var collectionUpdateStreamWhere: @Sendable (_ collectionName: String, _ documentType: (Decodable & Sendable).Type, _ key: String, _ value: String) -> AsyncStream<ChangedDocument> = { _, _, _, _ in .finished }
    public var documentUpdateStream: @Sendable (_ collectionName: String, _ documentID: String, _ documentType: (Decodable & Sendable).Type) -> AsyncStream<FirestoreDocument> = { _, _, _ in .finished }
    public var fetchItemsWhere: @Sendable (_ collectionName: String, _ documentType: (Decodable & Sendable).Type, _ key: String, _ value: String) async throws -> [FirestoreDocument]
    public var firebaseUserID: @Sendable () -> String?
}

extension FirebaseService: TestDependencyKey {
    public static var testValue: FirebaseService {
        FirebaseService  { name, parameters in
            // NO-OP
        } fetchItems: { collectionName, documentType in
            // NO-OP
            return []
        } fetchItemsByIDs: { collectionName, documentIDs, documentType in
            // NO-OP
            return []
        } deleteItem: { collectionName, documentID in
            // NO-OP
        } deleteItemsWhere: { collectionName, key, values in
            // NO-OP
        } updateItem: { collectionName, documentID, document in
            // NO-OP
        } collectionUpdateStream: { collectionName, documentType in
            .finished
        } collectionUpdateStreamWhere: { collectionName, documentType, key, value in
            .finished
        } documentUpdateStream: { collectionName, documentID, documentType in
            .finished
        } fetchItemsWhere: { collectionName, documentType, key, value in
            // NO-OP
            return []
        } firebaseUserID: {
            // NO-OP
            return nil
        }
    }
    
    public static var previewValue: FirebaseService {
        Self.testValue
    }
}

extension DependencyValues {
    public var firebaseService: FirebaseService {
        get { self[FirebaseService.self] }
        set { self[FirebaseService.self] = newValue }
    }
}

