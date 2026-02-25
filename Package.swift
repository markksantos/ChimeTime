// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ChimeTime",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ChimeTime",
            path: "Sources/ChimeTime",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ChimeTimeTests",
            dependencies: ["ChimeTime"],
            path: "Tests/ChimeTimeTests"
        )
    ]
)
