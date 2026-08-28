//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Dependencies
import Foundation
import SQLiteData
import OSLog

extension DependencyValues {
    public mutating func bootstrapDatabase() throws {
        let logger = Logger(subsystem: "com.simpleTasks", category: "database")
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            #if DEBUG
            db.trace(options: .profile) {
                logger.debug("\($0.expandedDescription)")
            }
            #endif
        }
        
        let url = URL.documentsDirectory.appending(path: "db.sqlite")
        let database = try SQLiteData.defaultDatabase(path: url.path(), configuration: configuration)
        
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        // MARK: - Table Migration
        try Task.migrate(using: &migrator)
        
        // MARK: - Database Migration
        try migrator.migrate(database)
        
        self.defaultDatabase = database
    }
}

extension DependencyValues {
    public func seedData(@SeedsBuilder _ build: () -> [any StructuredQueriesCore.Table]) throws {
        try self.defaultDatabase.write { db in
            try db.seed(build)
        }
    }
}
