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
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.3.1/VerifSDK.xcframework.zip",
            checksum: "a7266874e6d9ae814c5d5a3ad2684c9224676cbf01c09d17a065a7f5add5b27e"
        ),
        .target(
            name: "VerifSDKResourceCarrier",
            resources: [.copy("VerifSDKResources.bundle")]
        ),
    ]
)
