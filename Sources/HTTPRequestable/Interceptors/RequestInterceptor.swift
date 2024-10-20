//
//  RequestInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/24/24.
//

import Foundation
import HTTPTypes

public protocol RequestInterceptor {
  func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws
}

public extension RequestInterceptor {
  func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {}
}
