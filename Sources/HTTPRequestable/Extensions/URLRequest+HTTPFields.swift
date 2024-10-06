//
//  URLRequest+HTTPFields.swift
//
//  Created by Waqar Malik on 1/14/23.
//

import Foundation
import HTTPTypes

public extension URLRequest {
  @discardableResult
  func setHttpHeaderFields(_ fields: HTTPFields?) -> Self {
    var request = self
    request.headerFields = fields
    return request
  }

  @discardableResult
  func addHeaderFields(_ fields: HTTPFields) -> Self {
    var request = self
    for header in fields {
      request.addValue(header.value, forHTTPField: header.name)
    }
    return request
  }
}

public extension URLRequest {
  var headerFields: HTTPFields? {
    get {
      guard let allHTTPHeaderFields else {
        return nil
      }
      return HTTPFields(rawValue: allHTTPHeaderFields)
    }
    set {
      allHTTPHeaderFields = newValue?.rawValue
    }
  }
}
