//
//  URLSessionConfiguration+HTTPFields.swift
//
//  Created by Waqar Malik on 1/14/23.
//

import Foundation
import HTTPTypes

/* 
 # URLSessionConfiguration+HTTPFields

 This extension adds a computed property to `URLSessionConfiguration` for managing HTTP header fields using the `HTTPFields` type.
 */

public extension URLSessionConfiguration {
  /// The HTTP header fields of the session configuration as an `HTTPFields` instance.
  ///
  /// This property provides a convenient way to access or modify the `httpAdditionalHeaders` for a session configuration.
  var httpFields: HTTPFields {
    get { HTTPFields(rawValue: httpAdditionalHeaders as? [String: String] ?? [:]) }
    set { httpAdditionalHeaders = newValue.rawValue }
  }
}
