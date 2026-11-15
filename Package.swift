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
            url: "https://github.com/verif-online/msdk-ios/releases/download/0.2.2/VerifSDK.xcframework.zip",
            checksum: "855aa1ea8815ed15ab363f2d212dad5118386b42171faa14efdb906a3f1ce975"
        ),
        .target(
            name: "VerifSDKResourceCarrier",
            resources: [.copy("VerifSDKResources.bundle")]
        ),
    ]
)
