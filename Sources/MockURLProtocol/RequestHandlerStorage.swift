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
  private var handlers: [String: MockURLRequestHandler] = [:]

  func setHandler(_ handler: @escaping MockURLRequestHandler, forRequest request: any HTTPRequestable) async {
    guard let identifier = request.testIdentifier else {
      return
    }
    handlers[identifier] = handler
  }

  @discardableResult
  func removeHandler(forIdentifier identifier: String) -> MockURLRequestHandler? {
    handlers.removeValue(forKey: identifier)
  }

  func executeHandler(for request: URLRequest) async throws -> (HTTPURLResponse, Data) {
    guard let identifier = request.testIdentifier else {
      throw HTTPError.headerValueMissing(.testIdentifier)
    }
    guard let handler = removeHandler(forIdentifier: identifier) else {
      throw HTTPError.cannotCreateURLRequest
    }
    return try await handler(request)
  }
}
