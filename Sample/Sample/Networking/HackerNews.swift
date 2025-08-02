//
//  HackerNews.swift
//  Sample
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import OSLog

actor HackerNews: HTTPTransferable {
  var requestModifiers: [any HTTPRequestModifier] = []
  var responseInterceptors: [any HTTPResponseInterceptor] = []

  private(set) var environment: HTTPEnvironment = .init(scheme: "https", authority: "hacker-news.firebaseio.com", path: "/v0")

  let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
    environment.queryItems = [URLQueryItem(name: "print", value: "pretty")]
  }
}

extension HackerNews {
  func topStories(limit: Int = 20) async throws -> [Item] {
    let stories = try await stories(type: "topstories")
    var items: [Item] = []
    precondition(limit > 0 && limit <= stories.count, "Limit must be greater than zero")
    for index in 0 ..< limit {
      let story = stories[index]
      do {
        let item = try await item(id: story)
        items.append(item)
      } catch {
        os_log(.error, log: .default, "Failed to fetch item with id: \(story): \(error)")
      }
    }
    return items
  }

  func stories(type: String) async throws -> [Int] {
    try await object(for: StoryListRequest(environment: environment, storyType: type))
  }

  func item(id: Int) async throws -> Item {
    try await object(for: ItemRequest(environment: environment, item: id))
  }
}
