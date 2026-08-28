//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Dependencies
import FirebaseService
import FirebaseFirestore
import Synchronization
import OSLog

extension FirebaseService: DependencyKey {
    public static var liveValue: FirebaseService {
        let logger = Logger(subsystem: "com.simpleTasks", category: "FirebaseService")
        return FirebaseService { name, parameters in
            logger.info("Added log event for Event: \(name) with parameters: \(parameters)")
        } fetchItems: { collectionName, type in
            let snapshot = try await Firestore.firestore().collection(collectionName).getDocuments()
            return await withTaskGroup(of: [FirestoreDocument].self) { group in
                for document in snapshot.documents {
                    group.addTask {
                        do {
                            let data = try document.data(as: type)
                            return [FirestoreDocument(document: data)]
                        } catch {
                            reportIssue(error, "Collection name: \(collectionName),\ndata: \(document.data())")
                            return []
                        }
                    }
                }
                var items: [FirestoreDocument] = []
                for await itemCollection in group {
                    items.append(contentsOf: itemCollection)
                }
                return items
            }
        } fetchItemsByIDs: { collectionName, documentIDs, documentType in
            guard !documentIDs.isEmpty else { return [] }
            let snapshot = try await Firestore.firestore().collection(collectionName).whereField(FieldPath.documentID(), in: documentIDs).getDocuments()
            return await withTaskGroup(of: [FirestoreDocument].self) { group in
                for document in snapshot.documents {
                    group.addTask {
                        do {
                            let data = try document.data(as: documentType)
                            return [FirestoreDocument(document: data)]
                        } catch {
                            reportIssue(error, "Collection name: \(collectionName),\ndata: \(document.data())")
                            return []
                        }
                    }
                }
                var items: [FirestoreDocument] = []
                for await itemCollection in group {
                    items.append(contentsOf: itemCollection)
                }
                return items
            }
        } deleteItem: { collectionName, documentID in
            try await Firestore.firestore().collection(collectionName).document(documentID).delete()
            logger.debug("Deleted Firestore document from collectionName: \(collectionName), documentID: \(documentID)")
        } deleteItemsWhere: { collectionName, key, values in
            let batch = Firestore.firestore().batch()
            let docs = try await Firestore.firestore().collection(collectionName).whereField(key, in: values).getDocuments()
            docs.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
        } updateItem: { collectionName, documentID, document in
            try Firestore.firestore().collection(collectionName).document(documentID).setData(from: document)
            logger.debug("Update Firestore document from collectionName: \(collectionName), documentID: \(documentID)")
        } collectionUpdateStream: { collectionName, type in
            AsyncStream { continuation in
                let listener = Firestore.firestore().collection(collectionName).addSnapshotListener { snapshot, error in
                    if let error {
                        reportIssue(error)
                    }
                    for change in snapshot?.documentChanges ?? [] {
                        do {
                            let data = try change.document.data(as: type)
                            continuation.yield(ChangedDocument(changeType: change.type.changeType, data: data))
                        } catch {
                            reportIssue(error, "Collection name: \(collectionName),\ndata: \(change.document.data())")
                        }
                    }
                }
                
                let mutexListener: Mutex<any ListenerRegistration> = .init(listener)
                
                continuation.onTermination = { termination in
                    mutexListener.withLock { $0.remove() }
                    debugPrint("Firestore Collection Update Async stream terminated for : \(collectionName) due to: \(termination)")
                }
            }
        } collectionUpdateStreamWhere: { collectionName, type, key, value in
            AsyncStream { continuation in
                let listener = Firestore.firestore().collection(collectionName).whereField(key, isEqualTo: value).addSnapshotListener { snapshot, error in
                    if let error {
                        reportIssue(error)
                    }
                    for change in snapshot?.documentChanges ?? [] {
                        do {
                            let data = try change.document.data(as: type)
                            continuation.yield(ChangedDocument(changeType: change.type.changeType, data: data))
                        } catch {
                            reportIssue(error, "Collection name: \(collectionName),\ndata: \(change.document.data())")
                        }
                    }
                }
                
                let mutexListener: Mutex<any ListenerRegistration> = .init(listener)
                
                continuation.onTermination = { termination in
                    mutexListener.withLock { $0.remove() }
                    debugPrint("Firestore Collection Update Async stream terminated for : \(collectionName) due to: \(termination)")
                }
            }
        } documentUpdateStream: { collectionName, documentID, documentType in
            AsyncStream { continuation in
                let listener = Firestore.firestore().collection(collectionName).document(documentID).addSnapshotListener { snapshot, error in
                    if let error {
                        reportIssue(error)
                    }
                    if let data = try? snapshot?.data(as: documentType) {
                        continuation.yield(.init(document: data))
                    }
                }
                
                let mutexListener: Mutex<any ListenerRegistration> = .init(listener)
                
                continuation.onTermination = { termination in
                    mutexListener.withLock { $0.remove() }
                    debugPrint("Firestore Document Update Async stream terminated for : \(collectionName) due to: \(termination)")
                }

            }
        } fetchItemsWhere: { collectionName, type, key, value in
            let documents = try await Firestore.firestore()
                .collection(collectionName)
                .whereField(key, isEqualTo: value)
                .getDocuments()
            return try documents.documents.map { .init(document: try $0.data(as: type)) }
        } firebaseUserID: {
            //Auth.auth().currentUser?.uid
            return nil
        }
    }
}
struct CommunityRequestCode: Codable, Equatable, Sendable {
    var userID: String
    var code: String
    var email: String
    var expiresAt: Date
}

public enum FirestoreRequestCodeError: Error, Sendable, LocalizedError {
    case invalidCodeOrEmail
    case codeExpired
    
    public var errorDescription: String? {
        switch self {
        case .invalidCodeOrEmail:
            "Invalid Code or Email. Please try again."
        case .codeExpired:
            "Code Expired. Please request new one."
        }
    }
}

extension DocumentChangeType {
    var changeType: ChangeType {
        switch self {
        case .added: .added
        case .modified: .modified
        case .removed: .removed
        }
    }
}
