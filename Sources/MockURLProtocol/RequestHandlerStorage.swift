//
//  RequestHandlerStorage.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 4/16/25.
//

import Foundation
import HTTPRequestable

public typealias MockURLRequestHandler = @Sendable (URLRequest) async throws -> (HTTPURLResponse, Data)

actor RequestHandlerStorage {
  private var handlers: [URL: MockURLRequestHandler] = [:]

  func setHandler(_ handler: @escaping MockURLRequestHandler, forURL url: URL) async {
    handlers[url] = handler
  }

  @discardableResult
  func removeHandler(forURL url: URL) -> MockURLRequestHandler? {
    handlers.removeValue(forKey: url)
  }

  func executeHandler(for request: URLRequest) async throws -> (HTTPURLResponse, Data) {
    guard let url = request.url else {
      throw URLError(.badURL)
    }
    guard let handler = removeHandler(forURL: url) else {
      throw HTTPError.cannotCreateURLRequest
    }
    return try await handler(request)
  }
}
