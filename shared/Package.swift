// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SpotifyLocalCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "SpotifyLocalCore", targets: ["SpotifyLocalCore"]),
        .executable(name: "SpotifyLocalCoreChecks", targets: ["SpotifyLocalCoreChecks"]),
    ],
    targets: [
        .target(name: "SpotifyLocalCore"),
        .executableTarget(
            name: "SpotifyLocalCoreChecks",
            dependencies: ["SpotifyLocalCore"],
            path: "Tests/SpotifyLocalCoreChecks"
        ),
    ]
)
