//
//  URLRequest+Method.swift
//
//  Created by Waqar Malik on 7/12/23.
//

import Foundation
import HTTPTypes

public extension URLRequest {
  typealias Method = HTTPRequest.Method
}

public extension URLRequest {
  func value(forHTTPHeaderField field: HTTPField.Name) -> String? {
    value(forHTTPHeaderField: field.canonicalName) ?? value(forHTTPHeaderField: field.rawName)
  }

  mutating func setValue(_ value: String?, forHTTPHeaderField field: HTTPField.Name) {
    setValue(value, forHTTPHeaderField: field.rawName)
  }

  mutating func addValue(_ value: String, forHTTPHeaderField field: HTTPField.Name) {
    addValue(value, forHTTPHeaderField: field.rawName)
  }

  subscript(header key: String) -> String? {
    get {
      value(forHTTPHeaderField: key)
    }
    set {
      setValue(newValue, forHTTPHeaderField: key)
    }
  }

  subscript(field: HTTPField.Name) -> String? {
    get {
      value(forHTTPHeaderField: field)
    }
    set {
      setValue(newValue, forHTTPHeaderField: field)
    }
  }

  var contentType: String? {
    get {
      self[.contentType]
    }
    set {
      self[.contentType] = newValue
    }
  }

  var userAgent: String? {
    get {
      self[.userAgent]
    }
    set {
      self[.userAgent] = newValue
    }
  }
}
