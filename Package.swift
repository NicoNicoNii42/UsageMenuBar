// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "UsageMenuBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "UsageMenuBarCore", targets: ["UsageMenuBarCore"]),
        .executable(name: "UsageMenuBar", targets: ["UsageMenuBar"])
    ],
    targets: [
        .target(name: "UsageMenuBarCore"),
        .executableTarget(
            name: "UsageMenuBar",
            dependencies: ["UsageMenuBarCore"]
        ),
        .testTarget(
            name: "UsageMenuBarCoreTests",
            dependencies: ["UsageMenuBarCore"]
        )
    ]
)
