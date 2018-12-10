// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "AppStoreConnect-Swift-SDK",
    products: [
        .library(
            name: "AppStoreConnect-Swift-SDK",
            targets: ["AppStoreConnect-Swift-SDK"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            from: "4.0.0")
    ],
    targets: [
        .target(
            name: "AppStoreConnect-Swift-SDK",
            dependencies: ["Alamofire"],
            path: "Sources"),
        .testTarget(
            name: "AppStoreConnect-Swift-SDKTests",
            dependencies: ["AppStoreConnect-Swift-SDK"],
            path: "Example/CocoaPods-AppStoreConnect-Swift-SDK/Tests")
    ]
)
