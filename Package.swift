// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "HTTPRequestable",
  defaultLocalization: "en",
  platforms: [.iOS(.v18), .tvOS(.v18), .macOS(.v15), .watchOS(.v11), .macCatalyst(.v18), .visionOS(.v2)],
  products: [
    .library(name: "HTTPRequestable", targets: ["HTTPRequestable"]),
    .library(name: "MockURLProtocol", targets: ["MockURLProtocol"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.8.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "604.0.0")
  ],
  targets: [
    .macro(name: "HTTPRequestableMacros", dependencies: [.product(name: "SwiftSyntax", package: "swift-syntax"),
                                                         .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                                                         .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                                                         .product(name: "HTTPTypes", package: "swift-http-types"),
                                                         .product(name: "HTTPTypesFoundation", package: "swift-http-types")]),
    .target(name: "HTTPRequestable", dependencies: ["HTTPRequestableMacros",
                                                    .product(name: "HTTPTypes", package: "swift-http-types"),
                                                    .product(name: "HTTPTypesFoundation", package: "swift-http-types")],
            resources: [.process("Resources")]),
    .target(name: "MockURLProtocol", dependencies: ["HTTPRequestable",
                                                    .product(name: "HTTPTypes", package: "swift-http-types"),
                                                    .product(name: "HTTPTypesFoundation", package: "swift-http-types")]),
    .testTarget(name: "HTTPRequestableTests",
                dependencies: ["HTTPRequestable", "MockURLProtocol",
                               .product(name: "HTTPTypes", package: "swift-http-types"),
                               .product(name: "HTTPTypesFoundation", package: "swift-http-types")],
                resources: [.copy("MockData")]),
    .testTarget(name: "HTTPRequestableMacrosTests", dependencies: ["HTTPRequestableMacros",
                                                                   .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")])
  ]
)
