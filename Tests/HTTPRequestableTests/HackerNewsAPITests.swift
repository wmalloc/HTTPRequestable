//
//  HackerNewsAPITests.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

@testable import HTTPRequestable
import MockURLProtocol
import XCTest

final class HackerNewsAPITests: XCTestCase {
  private var api: HackerNews!

  override func setUpWithError() throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    api = HackerNews(session: session)
    let logger = LoggerInterceptor()
    api.requestInterceptors.append(logger)
    api.responseInterceptors.append(logger)
    let statusValidator = ResponseStatusValidator()
    api.responseInterceptors.append(statusValidator)
    let contentTypeValiator = ContentTypeValidator(acceptableContentTypes: ["application/json"])
    api.responseInterceptors.append(contentTypeValiator)
  }

  override func tearDownWithError() throws {
    api = nil
  }

  func testTopStories() async throws {
    let hackerNews = HackerNews()
    let topStories = try await hackerNews.storyList(type: "topstories.json")
    XCTAssertFalse(topStories.isEmpty)
  }

  func testMockTopStories() async throws {
    let request = try StoryList(storyType: "topstories.json")
    let url = try request.url()
    MockURLProtocol.requestHandlers[url] = { _ in
      let data = try Bundle.module.data(forResource: "topstories", withExtension: "json")
      return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!, data)
    }

    let topStories = try await api.storyList(type: "topstories.json")
    XCTAssertEqual(topStories.count, 466)
  }

  func testNewtories() async throws {
    let hackerNews = HackerNews()
    let topStories = try await hackerNews.storyList(type: "newstories.json")
    XCTAssertFalse(topStories.isEmpty)
  }

  func testMockNewStories() async throws {
    let request = try StoryList(storyType: "newstories.json")
    let url = try request.url()
    MockURLProtocol.requestHandlers[url] = { _ in
      let data = try Bundle.module.data(forResource: "newstories", withExtension: "json")
      return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!, data)
    }
    let newStories = try await api.storyList(type: "newstories.json")
    XCTAssertEqual(newStories.count, 500)
  }

  func testBesttories() async throws {
    let hackerNews = HackerNews()
    let topStories = try await hackerNews.storyList(type: "beststories.json")
    XCTAssertFalse(topStories.isEmpty)
  }

  func testMockBestStories() async throws {
    let request = try StoryList(storyType: "beststories.json")
    let url = try request.url()
    MockURLProtocol.requestHandlers[url] = { _ in
      let data = try Bundle.module.data(forResource: "beststories", withExtension: "json")
      return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!, data)
    }
    let bestStories = try await api.storyList(type: "beststories.json")
    XCTAssertEqual(bestStories.count, 200)
  }
}
