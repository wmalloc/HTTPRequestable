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
  /// Response interceptor
  /// - Parameters:
  ///   - response: Response objec that containes all items need
  ///   - session: Session that was used to make the call
  func intercept(_ response: inout HTTPAnyResponse, for session: URLSession) async throws
}

public extension HTTPResponseInterceptor {
  @inlinable
  func intercept(_ response: inout HTTPAnyResponse, for session: URLSession) async throws {}
}
