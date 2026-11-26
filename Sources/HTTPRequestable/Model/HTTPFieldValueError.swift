//
//  HTTPFieldValueError.swift
//
//  Created by Waqar Malik on 11/25/26.
//

/// An error thrown when a part of an HTTP field value, such as a ``KeyedItem`` or ``Quality`` item,
/// cannot be written as valid syntax (RFC 9110 section 5.6).
///
/// Values themselves are left out of the error, so a rejected value, which may be sensitive, is not
/// repeated where errors get logged.
public enum HTTPFieldValueError: Error, Equatable, Sendable, CustomStringConvertible {
  /// The item is not a token or a media range such as `text/html`.
  case invalidItem

  /// The parameter name is not a token.
  case invalidParameterName(String)

  /// The value of the named parameter contains a control character, such as CR or LF, that no field
  /// value can hold.
  case invalidParameterValue(name: String)

  /// The q-value is NaN or outside `0...1`.
  case invalidQuality

  public var description: String {
    switch self {
    case .invalidItem:
      "The item is not a token or a media range"
    case .invalidParameterName(let name):
      "The parameter name \"\(name)\" is not a token"
    case .invalidParameterValue(let name):
      "The value of parameter \"\(name)\" contains a control character"
    case .invalidQuality:
      "The q-value is not between 0 and 1"
    }
  }
}
