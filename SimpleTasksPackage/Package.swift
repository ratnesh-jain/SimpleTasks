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
}

let package = Package(
    name: "SimpleTasksPackage",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/sqlite-data", .upToNextMajor(from: "1.11.0")),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "1.26.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CoreModels",
            dependencies: [.sqliteData]
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
            dependencies: ["TasksFeature"],
        ),
    ]
)

let previewFeatures = package.targets.filter { $0.name.hasSuffix("Feature") }.map { $0.name }
package.products.append(contentsOf: previewFeatures.map { .library(name: $0, targets: [$0]) })
