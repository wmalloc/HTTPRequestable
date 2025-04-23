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
  let requestInterceptors = AsyncArray<any HTTPRequestInterceptor>()
  let responseInterceptors = AsyncArray<any HTTPResponseInterceptor>()

  let session: URLSession

  private(set) var environment: HTTPEnvironment = .init(scheme: "https", authority: "hacker-news.firebaseio.com", path: "/v0")

  required init(session: URLSession = .shared) {
    self.session = session
    Task {
      let logger = LoggerInterceptor()
      await requestInterceptors.append(logger)
      await responseInterceptors.append(logger)
    }
  }
}

extension HackerNews {
  func storyList(type: String) async throws -> StoryListRequest.ResultType {
    let request = try StoryListRequest(environment: environment, storyType: type)
    return try await object(for: request, delegate: nil)
  }
}
