// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CopyClip",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CopyClip",
            targets: ["CopyClip"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CopyClip",
            dependencies: [],
            path: "Sources"
        ),
    ]
)

