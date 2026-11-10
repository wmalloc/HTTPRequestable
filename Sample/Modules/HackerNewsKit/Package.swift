// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
  name: "HackerNewsKit",
  platforms: [.iOS(.v18), .tvOS(.v18), .macOS(.v15), .watchOS(.v11), .macCatalyst(.v18), .visionOS(.v2)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "HackerNewsKit", targets: ["HackerNewsKit"])
  ],
  dependencies: [
    .package(path: "../../..")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(name: "HackerNewsKit", dependencies: [
      .product(name: "HTTPRequestable", package: "HTTPRequestable")
    ],
    swiftSettings: [.enableUpcomingFeature("ApproachableConcurrency")]),
    .testTarget(name: "HackerNewsKitTests", dependencies: ["HackerNewsKit",
                                                           .product(name: "MockURLProtocol", package: "HTTPRequestable")],
                swiftSettings: [.enableUpcomingFeature("ApproachableConcurrency")])
  ]
)
