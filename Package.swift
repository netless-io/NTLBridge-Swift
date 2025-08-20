// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NTLBridge",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14)
    ],
    products: [
        .library(
            name: "NTLBridge",
            targets: ["NTLBridge"]
        ),
    ],
    targets: [
        .target(
            name: "NTLBridge",
            dependencies: [],
            path: "Sources/NTLBridge"
        ),
        .testTarget(
            name: "NTLBridgeTests",
            dependencies: ["NTLBridge"],
            path: "Tests/NTLBridgeTests"
        ),
    ]
)