//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/24/24.
//

import Foundation
import HTTPTypes

public struct ContentTypeValidator: ResponseInterceptor {
  let acceptableContentTypes: Set<String>?
  
  public init(acceptableContentTypes: Set<String>? = nil) {
    self.acceptableContentTypes = acceptableContentTypes
  }
  
  public func intercept(request: HTTPRequest, data: Data, response: HTTPTypes.HTTPResponse) async throws {
    guard let acceptableContentTypes else {
      return
    }
    
    if let contentType = response.headerFields[.contentType] {
      if !acceptableContentTypes.contains(contentType) {
        throw URLError(.dataNotAllowed)
      }
    } else {
      throw URLError(.badServerResponse)
    }
  }
  
  public func intercept(request: URLRequest, data: Data, response: HTTPURLResponse) async throws {
    guard let acceptableContentTypes else {
      return
    }
    
    if let contentType = response.value(forHTTPHeaderField: HTTPField.Name.contentType) {
      if !acceptableContentTypes.contains(contentType) {
        throw URLError(.dataNotAllowed)
      }
    } else {
      throw URLError(.badServerResponse)
    }
  }
}
