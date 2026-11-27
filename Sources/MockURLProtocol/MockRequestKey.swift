//
//  MockRequestKey.swift
//
//  Created by Waqar Malik on 8/30/25.
//

import Foundation
import HTTPTypes
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A value that supplies the identifier ``MockURLProtocol`` uses to find the handler for a request.
///
/// A handler registered with ``MockURLProtocol/setRequestHandler(_:forIdentifier:)`` answers the sent
/// request whose ``mockIdentifier`` matches. A request is identified by its `X-Mock-Identifier` header,
/// or by its absolute URL when the header is not set.
public protocol MockRequestKey {
  /// The identifier, or `nil` when there is none.
  var mockIdentifier: String? { get }
}

// MARK: - Conformances

extension String: MockRequestKey {
  /// The string itself.
  @inlinable
  public var mockIdentifier: String? {
    self
  }
}

extension URL: MockRequestKey {
  /// The absolute URL string.
  @inlinable
  public var mockIdentifier: String? {
    absoluteString
  }
}

extension URLRequest: MockRequestKey {
  /// The `X-Mock-Identifier` header, or the absolute URL string when the header is not set.
  public var mockIdentifier: String? {
    value(forHTTPHeaderField: .xMockIdentifier) ?? url?.mockIdentifier
  }
}

extension HTTPRequest: MockRequestKey {
  /// The `X-Mock-Identifier` header, or the absolute URL string when the header is not set.
  public var mockIdentifier: String? {
    headerFields[.xMockIdentifier] ?? url?.mockIdentifier
  }
}
