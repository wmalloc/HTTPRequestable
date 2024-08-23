//
//  RequestInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation
import HTTPTypes

/// Interceptor is a middleware component that can intercept, modify, or observe network requests and responses.
public protocol RequestInterceptor {
  func intercept(_ request: HTTPRequest) async throws -> HTTPRequest
  func intercept(_ request: URLRequest) async throws -> URLRequest
}

public extension RequestInterceptor {
  @inlinable
  func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
    request
  }

  @inlinable
  func intercept(_ request: URLRequest) async throws -> URLRequest {
    request
  }
}
