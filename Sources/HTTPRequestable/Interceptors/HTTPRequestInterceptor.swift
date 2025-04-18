//
//  HTTPRequestInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/24/24.
//

import Foundation
import HTTPTypes

public protocol HTTPRequestInterceptor: Sendable {
  /// Intercepts and customizes the HTTP request before it is sent through a URLSession.
  ///
  /// This method allows for customization of the HTTP request before it is sent to the server. It provides an opportunity to modify the request properties, such as headers or body data, before the request is sent through a `URLSession`.
  ///
  /// - Parameters:
  ///   - request: A reference to an `HTTPRequest` object that can be modified in place. The type of `HTTPRequest` must conform to `HTTPRequestable`.
  ///   - session: The `URLSession` through which the request will be sent. This parameter is provided so that you can adjust the request based on the session's configuration or other properties.
  /// - Throws: An error of type `Error` if there is an issue with the interceptor logic, such as invalid input.
  ///
  /// - Note: The `HTTPRequest` type must conform to `HTTPRequestable` for this method to work correctly.
  /// - Note: This method is called automatically by the `object(for:)` and `data(for:)` methods to allow for request customization.
  ///
  /// - SeeAlso: `HTTPRequestable`, `URLSession`
  func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws
}

/// Default implemenation
public extension HTTPRequestInterceptor {
  func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {}
}
