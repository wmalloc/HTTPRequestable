//
//  HackerNewsAPITests.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

import XCTest

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
final class HackerNewsAPITests: XCTestCase {
  var api = HackerNewsAPI()

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testTopStories() async throws {
    let topStories = try await api.storyList(type: "topstories.json")
    XCTAssertEqual(topStories.count, 500)
  }

  func testNewStories() async throws {
    let newStories = try await api.storyList(type: "newstories.json")
    XCTAssertEqual(newStories.count, 500)
  }

  func testBestStories() async throws {
    let bestStories = try await api.storyList(type: "beststories.json")
    XCTAssertEqual(bestStories.count, 200)
  }
}
