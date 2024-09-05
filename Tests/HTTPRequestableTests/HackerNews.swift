//
//  HackerNewsAPI.swift
//
//
//  Created by Waqar Malik on 7/15/23.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
class HackerNews: HTTPTransferable, @unchecked Sendable {
  var requestInterceptors: [any RequestInterceptor] = []
  var responseInterceptors: [any ResponseInterceptor] = []

  let session: URLSession

  required init(session: URLSession = .shared) {
    self.session = session
    let logger = LoggerInterceptor()
    requestInterceptors.append(logger)
    responseInterceptors.append(logger)
  }

  func storyList(type: String) async throws -> StoryList.ResultType {
    let request = try StoryList(storyType: type)
    return try await object(for: request, delegate: nil)
  }
}

struct StoryList: HTTPRequestable {
  typealias ResultType = [Int]

  var environment: HTTPEnvironment = .init(scheme: "https", authority: "hacker-news.firebaseio.com")
  let headerFields: HTTPFields? = .init([.accept(.json)])
  let queryItems: [URLQueryItem]? = [URLQueryItem(name: "print", value: "pretty")]

  var responseTransformer: Transformer<Data, ResultType> {
    { data, _ in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }

  init(storyType: String) throws {
    guard !storyType.isEmpty else {
      throw URLError(.badURL)
    }
    environment.path = "/v0/" + storyType
  }
}
