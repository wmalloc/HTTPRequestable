//
//  HackerNews.swift
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import OSLog

@globalActor actor HackerNewsActor: GlobalActor {
  static let shared = HackerNewsActor()

  private init() {}
}

@HackerNewsActor
final class HackerNews: HTTPTransferable {
  static let shared = HackerNews()
  private(set) var requestModifiers: [any HTTPRequestModifier] = []
  private(set) var interceptors: [any HTTPInterceptor] = []

  private(set) var environment: HTTPEnvironment = .init(authority: "hacker-news.firebaseio.com", path: "/v0")
  let session: URLSession

  nonisolated init() {
    self.session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
    var fields = HTTPFields.defaultHeaders
    fields.append(HTTPField(name: .accept, contentType: .json))
    fields.append(HTTPField(name: .contentType, contentType: .json))
    requestModifiers.append(DefaultHeadersModifier(headerFields: fields))
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
    let request = try StoryListRequest(environment, storyType: type)
    return try await object(for: request)
  }

  func item(id: Int) async throws -> Item {
    try await object(for: ItemRequest(environment, item: id))
  }
}
