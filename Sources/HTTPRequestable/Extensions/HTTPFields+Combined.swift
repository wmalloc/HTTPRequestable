//
//  File.swift
//
//
//  Created by Waqar Malik on 5/18/24.
//

import Foundation
import HTTPTypes

public extension HTTPFields {
  var combinedFields: [HTTPField.Name: String] {
    var combinedFields = [HTTPField.Name: String](minimumCapacity: count)
    for field in self {
      if let existingValue = combinedFields[field.name] {
        let separator = field.name == .cookie ? ";" : ","
        combinedFields[field.name] = "\(existingValue)\(separator)\(field.value)"
      } else {
        combinedFields[field.name] = field.value
      }
    }
    return combinedFields
  }
  
  var headerFields: [String: String] {
    var headerFields = [String: String](minimumCapacity: combinedFields.count)
    for (name, value) in combinedFields {
      headerFields[name.rawName] = value
    }
    return headerFields
  }
}
