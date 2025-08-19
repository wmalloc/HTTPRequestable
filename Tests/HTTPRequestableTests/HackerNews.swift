//
//  HackerNews.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes

final class HackerNews: HTTPTransferable, @unchecked Sendable {
  var requestModifiers: [any HTTPRequestModifier] = []
  var interceptors: [any HTTPInterceptor] = []

  let session: URLSession

  let environment: HTTPEnvironment = .init(scheme: "https", authority: "hacker-news.firebaseio.com", path: "/v0")

  init(session: URLSession = .shared) {
    self.session = session
    let logger = LoggerInterceptor()
    requestModifiers.append(logger)
    interceptors.append(logger)
  }
}

extension HackerNews {
  func storyList(type: String) async throws -> StoryListRequest.ResultType {
    let request = try StoryListRequest(environment: environment, storyType: type)
    return try await object(for: request, delegate: nil)
  }
}
