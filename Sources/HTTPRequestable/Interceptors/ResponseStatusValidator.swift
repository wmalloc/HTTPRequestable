//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/24/24.
//

import Foundation
import HTTPTypes

public struct ResponseStatusValidator: ResponseInterceptor {
  public func intercept(request: HTTPRequest, data: Data, response: HTTPTypes.HTTPResponse) async throws {
    if response.status.kind != .successful {
      let errorCode = URLError.Code(rawValue: response.status.code)
      throw URLError(errorCode)
    }
  }
  
  public func intercept(request: URLRequest, data: Data, response: HTTPURLResponse) async throws {
    if response.status.kind != .successful {
      let errorCode = URLError.Code(rawValue: response.status.code)
      throw URLError(errorCode)
    }
  }
}
