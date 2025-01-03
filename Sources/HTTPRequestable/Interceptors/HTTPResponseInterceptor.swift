//
//  HTTPResponseInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation
import HTTPTypes

/// Interceptor is a middleware component that can intercept, modify, or observe network requests and responses.
public protocol HTTPResponseInterceptor {
  func intercept(request: HTTPRequest, data: Data?, url: URL?, response: HTTPResponse) async throws
}

public extension HTTPResponseInterceptor {
  @inlinable
  func intercept(request: HTTPRequest, data: Data?, url: URL?, response: HTTPResponse) async throws {}
}
