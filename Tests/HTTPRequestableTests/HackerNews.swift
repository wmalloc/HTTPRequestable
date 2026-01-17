//
//  HackerNews.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes

@globalActor actor HackerNewsActor: GlobalActor {
  static let shared = HackerNewsActor()

  private init() {}
}

@HackerNewsActor
final class HackerNews: HTTPTransferable {
  static let shared = HackerNews()

  var requestModifiers: [any HTTPRequestModifier] = []
  var interceptors: [any HTTPInterceptor] = []
  let session: URLSession
  let environment: HTTPEnvironment = .init(authority: "hacker-news.firebaseio.com", path: "/v0")

  nonisolated init(session: URLSession = .shared) {
    self.session = session
    let logger = LoggerInterceptor()
    requestModifiers.append(logger)
    interceptors.append(logger)
  }
}

extension HackerNews {
  func storyList(type: String) async throws -> StoryListRequest.ResultType {
    let request = try StoryListRequest(environment, storyType: type)
    return try await object(for: request, delegate: nil)
  }
}
