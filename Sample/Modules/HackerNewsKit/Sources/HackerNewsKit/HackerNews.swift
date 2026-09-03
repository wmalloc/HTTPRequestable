//
//  HackerNews.swift
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import HTTPRequestable

public final class HackerNews: HTTPTransferable, Sendable {
  public static let shared = HackerNews()
  public let requestModifiers: [any HTTPRequestModifier]
  public let interceptors: [any HTTPInterceptor] = []

  public let environment: HTTPEnvironment = .init(authority: "hacker-news.firebaseio.com", path: "/v0")
  public let session: URLSession

  public let retryPolicy: RetryPolicy? = RetryPolicy()

  /// Creates a client.
  /// - Parameter session: The session used for all requests. Defaults to a session backed by
  ///   `URLSessionConfiguration.default`; tests inject one whose `protocolClasses` stub the network.
  public init(session: URLSession = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)) {
    self.session = session
    let modifier = HTTPRequestHeadersModifier(fields: [.accept(.json), .contentType(.json)])
    let traceModifier = TraceRequestModifier.default
    self.requestModifiers = [HTTPRequestHeadersModifier.defaultHeaderModifier, modifier, traceModifier]
  }
}

public extension HackerNews {
  /// Fetches the current top stories.
  /// - Parameter limit: The maximum number of stories to fetch. Fewer are returned when the feed is
  ///   shorter than the limit.
  /// - Returns: The stories, in the order the feed lists them.
  func topStories(limit: Int = 20) async throws -> [Item] {
    precondition(limit > 0, "Limit must be greater than zero")
    let stories = try await Array(stories(type: StoryType.top.rawValue).prefix(limit))
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
