// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SpaceLens",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SpaceLens", targets: ["SpaceLens"])
    ],
    targets: [
        .executableTarget(
            name: "SpaceLens",
            path: "SpaceLens/SpaceLens",
            exclude: ["Assets.xcassets"]
        ),
        .testTarget(
            name: "SpaceLensTests",
            dependencies: ["SpaceLens"],
            path: "SpaceLens/SpaceLensTests"
        )
    ]
)
