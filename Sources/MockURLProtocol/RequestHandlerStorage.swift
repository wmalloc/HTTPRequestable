//
//  RequestHandlerStorage.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 4/16/25.
//

import Foundation
import HTTPRequestable

/// A closure that produces a mock response for a given ``URLRequest``.
///
/// `MockURLRequestHandler` is the function signature used by
/// :class:`MockURLProtocol`.  It receives the request, performs any logic you
/// need (e.g., matching against URL patterns or inspecting headers), and then
/// returns a tuple containing the data to send back **and** the HTTP response.
/// The closure is `async` so it can await I/O or other async work, and it
/// propagates errors to let your test fail cleanly.
///
/// ```swift
/// let handler: MockURLRequestHandler = { request in
///     guard request.url?.host == "example.com" else {
///         throw URLError(.badServerResponse)
///     }
///     let data = Data("Hello".utf8)
///     let response = HTTPURLResponse(
///         url: request.url!,
///         statusCode: 200,
///         httpVersion: nil,
///         headerFields: ["Content-Type": "text/plain"]
///     )!
///     return (data, response)
/// }
/// ```
///
/// - Parameter request: The incoming ``URLRequest``.
/// - Returns: A tuple of the mock data and a fully‑configured
///   ``HTTPURLResponse``.
/// - Throws: Any error you wish to surface to the caller; e.g. an HTTP error
///   status or custom test failure.
///
/// **Use case**
/// Register handlers via :func:`MockURLProtocol.setRequestHandler(_:for:)`
/// to simulate network interactions in unit tests without hitting a real
/// server.
public typealias MockURLRequestHandler = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

actor RequestHandlerStorage {
  private var handlers: [String: MockURLRequestHandler] = [:]

  func setHandler(_ handler: @escaping MockURLRequestHandler, forIdentifier identifier: String) async {
    handlers[identifier] = handler
  }

  @discardableResult
  func removeHandler(forIdentifier identifier: String) -> MockURLRequestHandler? {
    handlers.removeValue(forKey: identifier)
  }

  func executeHandler(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    guard let identifier = request.testIdentifier else {
      throw HTTPError.headerValueMissing("testIdentifier")
    }
    guard let handler = removeHandler(forIdentifier: identifier) else {
      throw HTTPError.cannotCreateURLRequest
    }
    return try await handler(request)
  }
}
