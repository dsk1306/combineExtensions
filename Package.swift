// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "CombineExtensions",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .macCatalyst(.v15),
    .tvOS(.v15),
    .watchOS(.v8)
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
