// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SpotifyLocalApp",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(path: "../../shared"),
    ],
    targets: [
        .executableTarget(
            name: "SpotifyLocalApp",
            dependencies: [
                .product(name: "SpotifyLocalCore", package: "shared"),
            ]
        ),
    ]
)
