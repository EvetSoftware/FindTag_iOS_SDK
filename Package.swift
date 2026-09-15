// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FindTagSDK",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "TagSdk", targets: ["TagSdk"]),
    ],
    targets: [
        .binaryTarget(
            name: "TagSdk",
            path: "libs/sdk-findtag-release.xcframework"
        ),
    ]
)
