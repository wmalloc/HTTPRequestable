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
// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "MyApp",
  platforms: [.iOS(.v16), .tvOS(.v16), .macOS(.v12), .watchOS(.v9), .macCatalyst(.v16), .visionOS(.v1)],
  products: [
    .executable(name: "MyApp", targets: ["MyApp"])
  ],
  dependencies: [
    .package(url: "https://github.com/wmalloc/HTTPRequestable.git", from: "0.10.1")
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
|`HTTPRequstable` | Define your request|
|`HTTPTransferable` | To create your API client|

## Usage

### Creating an API

```swift
class HackerNews: HTTPTransferable, @unchecked Sendable {
  var requestInterceptors: [any RequestInterceptor] = []
  var responseInterceptors: [any ResponseInterceptor] = []

  let session: URLSession

  required init(session: URLSession = .shared) {
    self.session = session
    let logger = LoggerInterceptor()
    requestInterceptors.append(logger)
    responseInterceptors.append(logger)
  }

 func storyList(type: String) async throws -> StoryList.ResultType {
    let request = try StoryListRequest(environment: environment, storyType: type)
    return try await object(for: request, delegate: nil).value ?? []
  }
}
```

### To defineing a request

```swift
struct StoryListRequest: HTTPRequestable {
  typealias ResultType = [Int]
  
  let environment: HTTPEnvironment
  let headerFields: HTTPFields? = .init([.accept(.json)])
  let queryItems: [URLQueryItem]? = [URLQueryItem(name: "print", value: "pretty")]
  let path: String?
  
  var responseDataTransformer: Transformer<Data, ResultType>? {
    Self.jsonDecoder
  }
  
  init(environment: HTTPEnvironment, storyType: String) throws {
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

## License

**HTTPRequestable** is released under the MIT license. See LICENSE for details.

## Support

If you would like to support this project, please consider donating.\
Bitcoin: [bc1qzxs3wk29vfxlr9e4frq9cdmgkvrp62m5xhm93l](./Images/bitcoin_qr_code.jpeg)\
Ethereum: [0xa824353280d2A0F32b2d258904509EFAEaE6603d](./Images/ethereum_qr_code.jpeg)
