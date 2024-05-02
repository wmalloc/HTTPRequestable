//
//  HTTPURLResponse+Validation.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation
import HTTPTypes

public extension HTTPURLResponse {
  @discardableResult
  func url_httpValidate(acceptableStatusCodes: Range<Int> = 200 ..< 300, acceptableContentTypes: Set<String>? = nil) throws -> Self {
    try url_httpValidate(acceptableStatusCodes: acceptableStatusCodes)
      .url_httpValidate(acceptableContentTypes: acceptableContentTypes)
  }

  @discardableResult
  func url_httpValidate(acceptableStatusCodes: Range<Int> = 200 ..< 300) throws -> Self {
    guard acceptableStatusCodes.contains(statusCode) else {
      let errorCode = URLError.Code(rawValue: statusCode)
      throw URLError(errorCode)
    }
    return self
  }

  @discardableResult
  func url_httpValidate(acceptableContentTypes: Set<String>? = nil) throws -> Self {
    if let validContentType = acceptableContentTypes {
      if let contentType = value(forHTTPHeaderField: HTTPField.Name.contentType) {
        if !validContentType.contains(contentType) {
          throw URLError(.dataNotAllowed)
        }
      } else {
        throw URLError(.badServerResponse)
      }
    }

    return self
  }
}
