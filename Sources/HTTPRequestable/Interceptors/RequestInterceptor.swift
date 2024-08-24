//
//  RequestInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation
import HTTPTypes

/// Interceptor is a middleware component that can intercept, modify, or observe network requests and responses.
public protocol RequestInterceptor: Interceptor {
  func intercept(_ request: HTTPRequest, for session: URLSession) async throws -> HTTPRequest
  func intercept(_ request: URLRequest, for session: URLSession) async throws -> URLRequest
}

public extension RequestInterceptor {
  @inlinable
  func intercept(_ request: HTTPRequest, for session: URLSession) async throws -> HTTPRequest {
    request
  }

  @inlinable
  func intercept(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
    request
  }
}
