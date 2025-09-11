//
//  URLRequest+HTTPField.swift
//
//  Created by Waqar Malik on 7/12/23.
//

import Foundation
import HTTPTypes

/**
 # URLRequest+HTTPField

 This extension adds convenience methods and properties to `URLRequest` for working with HTTP fields.
 It simplifies the process of accessing, setting, and modifying HTTP headers, including common fields
 like `Content-Type` and `User-Agent`.

 */

public extension URLRequest {
  /// Retrieves the value of the specified HTTP field.
  ///
  /// - Parameter name: The name of the HTTP field.
  /// - Returns: The value of the HTTP field, or `nil` if the field is not set.
  func value(forHTTPField name: HTTPField.Name) -> String? {
    value(forHTTPHeaderField: name.canonicalName) ?? value(forHTTPHeaderField: name.rawName)
  }

  /// Sets the value of the specified HTTP field.
  ///
  /// - Parameters:
  ///   - value: The value to set for the HTTP field. Pass `nil` to remove the field.
  ///   - name: The name of the HTTP field.
  mutating func setValue(_ value: String?, forHTTPField name: HTTPField.Name) {
    setValue(value, forHTTPHeaderField: name.rawName)
  }

  /// Adds a value to the specified HTTP field.
  ///
  /// - Parameters:
  ///   - value: The value to add to the HTTP field.
  ///   - name: The name of the HTTP field.
  mutating func addValue(_ value: String, forHTTPField name: HTTPField.Name) {
    addValue(value, forHTTPHeaderField: name.rawName)
  }

  /// Accesses the value of an HTTP header field using a string key.
  ///
  /// - Parameter key: The name of the HTTP header field.
  /// - Returns: The value of the HTTP header field, or `nil` if the field is not set.
  subscript(header key: String) -> String? {
    get {
      value(forHTTPHeaderField: key)
    }
    set {
      setValue(newValue, forHTTPHeaderField: key)
    }
  }

  /// Accesses the value of an HTTP field using an `HTTPField.Name` key.
  ///
  /// - Parameter field: The name of the HTTP field.
  /// - Returns: The value of the HTTP field, or `nil` if the field is not set.
  subscript(field: HTTPField.Name) -> String? {
    get {
      value(forHTTPField: field)
    }
    set {
      setValue(newValue, forHTTPField: field)
    }
  }

  /// The value of the `Content-Type` HTTP field.
  ///
  /// This property provides a convenient way to access or modify the `Content-Type` header.
  var contentType: String? {
    get {
      self[.contentType]
    }
    set {
      self[.contentType] = newValue
    }
  }

  /// The value of the `User-Agent` HTTP field.
  ///
  /// This property provides a convenient way to access or modify the `User-Agent` header.
  var userAgent: String? {
    get {
      self[.userAgent]
    }
    set {
      self[.userAgent] = newValue
    }
  }
}
