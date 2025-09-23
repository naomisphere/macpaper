// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macpaper",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "macpaper", targets: ["macpaper"])
    ],
    targets: [
        .executableTarget(
            name: "macpaper",
            path: "app/main",
            resources: []
        )
    ]
)
