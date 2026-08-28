//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Foundation
import SQLiteData

protocol DatabaseMigrating {
    static func migrate(using migrator: inout DatabaseMigrator) throws
}
