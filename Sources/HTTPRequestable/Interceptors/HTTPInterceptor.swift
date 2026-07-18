//
//  HTTPInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation
import HTTPTypes

/// Interceptor is a middleware component that can intercept, modify, or observe network requests and responses.
public protocol HTTPInterceptor: Sendable {
  /// A closure type representing the next step in the interceptor chain.
  ///
  /// This typealias is used to forward the current HTTP request, optional body data, and an optional delegate
  /// to the next interceptor or the actual network execution. It allows interceptors to perform pre-processing,
  /// post-processing, or short-circuit the request handling.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` object representing the original or modified outbound HTTP request.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An `HTTPClientResponse` representing the response for the request.
  /// - Throws: Propagates any error thrown by the next interceptor or the underlying network operation.
  typealias NextHandler = (_ request: HTTPRequest, _ delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPClientResponse

  /**
   Intercepts an outgoing HTTP request, allowing modification, observation, or short-circuiting of the request before it continues through the interceptor chain.

   Use this method to inspect or alter the outgoing request (including headers or body if represented within `HTTPRequest`), provide a custom response, or perform asynchronous work before delegating to the next interceptor.

   - Parameters:
     - request: The `HTTPRequest` representing the outbound HTTP request to be sent.
     - next: A closure for invoking the next interceptor or performing the actual network operation. Call this with (potentially modified) arguments to continue the chain.
     - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
   - Returns: An `HTTPClientResponse` representing the network response or an interceptor-provided response.
   - Throws: Propagates any error thrown by the next interceptor or the underlying network operation, or throws an error if intercepting fails.

   - Note: If you wish to continue the request with modified values, call `next` using the new values. If you wish to terminate the chain early, do not call `next` and instead return or throw your own response or error.
   */
  func intercept(_ request: HTTPRequest, next: @escaping NextHandler, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPClientResponse
}

/// Default implementation
public extension HTTPInterceptor {
  @inlinable
  func intercept(_ request: HTTPRequest, next: @escaping NextHandler, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPClientResponse {
    try await next(request, delegate)
  }
}
