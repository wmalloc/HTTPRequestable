//
//  HackerNewsTests.swift
//
//  Created by Waqar Malik on 8/27/26.
//

import Foundation
@testable import HackerNewsKit
import HTTPRequestable
import HTTPTypes
import MockURLProtocol
import Testing

extension HTTPURLResponse {
  static func ok(url: URL) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
  }
}

/// Serialized because `MockURLProtocol` keeps one process wide handler registry keyed by URL, so
/// tests stubbing the same endpoint would otherwise overwrite each other's responses.
@Suite("HackerNews", .serialized)
struct HackerNewsTests {
  let environment = HTTPEnvironment(authority: "hacker-news.firebaseio.com", path: "/v0")

  /// A client whose session serves `MockURLProtocol` instead of the network.
  private func makeAPI() -> HackerNews {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return HackerNews(session: URLSession(configuration: configuration))
  }

  /// Stubs a single response. `MockURLProtocol` keys handlers by the request's absolute URL when no
  /// `X-Test-Identifier` header is present, so each URL can be stubbed exactly once.
  @discardableResult
  private func stub(_ url: URL, with body: Data, status: Int = 200) async throws -> URL {
    try await MockURLProtocol.setRequestHandler({ _ in
      let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1",
                                     headerFields: ["Content-Type": "application/json"])!
      return (body, response)
    }, forIdentifier: url)
    return url
  }

  private func storyListURL(_ type: String) throws -> URL {
    try StoryListRequest(environment, storyType: type).url
  }

  private func itemURL(_ id: Int) throws -> URL {
    try ItemRequest(environment, item: id).url
  }

  private func itemJSON(id: Int, title: String) -> Data {
    Data("""
    {"by": "author\(id)", "descendants": 0, "id": \(id), "kids": [], "score": \(id),
     "time": 1175714200, "title": "\(title)", "type": "story", "url": "https://example.com/\(id)"}
    """.utf8)
  }

  // MARK: Configuration

  @Test("Points at the v0 Hacker News API")
  func defaultEnvironment() async {
    let api = makeAPI()
    let environment = await api.environment
    #expect(environment.scheme == "https")
    #expect(environment.host == "hacker-news.firebaseio.com")
    #expect(environment.path == "/v0")
  }

  @Test("Installs the default, JSON and trace request modifiers")
  func requestModifiers() async {
    let api = makeAPI()
    let modifiers = await api.requestModifiers
    #expect(modifiers.count == 3)
    #expect(modifiers.contains { $0 is TraceRequestModifier })
  }

  @Test("Retries transient failures")
  func retryPolicy() async throws {
    let api = makeAPI()
    let policy = try #require(await api.retryPolicy)
    #expect(policy.maxRetries > 0)
    #expect(policy.shouldRetry(error: URLError(.timedOut), attempt: 0))
    #expect(!policy.shouldRetry(error: URLError(.timedOut), attempt: policy.maxRetries))
  }

  @Test("Starts with no interceptors")
  func interceptors() async {
    let api = makeAPI()
    #expect(await api.interceptors.isEmpty)
  }

  @Test("The shared client is a single instance")
  func sharedIsStable() async {
    #expect(await HackerNews.shared === HackerNews.shared)
  }

  // MARK: Story lists

  @Test("Decodes a story list")
  func stories() async throws {
    let api = makeAPI()
    try await stub(storyListURL("topstories"), with: Data("[9129911, 9129199, 9127761]".utf8))

    let ids = try await api.stories(type: "topstories")
    #expect(ids == [9129911, 9129199, 9127761])
  }

  @Test("Decodes an empty story list")
  func emptyStories() async throws {
    let api = makeAPI()
    try await stub(storyListURL("jobstories"), with: Data("[]".utf8))

    #expect(try await api.stories(type: "jobstories").isEmpty)
  }

  @Test("Requests the endpoint for each story type", arguments: StoryType.allCases)
  func storiesForEveryType(type: StoryType) async throws {
    let api = makeAPI()
    let url = try storyListURL(type.rawValue)
    try await stub(url, with: Data("[1]".utf8))

    #expect(try await api.stories(type: type.rawValue) == [1])
    #expect(url.path == "/v0/\(type.rawValue).json")
    #expect(url.query == "print=pretty")
  }

  @Test("Applies the request modifiers to the outgoing request")
  func appliesRequestModifiers() async throws {
    let api = makeAPI()
    let url = try storyListURL("topstories")
    let sent = SentRequest()
    try await MockURLProtocol.setRequestHandler({ request in
      await sent.record(request)
      return (Data("[1]".utf8), HTTPURLResponse.ok(url: url))
    }, forIdentifier: url)

    _ = try await api.stories(type: "topstories")

    let request = try #require(await sent.request)
    #expect(request.httpMethod == "GET")
    #expect(request.value(forHTTPHeaderField: "Accept")?.contains("application/json") == true)
    let traceID = try #require(request.value(forHTTPHeaderField: "X-Trace-Id"))
    #expect(UUID(uuidString: traceID) != nil)
  }

  @Test("Surfaces a malformed story list as a decoding error")
  func malformedStoryList() async throws {
    let api = makeAPI()
    try await stub(storyListURL("topstories"), with: Data(#"{"unexpected": true}"#.utf8))

    await #expect(throws: DecodingError.self) {
      try await api.stories(type: "topstories")
    }
  }

  // MARK: Items

  @Test("Decodes a single item")
  func item() async throws {
    let api = makeAPI()
    try await stub(itemURL(8863), with: itemJSON(id: 8863, title: "Dropbox"))

    let item = try await api.item(id: 8863)
    #expect(item.id == 8863)
    #expect(item.title == "Dropbox")
    #expect(item.by == "author8863")
  }

  @Test("Surfaces the null body of an unknown item as a decoding error")
  func unknownItem() async throws {
    let api = makeAPI()
    try await stub(itemURL(1), with: Data("null".utf8))

    await #expect(throws: DecodingError.self) {
      try await api.item(id: 1)
    }
  }

  // MARK: Top stories

  @Test("Returns top stories in the order of the identifier list")
  func topStories() async throws {
    let api = makeAPI()
    let ids = [3, 1, 2]
    try await stub(storyListURL("topstories"), with: Data("\(ids)".utf8))
    for id in ids {
      try await stub(itemURL(id), with: itemJSON(id: id, title: "Story \(id)"))
    }

    let items = try await api.topStories(limit: ids.count)
    #expect(items.map(\.id) == ids)
    #expect(items.map(\.title) == ["Story 3", "Story 1", "Story 2"])
  }

  @Test("Fetches no more stories than the requested limit")
  func topStoriesHonoursLimit() async throws {
    let api = makeAPI()
    let ids = [1, 2, 3, 4]
    try await stub(storyListURL("topstories"), with: Data("\(ids)".utf8))
    for id in ids {
      try await stub(itemURL(id), with: itemJSON(id: id, title: "Story \(id)"))
    }

    let items = try await api.topStories(limit: 2)
    #expect(items.map(\.id) == [1, 2])
  }

  @Test("Returns the whole feed when it is shorter than the limit")
  func topStoriesShorterThanLimit() async throws {
    let api = makeAPI()
    let ids = [1, 2]
    try await stub(storyListURL("topstories"), with: Data("\(ids)".utf8))
    for id in ids {
      try await stub(itemURL(id), with: itemJSON(id: id, title: "Story \(id)"))
    }

    let items = try await api.topStories(limit: 50)
    #expect(items.map(\.id) == ids)
  }

  @Test("Returns nothing when the feed is empty")
  func topStoriesEmptyFeed() async throws {
    let api = makeAPI()
    try await stub(storyListURL("topstories"), with: Data("[]".utf8))

    #expect(try await api.topStories().isEmpty)
  }

  @Test("Fails the whole batch when one item cannot be decoded")
  func topStoriesPropagatesItemFailure() async throws {
    let api = makeAPI()
    let ids = [1, 2]
    try await stub(storyListURL("topstories"), with: Data("\(ids)".utf8))
    try await stub(itemURL(1), with: itemJSON(id: 1, title: "Story 1"))
    try await stub(itemURL(2), with: Data("null".utf8))

    await #expect(throws: DecodingError.self) {
      try await api.topStories(limit: ids.count)
    }
  }
}

/// Captures the request that reached the mocked protocol.
private actor SentRequest {
  private(set) var request: URLRequest?

  func record(_ request: URLRequest) {
    self.request = request
  }
}
