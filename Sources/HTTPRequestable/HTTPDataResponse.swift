//
//  HTTPDataResponse.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 10/23/24.
//

import Foundation
import HTTPTypes

public struct HTTPDataResponse<ValueType: Sendable>: HTTPAnyResponse, Sendable {
  public let request: HTTPRequest
  public let data: Data
  public let response: HTTPResponse
  
  public let result: Result<ValueType, Error>
  
  public init(request: HTTPRequest, data: Data, response: HTTPResponse, result: Result<ValueType, Error>) {
    self.request = request
    self.data = data
    self.response = response
    self.result = result
  }
}
