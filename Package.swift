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
            linkerSettings: [
                // Embed Info.plist directly into the executable so the
                // bundle identifier, usage descriptions (EventKit), and
                // LSUIElement are present even when run as a bare binary.
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "ChimeTimeTests",
            dependencies: ["ChimeTime"],
            path: "Tests/ChimeTimeTests"
        )
    ]
)
