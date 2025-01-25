//
//  HTTPFields+Transferable.swift
//
//
//  Created by Waqar Malik on 5/18/24.
//

import Foundation
import HTTPTypes

/// Extension providing convenience initializers and computed properties for HTTP fields (headers).
public extension HTTPFields {
  /// Initializes a new `HTTPFields` instance from a dictionary of raw string values where keys represent header names and values represent header values.
  /// - Parameter rawValue: A dictionary with strings as keys and values representing the headers' names and their corresponding values.
  init(rawValue: [String: String]) {
    self.init()
    for (key, value) in rawValue {
      guard let name = HTTPField.Name(key) else {
        continue
      }
      let field = HTTPField(name: name, value: value)
      append(field)
    }
  }

  /// A computed property that combines the fields into a dictionary where keys are `HTTPField.Name` and values are header values as strings.
  var combinedFields: [HTTPField.Name: String] {
    reduce(into: [:]) { $0[$1.name] = self[$1.name] }
  }

  /// A computed property that returns the fields as a dictionary where keys are raw string representations of `HTTPField.Name` and values are header values as
  /// dictionary
  var rawValue: [String: String] {
    var headerFields = [String: String](minimumCapacity: combinedFields.count)
    for (name, value) in combinedFields {
      headerFields[name.rawName] = value
    }
    return headerFields
  }
}
