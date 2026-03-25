// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DigiaMoEngage",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "DigiaMoEngage",
            targets: ["DigiaMoEngage"]
        ),
    ],
    dependencies: [
        // Digia Engage iOS SDK (local)
        .package(name: "DigiaEngage", path: "/Users/ram/Digia/digia_engage/iOS"),
        // MoEngage iOS SDK
        .package(
            url: "https://github.com/moengage/MoEngage-iOS-SDK.git",
            from: "9.18.0"
        ),
    ],
    targets: [
        .target(
            name: "DigiaMoEngage",
            dependencies: [
                .product(name: "DigiaEngage", package: "DigiaEngage"),
                .product(name: "MoEngageInApps", package: "MoEngage-iOS-SDK"),
            ],
            path: "Sources/DigiaMoEngage"
        ),
    ]
)
