// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CmdTab",
  dependencies: [
    .package(url: "https://github.com/krisk/fuse-swift.git", from: "1.4.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "CmdTab",
      dependencies: [
        .product(name: "Fuse", package: "fuse-swift")
      ])
  ],
)
