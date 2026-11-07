// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VerifSDK",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "VerifSDK", targets: ["VerifSDK", "VerifSDKResourceCarrier"]),
    ],
    targets: [
        .binaryTarget(
            name: "VerifSDK",
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.2.0/VerifSDK.xcframework.zip",
            checksum: "edde0f3f9311b8d82843c1cac96fb7d906bcd899e06976d58fd17407d9a5e625"
        ),
        .target(
            name: "VerifSDKResourceCarrier",
            resources: [.copy("VerifSDKResources.bundle")]
        ),
    ]
)
