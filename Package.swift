// swift-tools-version: 6.3

import CompilerPluginSupport
import Foundation
import PackageDescription

/// Whether the package is being cross-compiled for Android. The Android CI action
/// (skiptools/swift-android-action) sets `TARGET_OS_ANDROID` while it builds.
let isBuildingForAndroid = ProcessInfo.processInfo.environment["TARGET_OS_ANDROID"] != nil

let package = Package(
  name: "HTTPRequestable",
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
                                                    .product(name: "HTTPTypesFoundation", package: "swift-http-types")]),
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

// The macro tests link the macro implementation, which runs on the build machine, so they cannot be
// cross-compiled for Android. They test compile-time behaviour, which the macOS and Linux builds cover.
if !isBuildingForAndroid {
  package.targets.append(
    .testTarget(name: "HTTPRequestableMacrosTests", dependencies: ["HTTPRequestableMacros",
                                                                   .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")])
  )
}
