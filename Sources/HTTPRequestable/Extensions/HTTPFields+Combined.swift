//
//  HTTPFields+Combined.swift
//
//
//  Created by Waqar Malik on 5/18/24.
//

import Foundation
import HTTPTypes

public extension HTTPFields {
  var combinedFields: [HTTPField.Name: String] {
    reduce(into: [:]) { $0[$1.name] = self[$1.name] }
  }

  var headerFields: [String: String] {
    var headerFields = [String: String](minimumCapacity: combinedFields.count)
    for (name, value) in combinedFields {
      headerFields[name.rawName] = value
    }
    return headerFields
  }
}
