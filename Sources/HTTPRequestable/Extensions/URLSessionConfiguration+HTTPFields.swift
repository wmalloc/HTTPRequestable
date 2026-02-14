//
//  URLSessionConfiguration+HTTPFields.swift
//
//  Created by Waqar Malik on 1/14/23.
//

import Foundation
import HTTPTypes

public extension URLSessionConfiguration {
  /// The HTTP header fields of the session configuration as an `HTTPFields` instance.
  ///
  /// This property provides a convenient way to access or modify the `httpAdditionalHeaders` for a session configuration.
  var httpFields: HTTPFields? {
    get {
      guard let headers = httpAdditionalHeaders as? [String: String] else { return nil }
      return HTTPFields(rawValue: headers)
    }
    set {
      httpAdditionalHeaders = newValue?.rawValue
    }
  }
}
