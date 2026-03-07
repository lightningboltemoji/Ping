// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Ping",
  platforms: [
    .macOS(.v26)
  ],
  dependencies: [
    .package(
      url: "https://github.com/jpsim/Yams.git",
      from: "5.0.0"
    )
  ],
  targets: [
    .executableTarget(
      name: "Ping",
      dependencies: [
        .product(name: "Yams", package: "Yams")
      ],
      resources: [
        .process("Resources/Chango-Regular.ttf"),
        .copy("Resources/Bell.svg"),
      ])
  ]
)
