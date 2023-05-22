// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Swiftchain",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "Swiftchain",
      targets: ["Swiftchain"]),
    .library(
      name: "SwiftchainOpenAI",
      targets: ["SwiftchainOpenAI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "Swiftchain",
      dependencies: [
        .product(name: "Logging", package: "swift-log"),
        "Rainbow",
      ]
    ),
    .target(
      name: "SwiftchainOpenAI",
      dependencies: [
        "Swiftchain",
      ]
    ),
    .testTarget(
      name: "swiftchainTests",
      dependencies: ["Swiftchain"]
    ),
  ]
)
