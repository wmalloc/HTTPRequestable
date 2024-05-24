//
//  URLRequest+HTTPFields.swift
//
//  Created by Waqar Malik on 1/14/23.
//  Copyright © 2020 Waqar Malik All rights reserved.
//

import Foundation
import HTTPTypes
import HTTPRequestable

public extension URLRequest {
  @discardableResult
  func setMultipartFormData(_ multipartForm: MultipartForm) throws -> Self {
    let request = self
    try request.setHttpBody(multipartForm.encoded(), contentType: multipartForm.contentType.encoded)
      .setHeader(HTTPField(name: .contentLength, value: "\(multipartForm.contentLength)"))
      .setHeader(HTTPField(name: .contentType, value: multipartForm.contentType.encoded))
    return self
  }
}
