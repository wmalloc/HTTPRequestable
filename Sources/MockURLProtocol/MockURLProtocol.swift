//
//  MockURLProtocol.swift
//
//  Created by Waqar Malik on 5/31/24.
//

import Foundation
import HTTPRequestable
import HTTPTypes

public class MockURLProtocol: URLProtocol, @unchecked Sendable {
  private static let requestHandlerStorage = RequestHandlerStorage()

  public static func setRequestHandler(_ handler: @escaping MockURLRequestHandler, forRequest request: any HTTPRequestConvertible) async throws {
    guard let identifier = request.testIdentifier else {
      throw URLError(.badURL)
    }
    await requestHandlerStorage.setHandler({ request in
      try await handler(request)
    }, forIdentifier: identifier)
  }

  public static func setRequestHandler(_ handler: @escaping MockURLRequestHandler, forIdentifier identifier: any TestIdentifiable) async throws {
    guard let testIdentifier = identifier.testIdentifier else {
      throw URLError(.badURL)
    }
    await requestHandlerStorage.setHandler({ request in
      try await handler(request)
    }, forIdentifier: testIdentifier)
  }

  override public class func canInit(with _: URLRequest) -> Bool { true }
  override public class func canInit(with _: URLSessionTask) -> Bool { true }
  override public class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

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
