//
//  URLRequest+HTTPFields.swift
//
//  Created by Waqar Malik on 1/14/23.
//

import Foundation
import HTTPTypes

/* 
 # URLRequest+HTTPFields

 This extension adds functionality to `URLRequest` for managing HTTP header fields using the `HTTPFields` type.
 It provides methods to set or add header fields and a computed property to access all header fields.

 */

public extension URLRequest {
  /// Sets the HTTP header fields of the `URLRequest` with the provided `HTTPFields`.
  ///
  /// - Parameter fields: An optional `HTTPFields` instance representing the headers to set. If `nil`, any existing headers are removed.
  /// - Returns: The modified `URLRequest` instance.
  @discardableResult
  func setHttpHeaderFields(_ fields: HTTPFields?) -> Self {
    var request = self
    request.headerFields = fields
    return request
  }

  /// Adds the HTTP header fields from the provided `HTTPFields` to the `URLRequest`.
  ///
  /// - Parameter fields: An instance of `HTTPFields` representing the headers to add.
  /// - Returns: The modified `URLRequest` instance.
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
  /// The HTTP header fields of the `URLRequest` as an `HTTPFields` instance.
  ///
  /// This property provides a convenient way to access or modify all HTTP header fields.
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
