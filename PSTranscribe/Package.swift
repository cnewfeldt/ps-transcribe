// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PSTranscribe",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", revision: "ea500621819cadc46d6212af44624f2b45ab3240"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "PSTranscribe",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/PSTranscribe",
            exclude: ["Info.plist", "PSTranscribe.entitlements", "Assets"]
        ),
        .testTarget(
            name: "PSTranscribeTests",
            dependencies: ["PSTranscribe"],
            path: "Tests/PSTranscribeTests"
        ),
    ]
)
