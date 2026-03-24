// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DigiaMoEngage",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "DigiaMoEngage",
            targets: ["DigiaMoEngage"]
        ),
    ],
    dependencies: [
        // Digia Engage iOS SDK
        .package(
            url: "https://github.com/Digia-Technology-Private-Limited/digia_engage.git",
            from: "1.0.0"
        ),
        // MoEngage iOS SDK
        .package(
            url: "https://github.com/moengage/MoEngage-iOS-SDK.git",
            from: "9.19.0"
        ),
    ],
    targets: [
        .target(
            name: "DigiaMoEngage",
            dependencies: [
                .product(name: "DigiaEngage", package: "digia_engage"),
                .product(name: "MoEngageInApp", package: "MoEngage-iOS-SDK"),
            ],
            path: "Sources/DigiaMoEngage"
        ),
    ]
)
