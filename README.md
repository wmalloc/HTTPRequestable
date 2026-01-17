![](https://img.shields.io/github/v/tag/wmalloc/URLRequestable?label=Version)
[![Swift](https://img.shields.io/badge/Swift-5.7%20%7C%205.8%20%7C%205.9%20%7C%206.0-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.7_5.8_5.9_6.0-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS_vision_OS-Green?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)

# HTTPRequestable

A lightweight WebService API for [Apple](https://www.apple.com) devices, written in [Swift](https://swift.org) 5.x and using [Structured Concurrency](https://developer.apple.com/documentation/swift/concurrency). It builds on top of [HTTPTypes](https://github.com/apple/swift-http-types) library by [Apple](https://www.apple.com).

## Getting Started

Add the following dependency clause to your Package.swift:

```swift
// swift-tools-version:5.11
import PackageDescription

let package = Package(
  name: "MyPackage",
  platforms: [.iOS(.v16), .tvOS(.v16), .macOS(.v12), .watchOS(.v9), .macCatalyst(.v16), .visionOS(.v1)],
  products: [
    .executable(name: "MyApp", targets: ["MyApp"])
  ],
  dependencies: [
    .package(url: "https://github.com/wmalloc/HTTPRequestable.git", from: "0.21.0")
  ],
  targets: [
    .target(name: "MyApp", dependencies: 
      [.product(name: "HTTPRequestable", package: "HTTPRequestable")])
  ]
)
```

## Features

| Protocol |Features |
|--------------------------|------------------------------------------|
|`HTTPRequestConfigurable` | Define your request|
|`HTTPTransferable` | To create your API client|
|`HTTPRequestConvertible` | To create your HTTPRequest|
|`URLRequestConvertible` | To create your URLRequest|
|`URLConvertible` | To create your URL|

## Usage

### Creating an API Manager

```swift
final class HackerNews: HTTPTransferable, @unchecked Sendable {
  var requestModifiers: [any HTTPRequestModifier] = []
  var interceptors: [any HTTPInterceptor] = []

  let session: URLSession

  required init(session: URLSession = .shared) {
    self.session = session
    let logger = LoggerInterceptor()
    requestModifiers.append(logger)
    interceptors.append(logger)
  }

 func storyList(type: String) async throws -> StoryList.ResultType {
    let request = try StoryListRequest(environment, storyType: type)
    return try await object(for: request, delegate: nil).value ?? []
  }
}
```

### To defineing a request

```swift
struct StoryListRequest: HTTPRequestConfigurable {
  typealias ResultType = [Int]
  
  let environment: HTTPEnvironment
  let headerFields: HTTPFields? = .init([.accept(.json)])
  let queryItems: [URLQueryItem]? = [URLQueryItem(name: "print", value: "pretty")]
  let path: String?
  
  var responseDataTransformer: Transformer<Data, ResultType>? {
    Self.jsonDecoder
  }
  
  init(_ environment: HTTPEnvironment, storyType: String) throws {
    precondition(!storyType.isEmpty, "Story type cannot be empty")
    self.environment = environment
    self.path = "/\(storyType).json"
  }
}
```

Then you can create an instantiate your API object to make calls

```swift
var api = HackerNews()
let topStories = try await api.storyList(type: "topstories.json")
```

### URLSession
If you intend to make direct calls to URLSession, there are APIs defined to accept configuration and facilitate the execution of API calls.

### HTTPRequestModifier
If you wish to modify the requests before they are sent to the server, you can create an object that conforms to the `HTTPRequestModifier` interface and add it to the `requestModifiers`.

For instance, you could create an authorization modifier that would add the `Authorization` header to the request.

### HTTPInterceptor
If you wish to intercept the requests before they are finished, you can create an object that conforms to the `HTTPInterceptor` interface and add it to the `interceptors`. They are called in the reverse order.

Logging interceptors are provided if you would like to log you responses.

## License

**HTTPRequestable** is released under the MIT license. See LICENSE for details.

## Support

If you would like to support this project, please consider donating.\
Bitcoin: [bc1qzxs3wk29vfxlr9e4frq9cdmgkvrp62m5xhm93l](./Images/bitcoin_qr_code.jpeg)\
Ethereum: [0xa824353280d2A0F32b2d258904509EFAEaE6603d](./Images/ethereum_qr_code.jpeg)
