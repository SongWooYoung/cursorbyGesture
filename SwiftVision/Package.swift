// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "visualAgent",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "visualAgent", targets: ["visualAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", exact: "6.2.4"),
    ],
    targets: [
        .target(
            name: "Support"
        ),
        .target(
            name: "Config",
            dependencies: ["Support"]
        ),
        .target(
            name: "Capture",
            dependencies: ["Support", "Config"]
        ),
        .target(
            name: "VisionPipeline",
            dependencies: ["Support"]
        ),
        .target(
            name: "Gesture",
            dependencies: ["Support", "Config", "VisionPipeline"]
        ),
        .target(
            name: "Control",
            dependencies: ["Support", "Config", "Gesture"]
        ),
        .target(
            name: "AppCore",
            dependencies: [
                "Support",
                "Config",
                "Capture",
                "VisionPipeline",
                "Gesture",
                "Control",
            ]
        ),
        .executableTarget(
            name: "visualAgent",
            dependencies: ["AppCore"]
        ),
        .testTarget(
            name: "GestureTests",
            dependencies: [
                "Gesture",
                "VisionPipeline",
                "Config",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
