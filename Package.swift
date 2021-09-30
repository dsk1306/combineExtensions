// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CombineExtensions",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "CombineExtensions",
            targets: ["CombineExtensions"]
        )
    ],
    targets: [
        .target(
            name: "CombineExtensions",
            path: "Sources"
        ),
        .testTarget(
            name: "CombineExtensionsTests",
            dependencies: ["CombineExtensions"],
            path: "Tests"
        )
    ]
)
