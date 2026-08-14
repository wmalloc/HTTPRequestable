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
  @inlinable
  func modify(_ request: inout HTTPRequest, for session: URLSession?) async throws {}

  @inlinable
  func modify(_ request: inout URLRequest, for session: URLSession?) async throws {}
}
