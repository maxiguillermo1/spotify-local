// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SpotifyLocalCompanion",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(path: "../../shared"),
    ],
    targets: [
        .executableTarget(
            name: "SpotifyLocalCompanion",
            dependencies: [
                .product(name: "SpotifyLocalCore", package: "shared"),
            ]
        ),
    ]
)
