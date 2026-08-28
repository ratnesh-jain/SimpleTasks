//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    public func modify(@ViewBuilder transform: (Self) -> some View) -> some View {
        transform(self)
    }
}

public enum Backport {
    public static func value<T>(iOS27: T, iOS26: T) -> T {
        if #available(iOS 27, *) {
            iOS27
        } else {
            iOS26
        }
    }
}
