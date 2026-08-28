// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

extension Target.Dependency {
    static var tca: Self {
        product(name: "ComposableArchitecture", package: "swift-composable-architecture")
    }
    static var sqliteData: Self {
        product(name: "SQLiteData", package: "sqlite-data")
    }
    static var firestore: Self {
        product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
    }
    static var dependencies: Self {
        .product(name: "Dependencies", package: "swift-dependencies")
    }
    static var dependenciesMacros: Self {
        .product(name: "DependenciesMacros", package: "swift-dependencies")
    }
}

let package = Package(
    name: "SimpleTasksPackage",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "FirebaseServiceLive", targets: ["FirebaseServiceLive"]),
        .library(name: "SyncService", targets: ["SyncService"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/sqlite-data", .upToNextMajor(from: "1.11.0")),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "1.26.1")),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", .upToNextMajor(from: "12.5.0")),
    ],
    targets: [
        .target(
            name: "CoreModels",
            dependencies: [.sqliteData]
        ),
        .target(
            name: "NetworkStatusService",
            dependencies: [
                .dependencies,
                .dependenciesMacros
            ]
        ),
        .target(
            name: "FirebaseService",
            dependencies: [
                .dependencies,
                .dependenciesMacros
            ]
        ),
        .target(
            name: "FirebaseServiceLive",
            dependencies: [
                "FirebaseService",
                .firestore,
            ]
        ),
        .target(
            name: "SyncService",
            dependencies: [
                "CoreModels",
                "FirebaseService",
                "NetworkStatusService",
            ]
        ),
        .target(
            name: "CreateEditTaskFeature",
            dependencies: [
                "CoreModels",
                .tca
            ]
        ),
        .target(
            name: "TasksFeature",
            dependencies: [
                "CreateEditTaskFeature",
            ]
        ),
        .testTarget(
            name: "TasksFeatureTests",
            dependencies: [
                "CoreModels",
                .sqliteData,
            ],
        ),
    ]
)

let previewFeatures = package.targets.filter { $0.name.hasSuffix("Feature") }.map { $0.name }
package.products.append(contentsOf: previewFeatures.map { .library(name: $0, targets: [$0]) })
