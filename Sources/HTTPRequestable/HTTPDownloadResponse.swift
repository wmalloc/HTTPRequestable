//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 10/24/24.
//

import Foundation
import HTTPTypes

public struct HTTPDownloadResponse<ValueType: Sendable>: Sendable {
  public let request: HTTPRequest
  public let fileURL: URL
  public let response: HTTPResponse
  
  public let result: Result<ValueType, Error>
  
  public var value: ValueType? {
    if case .success(let value) = result {
      return value
    }
    return nil
  }
  
  public var error: Error? {
    if case .failure(let error) = result {
      return error
    }
    return nil
  }
  
  public init(request: HTTPRequest, fileURL: URL, response: HTTPResponse, result: Result<ValueType, Error>) {
    self.request = request
    self.fileURL = fileURL
    self.response = response
    self.result = result
  }
  
  @inlinable
  public var status: HTTPResponse.Status {
    response.status
  }
}
