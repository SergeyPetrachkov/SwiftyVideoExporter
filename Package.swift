// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let name = "SwiftyVideoExporter"
let package = Package(
  name: name,
  platforms: [.iOS(.v11)],
  products: [
    .library(
      name: name,
      targets: [name]
    ),
  ],
  dependencies: [
    .package(
      name: "SPMAssetExporter",
      url: "https://github.com/SergeyPetrachkov/SPMAssetExporter",
      .revision("85b5946924093ddd88dffa52f6f29b76636736b1")
    ),
    .package(
      name: "AVFoundationExtensions",
      url: "https://github.com/SergeyPetrachkov/AVFoundationExtensions",
      .revision("98f4ad7667f7dd8a37770fc63073e93ae2847908")
    )
  ],
  targets: [
    .target(
      name: name,
      dependencies: ["SPMAssetExporter", "AVFoundationExtensions"]
    ),
  ]
)
