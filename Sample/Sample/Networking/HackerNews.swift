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
    requestModifiers.append(HTTPRequestHeadersModifier.defaultHeaderModifier)
    let modifier = HTTPRequestHeadersModifier(fields: [.accept(.json), .contentType(.json)])
    requestModifiers.append(modifier)
  }
}

extension HackerNews {
  func topStories(limit: Int = 20) async throws -> [Item] {
    let stories = try await stories(type: "topstories")
    precondition(limit > 0 && limit <= stories.count, "Limit must be greater than zero")
    let allResults = try await withThrowingTaskGroup(of: (Int, Item).self, returning: [Int: Item].self) { taskGroup in
      for storyId in stories {
        taskGroup.addTask {
          let item = try await self.item(id: storyId)
          return (storyId, item)
        }
      }
      var results: [Int: Item] = [:]
      for try await result in taskGroup {
        results[result.0] = result.1
      }
      return results
    }

    return stories.compactMap { allResults[$0] }
  }

  func stories(type: String) async throws -> [Int] {
    let request = try StoryListRequest(environment, storyType: type)
    return try await object(for: request)
  }

  func item(id: Int) async throws -> Item {
    try await object(for: ItemRequest(environment, item: id))
  }
}
