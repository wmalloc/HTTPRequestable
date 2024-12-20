//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 12/14/24.
//

import Foundation
import HTTPTypes

public protocol HTTPAnyResponse {
  associatedtype ValueType
  
  var request: HTTPRequest { get }
  var response: HTTPResponse { get }
  var result: Result<ValueType, Error> { get }
  var value: ValueType? { get }
  var error: Error? { get }
  var status: HTTPResponse.Status { get }
  
  func validateStatus() throws -> Self
  func validateContentType(_ acceptableContentTypes: Set<String>?) throws -> Self
}

public extension HTTPAnyResponse {
  var value: ValueType? {
    if case .success(let value) = result {
      return value
    }
    return nil
  }
  
  var error: Error? {
    if case .failure(let error) = result {
      return error
    }
    return nil
  }
  
  @inlinable
  var status: HTTPResponse.Status {
    response.status
  }
  
  @discardableResult
  func validateStatus() throws -> Self {
    if response.status.kind != .successful {
      let errorCode = URLError.Code(rawValue: response.status.code)
      throw URLError(errorCode)
    }
    return self
  }
  
  @discardableResult
  func validateContentType(_ acceptableContentTypes: Set<String>? = nil) throws -> Self {
    // bypass if no content type defined
    guard let acceptableContentTypes else {
      return self
    }
    
    // if the server did not set the content type then throw a bad server response
    guard let contentType = response.headerFields[.contentType] else {
      throw URLError(.badServerResponse)
    }
    
    // if content type is not acceptable throw and errro
    guard acceptableContentTypes.contains(contentType) else {
      throw URLError(.notAcceptable)
    }
    
    // success
    return self
  }
}
