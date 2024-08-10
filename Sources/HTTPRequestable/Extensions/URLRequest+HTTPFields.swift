//
//  URLRequest+HTTPFields.swift
//
//  Created by Waqar Malik on 1/14/23.
//

import Foundation
import HTTPTypes

public extension URLRequest {
  @discardableResult
  func setHttpHeaderFields(_ fields: HTTPFields?) -> Self {
    var request = self
    request.headerFields = fields
    return request
  }

  @discardableResult
  func addHeaderFields(_ fields: HTTPFields) -> Self {
    var request = self
    for header in fields {
      request.addValue(header.value, forHTTPField: header.name)
    }
    return request
  }
}

public extension URLRequest {
  var headerFields: HTTPFields? {
    get {
      guard let allHTTPHeaderFields else {
        return nil
      }
      return HTTPFields(rawValue: allHTTPHeaderFields)
    }
    set {
      allHTTPHeaderFields = newValue?.rawValue
    }
  }
}

extension HTTPFields: RawRepresentable {
  public typealias RawValue = [String: String]

  public init?(rawValue: RawValue) {
    self.init()
    for (key, value) in rawValue {
      guard let name = HTTPField.Name(key) else {
        continue
      }
      self[name] = value
    }
  }

  public var rawValue: RawValue {
    var rawValues: RawValue = [:]
    for field in self {
      if let existingValue = rawValues[field.name.rawName] {
        let separator = field.name == .cookie ? "; " : ", "
        rawValues[field.name.rawName] = "\(existingValue)\(separator)\(field.value)"
      } else {
        rawValues[field.name.rawName] = field.value
      }
    }
    return rawValues
  }
}
