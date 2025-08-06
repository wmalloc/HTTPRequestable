//
//  HTTPResponseInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation
import HTTPTypes

/// Interceptor is a middleware component that can intercept, modify, or observe network requests and responses.
public protocol HTTPInterceptor: Sendable {
  /// Intercepts and customizes the HTTP response before it is returned from a URLSession.
  ///
  /// This method allows for customization of the HTTP response after it is received from the server. It provides an opportunity to modify the response properties, such as headers or body data, before returning it from a `URLSession`.
  ///
  /// - Parameters:
  ///   - response: A reference to an `HTTPAnyResponse` object that can be modified in place. The type of `HTTPAnyResponse` must conform to `HTTPResponse`.
  ///   - session: The `URLSession` from which the response was received. This parameter is provided so that you can adjust the response based on the session's configuration or other properties.
  /// - Throws: An error of type `Error` if there is an issue with the interceptor logic, such as invalid input.
  ///
  /// - Note: The `HTTPAnyResponse` type must conform to `HTTPResponse` for this method to work correctly.
  /// - Note: This method is called automatically by the `object(for:)` and `data(for:)` methods to allow for response customization.
  ///
  /// - SeeAlso: `HTTPResponse`, `URLSession`
  func intercept(_ response: inout HTTPAnyResponse, for session: URLSession) async throws
}

/// Default implementation
public extension HTTPInterceptor {
  @inlinable
  func intercept(_ response: inout HTTPAnyResponse, for session: URLSession) async throws {}
}
