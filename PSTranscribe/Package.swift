// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PSTranscribe",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", revision: "ea500621819cadc46d6212af44624f2b45ab3240"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.4.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.2"),
    ],
    targets: [
        .executableTarget(
            name: "PSTranscribe",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/PSTranscribe",
            exclude: ["Info.plist", "PSTranscribe.entitlements", "Assets"]
        ),
        .testTarget(
            name: "PSTranscribeTests",
            dependencies: [
                "PSTranscribe",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Tests/PSTranscribeTests"
        ),
    ]
)
