import Foundation
@testable import HTTPRequestable
import MockURLProtocol
import Testing

extension HTTPURLResponse {
  static func ok(url: URL) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
  }
}

@Suite("HackerNews API Tests")
struct HackerNewsAPITests {
  private var api: HackerNews = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    return HackerNews(session: session)
  }()

  @Test("Top Stories from Live API")
  func testTopStories() async throws {
    let topStories = try await HackerNews.shared.storyList(type: "topstories")
    #expect(!topStories.isEmpty)
  }

  @Test("Mocked Top Stories")
  func mockTopStories() async throws {
    let request = try StoryListRequest(environment: api.environment, storyType: "topstories").addTestIdentifierHeader()
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.data(forResource: "topstories", withExtension: "json")
      return (data, HTTPURLResponse.ok(url: url))
    }, forRequest: request)
    let topStories = try await api.object(for: request)
    #expect(topStories.count == 466)
  }

  @Test("New Stories from Live API")
  func testNewStories() async throws {
    let topStories = try await HackerNews.shared.storyList(type: "newstories")
    #expect(!topStories.isEmpty)
  }

  @Test("Mocked New Stories")
  func mockNewStories() async throws {
    let request = try StoryListRequest(environment: api.environment, storyType: "newstories").addTestIdentifierHeader()
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.data(forResource: "newstories", withExtension: "json")
      return (data, HTTPURLResponse.ok(url: url))
    }, forRequest: request)
    let newStories = try await api.object(for: request, delegate: nil)
    #expect(newStories.count == 500)
  }

  @Test("Best Stories from Live API")
  func testBestStories() async throws {
    let topStories = try await HackerNews.shared.storyList(type: "beststories")
    #expect(!topStories.isEmpty)
  }

  @Test("Mocked Best Stories")
  func mockBestStories() async throws {
    let request = try StoryListRequest(environment: api.environment, storyType: "beststories").addTestIdentifierHeader()
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.data(forResource: "beststories", withExtension: "json")
      return (data, HTTPURLResponse.ok(url: url))
    }, forRequest: request)
    let bestStories = try await api.object(for: request, delegate: nil)
    #expect(bestStories.count == 200)
  }
}
