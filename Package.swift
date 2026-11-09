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
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.2.1/VerifSDK.xcframework.zip",
            checksum: "b5d1c07f9dabcbbc63ad09556335e5f6d9e205d19715214021b44a3d1c201a1d"
        ),
        .target(
            name: "VerifSDKResourceCarrier",
            resources: [.copy("VerifSDKResources.bundle")]
        ),
    ]
)
