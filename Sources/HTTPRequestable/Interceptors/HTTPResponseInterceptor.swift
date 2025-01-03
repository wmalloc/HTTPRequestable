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
//  func intercept<InputType, OutputType>(request: HTTPRequest, response: HTTPAnyResponse<InputType>) async throws -> HTTPAnyResponse<OutputType>
  func intercept(request: HTTPRequest, data: Data?, url: URL?, response: HTTPResponse) async throws
}

public extension HTTPResponseInterceptor {
  @inlinable
  func intercept(request: HTTPRequest, data: Data?, url: URL?, response: HTTPResponse) async throws {}
//  
//  @inlinable
//  func intercept<InputType, OutputType>(request: HTTPRequest, response: HTTPAnyResponse<InputType>) async throws -> HTTPAnyResponse<OutputType> {
//    HTTPAnyResponse(request: request, response: HTTPAny, data: response.data, fileURL: response.fileURL)
//  }
}
