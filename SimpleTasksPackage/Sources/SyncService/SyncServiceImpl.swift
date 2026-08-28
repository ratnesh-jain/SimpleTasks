//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import CoreModels
import Foundation
import FirebaseService
import NetworkStatusService
import Sharing
import SQLiteData

struct SyncServiceImpl {
    init() {}
    
    func start() {
        syncPendingItems()
        observeNetworkStatus()
        observeFirestore()
        observeRecords()
    }
    
    func syncPendingItems() {
        Swift.Task {
            await withErrorReporting {
                @Dependency(\.defaultDatabase) var database
                let items = try await database.read { db in
                    try Task.allPendingToSync.fetchAll(db)
                }
                guard !items.isEmpty else { return }
                
                @Dependency(\.firebaseService) var firestore
                let remoteItems = try await firestore.fetchItemsByIDs(collectionName: Task.tableName, documentIDs: items.map { $0.id.uuidString }, documentType: Task.self).compactMap { $0.document as? Task }
                var syncedItemIds: Set<Task.ID> = []
                
                for item in items {
                    do {
                        var copy = item
                        if let remoteItem = remoteItems.first(where: { $0.id == item.id }) {
                            if remoteItem.updatedAt >= item.updatedAt { continue }
                        }
                        copy.uploaded = true
                        try firestore.updateItem(collectionName: Task.tableName, documentID: item.id.uuidString, document: copy)
                        syncedItemIds.insert(item.id)
                    } catch {
                        throw error
                    }
                }
                
                guard !syncedItemIds.isEmpty else { return }
                let syncIds = syncedItemIds
                
                try await database.write { db in
                    try Task.find(syncIds).update { $0.uploaded = true }.execute(db)
                }
            }
        }
    }
    
    func observeNetworkStatus() {
        Swift.Task {
            @Dependency(\.networkStatusService) var networkStatus
            for await isConnected in networkStatus.networkStatusStream() {
                if isConnected {
                    syncPendingItems()
                }
            }
        }
    }
    
    func observeFirestore() {
        Swift.Task {
            await withErrorReporting {
                @Dependency(\.firebaseService) var firestore
                for await change in firestore.collectionUpdateStream(collectionName: Task.tableName, documentType: Task.self) {
                    guard let item = change.data as? Task else { continue }
                    @Dependency(\.defaultDatabase) var database
                    try await database.write { db in
                        switch change.changeType {
                        case .added, .modified:
                            let existing = try Task.find(item.id).fetchOne(db)
                            if let existing {
                                let winner = Task.resolveConflict(between: existing, remote: item)
                                try Task.upsert { winner }.execute(db)
                            } else {
                                try Task.upsert { item }.execute(db)
                            }
                        
                        case .removed:
                            try Task.find(item.id).delete().execute(db)
                        }
                    }
                }
            }
        }
    }
    
    func observeRecords() {
        Swift.Task {
            await withTaskGroup { group in
                group.addTask {
                    await withErrorReporting {
                        @SharedReader(.updatedTaskItems) var updatedItems
                        for await item in updatedItems.stream {
                            @Dependency(\.firebaseService) var firestore
                            @Dependency(\.defaultDatabase) var database
                            
                            let remoteItem = try await firestore.fetchItemsByIDs(collectionName: Task.tableName, documentIDs: [item.id.uuidString], documentType: Task.self).first?.document as? Task
                            if let remoteItem {
                                guard item.updatedAt >= remoteItem.updatedAt else {
                                    try await database.write { db in
                                        try Task.upsert { remoteItem }.execute(db)
                                    }
                                    continue
                                }
                            }
                            
                            var copy = item
                            copy.uploaded = true
                            try firestore.updateItem(collectionName: Task.tableName, documentID: item.id.uuidString, document: copy)
                            
                            try await database.write { db in
                                try Task.find(item.id).update { $0.uploaded = true }.execute(db)
                            }
                        }
                    }
                }
                
                group.addTask {
                    await withErrorReporting {
                        @SharedReader(.deletedTaskItems) var deletedItems
                        for await itemID in deletedItems.stream {
                            @Dependency(\.firebaseService) var firestore
                            try await firestore.deleteItem(collectionName: Task.tableName, documentID: itemID.uuidString)
                        }
                    }
                }
            }
        }
    }
}
