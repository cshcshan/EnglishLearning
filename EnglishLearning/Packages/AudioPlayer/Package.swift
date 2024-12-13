// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AudioPlayer",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "AudioPlayer",
            targets: ["AudioPlayer"]
        ),
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "AudioPlayer",
            dependencies: ["Core"]
        ),
        .testTarget(
            name: "AudioPlayerTests",
            dependencies: ["AudioPlayer"]
        ),
    ]
)
