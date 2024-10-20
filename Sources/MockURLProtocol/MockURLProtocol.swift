//
//  MockURLProtocol.swift
//
//
//  Created by Waqar Malik on 5/31/24.
//

import Foundation

public class MockURLProtocol: URLProtocol {
  public typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data?)

  public nonisolated(unsafe) static var requestHandlers: [URL: RequestHandler] = [:]

  override public class func canInit(with _: URLRequest) -> Bool { true }
  override public class func canInit(with _: URLSessionTask) -> Bool { true }
  override public class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override public func startLoading() {
    guard let client else {
      fatalError("missing client")
    }

    let validCodes = Set(200 ..< 300)
    do {
      guard let url = request.url, let handler = Self.requestHandlers.removeValue(forKey: url) else {
        throw URLError(.badURL)
      }

      let (response, data) = try handler(request)
      if !validCodes.contains(response.statusCode) {
        throw URLError(URLError.Code(rawValue: response.statusCode))
      }

      client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

      if let data {
        client.urlProtocol(self, didLoad: data)
      }

      client.urlProtocolDidFinishLoading(self)
    } catch {
      client.urlProtocol(self, didFailWithError: error)
    }
  }

  override public func stopLoading() {}
}
