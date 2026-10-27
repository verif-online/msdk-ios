// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VerifSDK",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "VerifSDK",
            targets: ["VerifSDK", "VerifSDKDesignSystem", "VerifSDKResourceCarrier"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "VerifSDK",
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.1.0/VerifSDK.xcframework.zip",
            checksum: "7730e516694dc4ec1e82c0aeb60160764a3f92e635bb092094fcd7a0a1a470c7"
        ),
        .binaryTarget(
            name: "VerifSDKDesignSystem",
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.1.0/VerifSDKDesignSystem.xcframework.zip",
            checksum: "6ec5565c35d539ce65b54a2cb6f44c47b7b4076fa21f3ba608f5a61c818234c9"
        ),
        .target(
            name: "VerifSDKResourceCarrier",
            resources: [.copy("VerifSDKResources.bundle")]
        ),
    ]
)
