//
//  HackerNewsAPITests.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

@testable import HTTPRequestable
import MockURLProtocol
import XCTest

final class HackerNewsAPITests: XCTestCase, @unchecked Sendable {
  private var api: HackerNews!

  override func setUpWithError() throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    api = HackerNews(session: session)
    Task { [weak self] in
      guard let self else { return }
      let logger = LoggerInterceptor()
      await self.api.requestInterceptors.append(logger)
      await self.api.responseInterceptors.append(logger)
    }
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
    let request = try StoryListRequest(environment: api.environment, storyType: "topstories").addTestIdentifierHeader()
    let url = try request.url
    await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.data(forResource: "topstories", withExtension: "json")
      return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!, data)
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
    let request = try StoryListRequest(environment: api.environment, storyType: "newstories").addTestIdentifierHeader()
    let url = try request.url
    await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.data(forResource: "newstories", withExtension: "json")
      return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!, data)
    }, forRequest: request)
    let newStories = try await api.storyList(type: "newstories")
    XCTAssertEqual(newStories.count, 500)
  }

  func testBesttories() async throws {
    let hackerNews = HackerNews()
    let topStories = try await hackerNews.storyList(type: "beststories")
    XCTAssertFalse(topStories.isEmpty)
  }

  func testMockBestStories() async throws {
    let request = try StoryListRequest(environment: api.environment, storyType: "beststories").addTestIdentifierHeader()
    let url = try request.url
    await MockURLProtocol.setRequestHandler({ _ in
      let data = try Bundle.module.data(forResource: "beststories", withExtension: "json")
      return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!, data)
    }, forRequest: request)
    let bestStories = try await api.storyList(type: "beststories")
    XCTAssertEqual(bestStories.count, 200)
  }
}
