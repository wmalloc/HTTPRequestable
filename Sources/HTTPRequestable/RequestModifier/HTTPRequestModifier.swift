//
//  HTTPRequestModifier.swift
//
//  Created by Waqar Malik on 9/24/24.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif
import HTTPTypes

public protocol HTTPRequestModifier: Sendable {
  /// The hosts this modifier is restricted to.
  ///
  /// When `nil` (the default), the modifier applies to requests for any host. When non-nil, the modifier
  /// is only applied to requests whose host is in the set; host comparison is case-insensitive and ignores the port.
  var allowedHosts: Set<String>? { get }

  /// Intercepts and customizes the HTTP request before it is sent through a URLSession.
  ///
  /// Use this hook to modify request properties (for example, headers, cache policy, or body if represented on `HTTPRequest`) based on runtime context.
  /// This method is invoked by the request execution pipeline prior to sending the request.
  ///
  /// - Parameters:
  ///   - request: An inout `HTTPRequest` that you may modify in place.
  ///   - session: The `URLSession` through which the request will be sent, if available. Use this for contextual adjustments based on configuration.
  ///   This value may be `nil` when no session is available or applicable.
  /// - Throws: An error if modification fails.
  func modify(_ request: inout HTTPRequest, for session: URLSession?) async throws

  /// Intercepts and customizes the URL request before it is sent through a URLSession.
  ///
  /// Use this hook to modify request properties (for example, headers, cache policy, or HTTP body) based on runtime context.
  /// This method is invoked by the request execution pipeline prior to sending the request.
  ///
  /// - Parameters:
  ///   - request: An inout `URLRequest` that you may modify in place.
  ///   - session: The `URLSession` through which the request will be sent, if available. Use this for contextual adjustments based on configuration.
  ///   This value may be `nil` when no session is available or applicable.
  /// - Throws: An error if modification fails.
  func modify(_ request: inout URLRequest, for session: URLSession?) async throws
}

/// Default implementation
public extension HTTPRequestModifier {
  var allowedHosts: Set<String>? { nil }

  /// Returns `true` if this modifier should be applied to a request for `url`.
  ///
  /// - Parameter url: The request's URL, or `nil` if it could not be determined.
  /// - Returns: `true` when `allowedHosts` is `nil`, or when the host of `url` is contained in `allowedHosts`.
  func isAllowed(url: URL?) -> Bool {
    guard let allowedHosts else {
      return true
    }
    guard let host = url?.host(percentEncoded: false)?.lowercased() else {
      return false
    }
    return allowedHosts.contains { $0.lowercased() == host }
  }

  @inlinable
  func modify(_ request: inout HTTPRequest, for session: URLSession?) async throws {}

  @inlinable
  func modify(_ request: inout URLRequest, for session: URLSession?) async throws {}
}
