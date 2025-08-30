//
//  HackerNewsAPITests.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

@testable import HTTPRequestable
import MockURLProtocol
import XCTest

extension HTTPURLResponse {
  static func ok(url: URL) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
  }
}

final class HackerNewsAPITests: XCTestCase, @unchecked Sendable {
  private var api: HackerNews!

  override func setUpWithError() throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    api = HackerNews(session: session)
  }

  override func tearDownWithError() throws {
    api = nil
  }

  func testTopStories() async throws {
    let hackerNews = HackerNews()
    let topStories = try await hackerNews.storyList(type: "topstories")
    XCTAssertFalse(topStories.isEmpty)
  }

  func testMockTopStories() async throws {
    let request = try StoryListRequest(environment: api.environment, storyType: "topstories")
      .addTestIdentifierHeader()
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.data(forResource: "topstories", withExtension: "json")
      return (data, HTTPURLResponse.ok(url: url))
    }, forRequest: request)

    let topStories = try await api.object(for: request)
    XCTAssertEqual(topStories.count, 466)
  }

  func testNewtories() async throws {
    let hackerNews = HackerNews()
    let topStories = try await hackerNews.storyList(type: "newstories")
    XCTAssertFalse(topStories.isEmpty)
  }

  func testMockNewStories() async throws {
    let request = try StoryListRequest(environment: api.environment, storyType: "newstories")
      .addTestIdentifierHeader()
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.data(forResource: "newstories", withExtension: "json")
      return (data, HTTPURLResponse.ok(url: url))
    }, forRequest: request)
    let newStories = try await api.object(for: request, delegate: nil)
    XCTAssertEqual(newStories.count, 500)
  }

  func testBesttories() async throws {
    let hackerNews = HackerNews()
    let topStories = try await hackerNews.storyList(type: "beststories")
    XCTAssertFalse(topStories.isEmpty)
  }

  func testMockBestStories() async throws {
    let request = try StoryListRequest(environment: api.environment, storyType: "beststories")
      .addTestIdentifierHeader()
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.data(forResource: "beststories", withExtension: "json")
      return (data, HTTPURLResponse.ok(url: url))
    }, forRequest: request)
    let bestStories = try await api.object(for: request, delegate: nil)
    XCTAssertEqual(bestStories.count, 200)
  }
}
