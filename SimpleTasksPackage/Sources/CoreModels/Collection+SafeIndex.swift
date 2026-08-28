//
//  Collection+SafeIndex.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

extension Collection {
    public subscript(safe index: Index) -> Element? {
        get {
            self.indices.contains(index) ? self[index] : nil
        }
    }
}
