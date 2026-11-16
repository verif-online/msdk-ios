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
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.3.0/VerifSDK.xcframework.zip",
            checksum: "076a9d02012f2d9cf9fbd1892089db0e7cf363833241d95ee9dea462f7e1d807"
        ),
        .target(
            name: "VerifSDKResourceCarrier",
            resources: [.copy("VerifSDKResources.bundle")]
        ),
    ]
)
