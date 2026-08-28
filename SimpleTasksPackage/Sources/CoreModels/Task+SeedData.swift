//
//  File.swift
//  SimpleTasksPackage
//
//  Created by Ratnesh Jain on 28/08/26.
//

import Foundation
import SQLiteData

extension Task {
    public static var seedData: [Task] {
        [
            Task(
                id: UUID(0),
                title: "Design home screen",
                description: "Sketch out the initial layout for the home screen in Figma.",
                status: .todo,
                sortOrder: 1,
                createdBy: "Ratnesh"
            ),
            Task(
                id: UUID(1),
                title: "Write project kickoff doc",
                description: "Draft the scope and goals for the next release.",
                status: .inProgress,
                sortOrder: 2,
                createdBy: "Ratnesh"
            ),
            Task(
                id: UUID(2),
                title: "Review pull requests",
                description: "Go through the open PRs and leave feedback.",
                status: .inProgress,
                sortOrder: 3,
                createdBy: "Ratnesh"
            ),
            Task(
                id: UUID(3),
                title: "Set up CI pipeline",
                description: "Configure the build and test jobs on GitHub Actions.",
                status: .done,
                sortOrder: 4,
                createdBy: "Ratnesh"
            ),
            Task(
                id: UUID(4),
                title: "Ship v1.0",
                description: "Submit the first release to the App Store.",
                status: .done,
                sortOrder: 5,
                createdBy: "Ratnesh"
            ),
        ]
    }
}


