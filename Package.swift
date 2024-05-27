// swift-tools-version: 5.10

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("BareSlashRegexLiterals"),
  .enableUpcomingFeature("ConciseMagicFile"),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("ForwardTrailingClosures"),
  .enableUpcomingFeature("ImplicitOpenExistentials"),
  .enableUpcomingFeature("StrictConcurrency"),
  .unsafeFlags(["-warn-concurrency", "-enable-actor-data-race-checks"]),
]

let package = Package(
  name: "HTTPRequestable",
  defaultLocalization: "en",
  platforms: [.iOS(.v15), .tvOS(.v15), .macOS(.v11), .watchOS(.v8), .macCatalyst(.v15)],
  products: [
    .library(name: "HTTPRequestable", targets: ["HTTPRequestable"]),
    .library(name: "MultipartForm", targets: ["MultipartForm"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.1.0"),
  ],
  targets: [
    .target(name: "HTTPRequestable", dependencies: [
      .product(name: "HTTPTypes", package: "swift-http-types"),
      .product(name: "HTTPTypesFoundation", package: "swift-http-types")],
            resources: [.process("Resources")],
            swiftSettings: []),
    .target(name: "MultipartForm", dependencies: ["HTTPRequestable",
                                                  .product(name: "HTTPTypes", package: "swift-http-types"),
                                                  .product(name: "HTTPTypesFoundation", package: "swift-http-types")],
            resources: [.process("Resources")],
            swiftSettings: []),
    .testTarget(name: "HTTPRequestableTests",
                dependencies: ["HTTPRequestable", "MultipartForm",
                               .product(name: "HTTPTypes", package: "swift-http-types"),
                               .product(name: "HTTPTypesFoundation", package: "swift-http-types")],
                resources: [.copy("TestData")]),
  ]
)
