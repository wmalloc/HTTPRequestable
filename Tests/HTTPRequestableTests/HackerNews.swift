//
//  HackerNews.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes

class HackerNews: HTTPTransferable, @unchecked Sendable {
  var requestInterceptors: [any RequestInterceptor] = []
  var responseInterceptors: [any ResponseInterceptor] = []

  let session: URLSession
  
  private(set) var environment: HTTPEnvironment = .init(scheme: "https", authority: "hacker-news.firebaseio.com", path: "/v0")

  required init(session: URLSession = .shared) {
    self.session = session
    let logger = LoggerInterceptor()
    requestInterceptors.append(logger)
    responseInterceptors.append(logger)
  }
}

extension HackerNews {
  func storyList(type: String) async throws -> StoryListRequest.ResultType {
    let request = try StoryListRequest(environment: environment, storyType: type)
    return try await object(for: request, delegate: nil).value ?? []
  }
}
