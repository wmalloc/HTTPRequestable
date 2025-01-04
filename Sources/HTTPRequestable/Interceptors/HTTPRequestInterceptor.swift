//
//  HTTPRequestInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/24/24.
//

import Foundation
import HTTPTypes

public protocol HTTPRequestInterceptor {
  /// Modify the request if needed
  /// - Parameters:
  ///   - request: The request that needs to be modified
  ///   - session: The session used to send the request
  func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws
}

public extension HTTPRequestInterceptor {
  func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {}
}
