// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VerifSDK",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "VerifSDK",
            targets: ["VerifSDK", "VerifSDKResourceCarrier"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "VerifSDK",
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.2.0/VerifSDK.xcframework.zip",
            checksum: "49ee96973a606f63685fc6487df9fda793953bde70b85a01cb3c047e1a55b500"
        ),
        .target(
            name: "VerifSDKResourceCarrier",
            resources: [.copy("VerifSDKResources.bundle")]
        ),
    ]
)
