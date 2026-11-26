//
//  MockURLProtocol.swift
//
//  Created by Waqar Malik on 5/31/24.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif
import HTTPRequestable

public class MockURLProtocol: URLProtocol, @unchecked Sendable {
  private static let requestHandlerStorage = RequestHandlerStorage()

  /// Registers `handler` to answer the next request sent for `request`.
  ///
  /// The handler is keyed by the request's `X-Test-Identifier` header, or by its absolute URL when the
  /// header is not set, matching how a sent request is looked up. It answers one request and is then
  /// removed.
  ///
  /// - Parameters:
  ///   - handler: Produces the response for the request.
  ///   - request: The request the handler answers.
  /// - Throws: `URLError(.badURL)` when the request has no `X-Test-Identifier` header and no valid URL.
  public static func setRequestHandler(_ handler: @escaping MockURLRequestHandler, forRequest request: some HTTPRequestConfigurable) async throws {
    try await setRequestHandler(handler, testIdentifier: request.testIdentifier ?? (try? request.url)?.testIdentifier)
  }

  /// Registers `handler` to answer the next request whose test identifier matches `identifier`.
  ///
  /// A sent request is identified by its `X-Test-Identifier` header, or by its absolute URL when the
  /// header is not set. The handler answers one request and is then removed.
  ///
  /// - Parameters:
  ///   - handler: Produces the response for the request.
  ///   - identifier: The identifier to match, such as the request's URL or its test identifier string.
  /// - Throws: `URLError(.badURL)` when `identifier` has no test identifier.
  public static func setRequestHandler(_ handler: @escaping MockURLRequestHandler, forIdentifier identifier: some TestIdentifiable) async throws {
    try await setRequestHandler(handler, testIdentifier: identifier.testIdentifier)
  }

  private static func setRequestHandler(_ handler: @escaping MockURLRequestHandler, testIdentifier: String?) async throws {
    guard let testIdentifier else {
      throw URLError(.badURL)
    }
    await requestHandlerStorage.setHandler(handler, forIdentifier: testIdentifier)
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
    Task {
      do {
        let (data, response) = try await executeHandler(for: request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
      } catch {
        client?.urlProtocol(self, didFailWithError: error)
      }
    }
  }

  override public func stopLoading() {}
}
