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
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.1.1/VerifSDK.xcframework.zip",
            checksum: "38f83af629d3782422669188c63e9b0ab14878d12aeea37066ba0d2119192eb6"
        ),
        .binaryTarget(
            name: "VerifSDKDesignSystem",
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.1.1/VerifSDKDesignSystem.xcframework.zip",
            checksum: "83e7060e052cf89470a49e5b3f455b4110b3b8d63e9fbc0542029ae238cb5b7e"
        ),
        .target(
            name: "VerifSDKResourceCarrier",
            resources: [.copy("VerifSDKResources.bundle")]
        ),
    ]
)
