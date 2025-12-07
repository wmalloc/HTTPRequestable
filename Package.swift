// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "HTTPRequestable",
  defaultLocalization: "en",
  platforms: [.iOS(.v16), .tvOS(.v16), .macOS(.v12), .watchOS(.v9), .macCatalyst(.v16), .visionOS(.v1)],
  products: [
    .library(name: "HTTPRequestable", targets: ["HTTPRequestable"]),
    .library(name: "MockURLProtocol", targets: ["MockURLProtocol"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.5.1")
  ],
  targets: [
    .target(name: "HTTPRequestable", dependencies: [.product(name: "HTTPTypes", package: "swift-http-types"),
                                                    .product(name: "HTTPTypesFoundation", package: "swift-http-types")],
            resources: [.process("Resources")],
            swiftSettings: []),
    .target(name: "MockURLProtocol", dependencies: ["HTTPRequestable",
                                                    .product(name: "HTTPTypes", package: "swift-http-types"),
                                                    .product(name: "HTTPTypesFoundation", package: "swift-http-types")]),
    .testTarget(name: "HTTPRequestableTests",
                dependencies: ["HTTPRequestable", "MockURLProtocol",
                               .product(name: "HTTPTypes", package: "swift-http-types"),
                               .product(name: "HTTPTypesFoundation", package: "swift-http-types")],
                resources: [.copy("MockData")])
  ]
)
