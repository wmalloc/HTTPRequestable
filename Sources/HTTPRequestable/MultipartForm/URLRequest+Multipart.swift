//
//  URLRequest+Multipart.swift
//
//  Created by Waqar Malik on 1/14/23.
//

import Foundation
import HTTPTypes

public extension URLRequest {
  /// Append the multipart form data to request, and header fields
  @discardableResult
  func setMultipartFormData(_ multipartForm: MultipartForm) throws -> Self {
    try setHttpBody(multipartForm.data(), contentType: multipartForm.contentType.encoded)
      .setHeader(HTTPField(name: .contentLength, value: "\(multipartForm.contentLength)"))
  }
}
