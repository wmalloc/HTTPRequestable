//
//  HackerNewsAPITests.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

import XCTest

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
final class HackerNewsAPITests: XCTestCase {
  private var api: HackerNewsAPI!

  override func setUpWithError() throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    api = HackerNewsAPI(session: session)
  }

  override func tearDownWithError() throws {
    api = nil
  }

  func testTopStories() async throws {
    let request = try StoryList(storyType: "topstories.json")
    let url = try request.url()
    MockURLProtocol.requestHandlers[url] = { _ in
      let data = try Bundle.module.data(forResource: "topstories", withExtension: "json")
      return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!, data)
    }

    let topStories = try await api.storyList(type: "topstories.json")
    XCTAssertEqual(topStories.count, 466)
  }

  func testNewStories() async throws {
    let request = try StoryList(storyType: "newstories.json")
    let url = try request.url()
    MockURLProtocol.requestHandlers[url] = { _ in
      let data = try Bundle.module.data(forResource: "newstories", withExtension: "json")
      return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!, data)
    }
    let newStories = try await api.storyList(type: "newstories.json")
    XCTAssertEqual(newStories.count, 500)
  }

  func testBestStories() async throws {
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
