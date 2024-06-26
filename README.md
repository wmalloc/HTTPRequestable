![](https://img.shields.io/github/v/tag/wmalloc/URLRequestable?label=Version)
[![Swift 5.7](https://img.shields.io/badge/swift-5.7-ED523F.svg?style=flat)](https://swift.org/download/)
[![SPM supported](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager)
![License](https://img.shields.io/github/license/wmalloc/URLRequestable.svg?style=flat)

# HTTPRequestable

A lightweight Web API for [Apple](https://www.apple.com) devices, written in [Swift](https://swift.org) 5.x and using [Structured Concurrency](https://developer.apple.com/documentation/swift/concurrency). It builds on top of [HTTPTypes](https://github.com/apple/swift-http-types) library by [Apple](https://www.apple.com).

## Getting Started

Add the following dependency clause to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/wmalloc/HTTpRequestable.git", from: "0.6.0")
]
```
## Features

| |Features |
--------------------------|------------------------------------------------------------
`HTTPRequstable` | Define your request
`URLRequestable` | Build your `URLRequest` to make a call
`URLTransferable` | To create your API client
`URLAsyncTransferable` | Concurrency version of the API.

## Usage

To defineing a request:

```swift
struct StoryList: HTTPRequstable {
  typealias ResultType = [Int]

  let authority: String = "hacker-news.firebaseio.com"
  let method: HTTPMethod = .get
  let path: String
  let headerFields: HTTPFields = .init([.accept(.json)])
  let queryItems: Array<URLQueryItem>? = [URLQueryItem(name: "print", value: "pretty")]

  init(storyType: String) throws {
    guard !storyType.isEmpty else {
      throw URLError(.badURL)
    }
    self.path = "/v0/" + storyType
  }
}

```
#### Creating an API

```swift
class HackerNewsAPI: HTTPTransferable {
  let session: URLSession

  required init(session: URLSession = .shared) {
    self.session = session
  }

  func storyList(type: String) async throws -> StoryList.ResultType {
    let request = try StoryList(storyType: type)
    return try await data(for: request, delegate: nil)
  }
}
```

Then you can create an instantiate your API object to make calls

```swift
var api = HackerNewsAPI()
let topStories = try await api.storyList(type: "topstories.json")
```
