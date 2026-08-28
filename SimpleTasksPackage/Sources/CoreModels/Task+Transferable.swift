//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

extension UTType {
    public static let task = UTType(exportedAs: "com.simpleTasks.task")
}

extension Task: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .task)
    }
}
