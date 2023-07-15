// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "URLRequestable",
    defaultLocalization: "en",
    platforms: [.iOS(.v13), .tvOS(.v13), .macOS(.v10_15), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "URLRequestable", targets: ["URLRequestable"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "0.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "URLRequestable", dependencies: [
            .product(name: "HTTPTypes", package: "swift-http-types"),
            .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
            .product(name: "OrderedCollections", package: "swift-collections")]),
        .testTarget(name: "URLRequestableTests",
                    dependencies: [
                        "URLRequestable",
                        .product(name: "HTTPTypes", package: "swift-http-types"),
                        .product(name: "HTTPTypesFoundation", package: "swift-http-types")]),
    ]
)
