//
//  HTTPAnyResponse.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 12/14/24.
//

import Foundation
import HTTPTypes

public struct HTTPAnyResponse {
  public let request: HTTPRequest
  public let response: HTTPResponse
  public let data: Data?
  public let fileURL: URL?
  
  public init(request: HTTPRequest, response: HTTPResponse, data: Data? = nil, fileURL: URL? = nil) {
    self.request = request
    self.data = data
    self.fileURL = nil
    self.response = response
  }
}

public extension HTTPAnyResponse {
  @inlinable
  var error: Error? {
    response.error
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
