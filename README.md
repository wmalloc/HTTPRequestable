![](https://img.shields.io/github/v/tag/wmalloc/URLRequestable?label=Version)
[![Swift 5.9](https://img.shields.io/badge/swift-5.9-ED523F.svg?style=flat)](https://swift.org/download/)
[![SPM supported](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager)
![License](https://img.shields.io/github/license/wmalloc/URLRequestable.svg?style=flat)

# HTTPRequestable

A lightweight WebService API for [Apple](https://www.apple.com) devices, written in [Swift](https://swift.org) 5.x and using [Structured Concurrency](https://developer.apple.com/documentation/swift/concurrency). It builds on top of [HTTPTypes](https://github.com/apple/swift-http-types) library by [Apple](https://www.apple.com).

## Getting Started

Add the following dependency clause to your Package.swift:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "MyApp",
  platforms: [.iOS(.v16), .tvOS(.v16), .macOS(.v12), .watchOS(.v9), .macCatalyst(.v16), .visionOS(.v1)],
  products: [
    .executable(name: "MyApp", targets: ["MyApp"])
  ],
  dependencies: [
    .package(url: "https://github.com/wmalloc/HTTPRequestable.git", from: "0.7.11")
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
|`URLTransferable` | To create your API client|

## Usage

### Creating an API

```swift
class HackerNews: HTTPTransferable {
  let session: URLSession

  var requestInterceptors: [any RequestInterceptor] = []
  var responseInterceptors: [any ResponseInterceptor] = []

  required init(session: URLSession = .shared) {
    self.session = session
  }

  func storyList(type: String) async throws -> StoryList.ResultType {
    let request = try StoryList(storyType: type)
    return try await object(for: request, delegate: nil)
  }
}
```

### To defineing a request

```swift
struct StoryList: HTTPRequestable {
  typealias ResultType = [Int]

  let environment: HTTPEnvironment = .init(scheme: "https", authority: "hacker-news.firebaseio.com")
  let headerFields: HTTPFields? = .init([.accept(.json)])
  let queryItems: [URLQueryItem]? = [URLQueryItem(name: "print", value: "pretty")]
  let path: String?

  var responseTransformer: Transformer<Data, ResultType> {
    { data, _ in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }

  init(storyType: String) throws {
    guard !storyType.isEmpty else {
      throw URLError(.badURL)
    }
    path = "/v0/" + storyType
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