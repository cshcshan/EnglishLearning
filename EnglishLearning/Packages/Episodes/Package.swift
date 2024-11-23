// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Episodes",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Episodes",
            targets: ["Episodes"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup", .upToNextMajor(from: "2.7.5"))
    ],
    targets: [
        .target(
            name: "Episodes",
            dependencies: ["SwiftSoup"]
        ),
        .testTarget(
            name: "EpisodesTests",
            dependencies: ["Episodes"],
            resources: [.process("Resources")]
        ),
    ]
)
