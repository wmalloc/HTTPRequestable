// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "URLRequestable",
  defaultLocalization: "en",
  platforms: [.iOS(.v15), .tvOS(.v15), .macOS(.v11), .watchOS(.v8), .macCatalyst(.v15)],
  products: [
    .library(name: "URLRequestable", targets: ["URLRequestable"]),
    .library(name: "MultipartForm", targets: ["MultipartForm"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.3"),
  ],
  targets: [
    .target(name: "URLRequestable", dependencies: [
      .product(name: "HTTPTypes", package: "swift-http-types"),
      .product(name: "HTTPTypesFoundation", package: "swift-http-types")]),
    .target(name: "MultipartForm", dependencies: ["URLRequestable",
                                                  .product(name: "HTTPTypes", package: "swift-http-types"),
                                                  .product(name: "HTTPTypesFoundation", package: "swift-http-types")]),
    .testTarget(name: "URLRequestableTests",
                dependencies: ["URLRequestable", "MultipartForm",
                               .product(name: "HTTPTypes", package: "swift-http-types"),
                               .product(name: "HTTPTypesFoundation", package: "swift-http-types")]),
  ]
)
