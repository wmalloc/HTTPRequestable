//
//  HTTPFields+Transferable.swift
//
//
//  Created by Waqar Malik on 5/18/24.
//

import Foundation
import HTTPTypes

public extension HTTPFields {
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

  var combinedFields: [HTTPField.Name: String] {
    reduce(into: [:]) { $0[$1.name] = self[$1.name] }
  }

  var rawValue: [String: String] {
    var headerFields = [String: String](minimumCapacity: combinedFields.count)
    for (name, value) in combinedFields {
      headerFields[name.rawName] = value
    }
    return headerFields
  }
}
