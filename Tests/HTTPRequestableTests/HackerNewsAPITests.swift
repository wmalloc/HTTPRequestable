import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import HTTPRequestable
import MockURLProtocol
import Testing

extension HTTPURLResponse {
  static func ok(url: URL) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
  }
}

extension Tag {
  /// Tests that call a real server over the network.
  @Tag static var live: Self
}

/// Whether tests that call the live Hacker News API run. They are off by default, so the suite passes
/// offline and does not depend on the API being up; set `HTTPREQUESTABLE_LIVE_TESTS=1` to run them.
let liveTestsEnabled = ProcessInfo.processInfo.environment["HTTPREQUESTABLE_LIVE_TESTS"] == "1"

struct HackerNewsAPITests {
  private var api: HackerNews = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    return HackerNews(session: session)
  }()

  @Test("Top Stories from Live API", .tags(.live),
        .enabled(if: liveTestsEnabled, "Set HTTPREQUESTABLE_LIVE_TESTS=1 to call the live Hacker News API"))
  func testTopStories() async throws {
    let topStories = try await HackerNews.shared.storyList(type: "topstories")
    #expect(!topStories.isEmpty)
  }

  @Test("Mocked Top Stories")
  func mockTopStories() async throws {
    let request = try StoryListRequest(api.environment, storyType: "topstories").byAddingMockIdentifierHeader()
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.mockData(forResource: "topstories", withExtension: "json")
      return (data, HTTPURLResponse.ok(url: url))
    }, forRequest: request)
    let topStories = try await api.object(for: request)
    #expect(topStories.count == 466)
  }

  @Test("New Stories from Live API", .tags(.live),
        .enabled(if: liveTestsEnabled, "Set HTTPREQUESTABLE_LIVE_TESTS=1 to call the live Hacker News API"))
  func testNewStories() async throws {
    let topStories = try await HackerNews.shared.storyList(type: "newstories")
    #expect(!topStories.isEmpty)
  }

  @Test("Mocked New Stories")
  func mockNewStories() async throws {
    let request = try StoryListRequest(api.environment, storyType: "newstories").byAddingMockIdentifierHeader()
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.mockData(forResource: "newstories", withExtension: "json")
      return (data, HTTPURLResponse.ok(url: url))
    }, forRequest: request)
    let newStories = try await api.object(for: request, delegate: nil)
    #expect(newStories.count == 500)
  }

  @Test("Best Stories from Live API", .tags(.live),
        .enabled(if: liveTestsEnabled, "Set HTTPREQUESTABLE_LIVE_TESTS=1 to call the live Hacker News API"))
  func testBestStories() async throws {
    let topStories = try await HackerNews.shared.storyList(type: "beststories")
    #expect(!topStories.isEmpty)
  }

  @Test("Mocked Best Stories")
  func mockBestStories() async throws {
    let request = try StoryListRequest(api.environment, storyType: "beststories").byAddingMockIdentifierHeader()
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.mockData(forResource: "beststories", withExtension: "json")
      return (data, HTTPURLResponse.ok(url: url))
    }, forRequest: request)
    let bestStories = try await api.object(for: request, delegate: nil)
    #expect(bestStories.count == 200)
  }
}
