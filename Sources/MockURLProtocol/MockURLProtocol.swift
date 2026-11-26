//
//  MockURLProtocol.swift
//
//  Created by Waqar Malik on 5/31/24.
//

import Foundation
import HTTPRequestable
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A `URLProtocol` that answers requests with handlers registered by the test, instead of the network.
///
/// Add it to a session's `URLSessionConfiguration.protocolClasses`, then register a handler for each
/// request with ``setRequestHandler(_:forRequest:)`` or ``setRequestHandler(_:forIdentifier:)``.
public class MockURLProtocol: URLProtocol {
  private static let requestHandlerStorage = RequestHandlerStorage()

  /// Registers `handler` to answer the next request sent for `request`.
  ///
  /// The handler is keyed by the request's `X-Mock-Identifier` header, or by its absolute URL when the
  /// header is not set, matching how a sent request is looked up. It answers one request and is then
  /// removed.
  ///
  /// - Parameters:
  ///   - handler: Produces the response for the request.
  ///   - request: The request the handler answers.
  /// - Throws: `URLError(.badURL)` when the request has no `X-Mock-Identifier` header and no valid URL.
  public static func setRequestHandler(_ handler: @escaping MockURLRequestHandler, forRequest request: some HTTPRequestConfigurable) async throws {
    try await setRequestHandler(handler, mockIdentifier: request.mockIdentifier ?? (try? request.url)?.mockIdentifier)
  }

  /// Registers `handler` to answer the next request whose test identifier matches `identifier`.
  ///
  /// A sent request is identified by its `X-Mock-Identifier` header, or by its absolute URL when the
  /// header is not set. The handler answers one request and is then removed.
  ///
  /// - Parameters:
  ///   - handler: Produces the response for the request.
  ///   - identifier: The identifier to match, such as the request's URL or its `X-Mock-Identifier` value.
  /// - Throws: `URLError(.badURL)` when `identifier` has no mock identifier.
  public static func setRequestHandler(_ handler: @escaping MockURLRequestHandler, forIdentifier identifier: some MockRequestKey) async throws {
    try await setRequestHandler(handler, mockIdentifier: identifier.mockIdentifier)
  }

  private static func setRequestHandler(_ handler: @escaping MockURLRequestHandler, mockIdentifier: String?) async throws {
    guard let mockIdentifier else {
      throw URLError(.badURL)
    }
    await requestHandlerStorage.setHandler(handler, forIdentifier: mockIdentifier)
  }

  override public class func canInit(with _: URLRequest) -> Bool {
    true
  }

  override public class func canInit(with _: URLSessionTask) -> Bool {
    true
  }

  override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  func executeHandler(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    try await Self.requestHandlerStorage.executeHandler(for: request)
  }

  override public func startLoading() {
    // `URLProtocol` is not `Sendable` on every platform, so the task reaches this instance through a box
    // instead of capturing `self`.
    let loader = UncheckedSendableBox(self)
    Task {
      let urlProtocol = loader.value
      do {
        let (data, response) = try await urlProtocol.executeHandler(for: urlProtocol.request)
        urlProtocol.client?.urlProtocol(urlProtocol, didReceive: response, cacheStoragePolicy: .notAllowed)
        urlProtocol.client?.urlProtocol(urlProtocol, didLoad: data)
        urlProtocol.client?.urlProtocolDidFinishLoading(urlProtocol)
      } catch {
        urlProtocol.client?.urlProtocol(urlProtocol, didFailWithError: error)
      }
    }
  }

  override public func stopLoading() {}
}

#if canImport(Darwin)
// `@unchecked` because `URLProtocol` is an open Foundation class that is not `Sendable`, so the compiler
// cannot check a subclass. MockURLProtocol adds no stored state of its own: handlers live in the
// `RequestHandlerStorage` actor, and the URL Loading System owns the inherited `request` and `client`.
// On Linux, Foundation marks `URLProtocol`'s `Sendable` conformance unavailable, which subclasses
// inherit, so the conformance is declared only on Apple platforms.
extension MockURLProtocol: @unchecked Sendable {}
#endif

/// Carries a value that is not `Sendable` into a task.
///
/// `@unchecked` because the value is a `URLProtocol` that the URL Loading System hands to
/// `startLoading()`. The loading task is the only code that uses it after that call, and it only
/// reports to the protocol's `client`, as `URLProtocol` subclasses do from their own threads.
private struct UncheckedSendableBox<Value>: @unchecked Sendable {
  let value: Value

  init(_ value: Value) {
    self.value = value
  }
}
