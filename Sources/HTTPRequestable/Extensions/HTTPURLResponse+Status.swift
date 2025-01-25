//
//  HTTPURLResponse+Status.swift
//
//  Created by Waqar Malik on 7/14/23.
//

import Foundation
import HTTPTypes

/// Extension providing a type alias for HTTP response status and computed properties for accessing headers and status.
public extension HTTPURLResponse {
  /// A type alias representing the status of an HTTP response, conforming to `ExpressibleByIntegerLiteral`.
  typealias Status = HTTPResponse.Status

  /// A computed property that returns the status of the HTTP response as a `Status` instance, initialized with the numeric value of `statusCode`.
  var status: Status {
    Status(integerLiteral: statusCode)
  }
}

/// Extension providing a method for accessing header values by field name.
public extension HTTPURLResponse {
  /// A method that returns the value for a specified HTTP header field, checking both canonical and raw names if necessary.
  /// - Parameter field: The `HTTPField.Name` representing the header field to retrieve.
  /// - Returns: An optional string containing the value of the specified header field, or `nil` if the field is not found.
  func value(forHTTPHeaderField field: HTTPField.Name) -> String? {
    value(forHTTPHeaderField: field.canonicalName) ?? value(forHTTPHeaderField: field.rawName)
  }
}

/// Extension providing a method for accessing header values from dictionaries by field name.
public extension [AnyHashable: Any] {
  /// A method that returns the value for a specified HTTP header field, checking both canonical and raw names if necessary.
  /// - Parameter field: The `HTTPField.Name` representing the header field to retrieve.
  /// - Returns: An optional string containing the value of the specified header field, or `nil` if the field is not found.
  func value(forHTTPHeaderField field: HTTPField.Name) -> String? {
    (self[field.canonicalName] ?? self[field.rawName]) as? String
  }
}
