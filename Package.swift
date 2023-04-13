// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebKitBridge",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "WebKitBridge",
            targets: ["WebKitBridge"]),
    ],
    targets: [
        .target(
            name: "WebKitBridge",
            dependencies: []),
        .testTarget(
            name: "WebKitBridgeTests",
            dependencies: [
                "WebKitBridge"
            ]),
    ]
)
