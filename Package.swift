// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CombineExtensions",
    products: [
        .library(
            name: "CombineExtensions",
            targets: ["CombineExtensions"]
        )
    ],
    targets: [
        .target(name: "CombineExtensions"),
        .testTarget(
            name: "CombineExtensionsTests",
            dependencies: ["CombineExtensions"]
        )
    ]
)
