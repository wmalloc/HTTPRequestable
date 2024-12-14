//
//  HTTPDownloadResponse.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 10/24/24.
//

import Foundation
import HTTPTypes

public struct HTTPDownloadResponse<ValueType: Sendable>: HTTPAnyResponse, Sendable {
  public let request: HTTPRequest
  public let fileURL: URL
  public let response: HTTPResponse

  public let result: Result<ValueType, Error>

  public init(request: HTTPRequest, fileURL: URL, response: HTTPResponse, result: Result<ValueType, Error>) {
    self.request = request
    self.fileURL = fileURL
    self.response = response
    self.result = result
  }
}
