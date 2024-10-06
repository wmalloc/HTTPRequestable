//
//  ResponseInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation
import HTTPTypes

/// Interceptor is a middleware component that can intercept, modify, or observe network requests and responses.
public protocol ResponseInterceptor {
  func intercept(request: HTTPRequest, data: Data, response: HTTPResponse) async throws
  func intercept(request: URLRequest, data: Data, response: HTTPURLResponse) async throws
}

public extension ResponseInterceptor {
  @inlinable
  func intercept(request: HTTPRequest, data: Data, response: HTTPResponse) async throws {}
  
  @inlinable
  func intercept(request: URLRequest, data: Data, response: HTTPURLResponse) async throws {}
}
