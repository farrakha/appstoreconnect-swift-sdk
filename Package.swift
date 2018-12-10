// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "AppStoreConnect-Swift-SDK",
    products: [
        .library(
            name: "AppStoreConnect-Swift-SDK",
            targets: ["AppStoreConnect-Swift-SDK"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .exact("0.9.0"))
    ],
    targets: [
        .target(
            name: "AppStoreConnect-Swift-SDK",
            dependencies: ["CryptoSwift"],
            path: "Sources"),
        .testTarget(
            name: "AppStoreConnect-Swift-SDKTests",
            dependencies: ["AppStoreConnect-Swift-SDK"],
            path: "Example/CocoaPods-AppStoreConnect-Swift-SDK/Tests")
    ]
)
