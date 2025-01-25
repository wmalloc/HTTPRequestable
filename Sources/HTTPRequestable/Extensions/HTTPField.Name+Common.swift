//
//  HTTPField.Name+Common.swift
//
//  Created by Waqar Malik on 7/14/23.
//

import Foundation
import HTTPTypes

/// Extension providing convenience properties for commonly used HTTP header fields.
public extension HTTPField.Name {
  /// A predefined `HTTPField.Name` representing the `User-Authorization` header field.
  static var userAuthorization: HTTPField.Name {
    .init("User-Authorization")!
  }

  /// A predefined `HTTPField.Name` representing the `X-API-Key` header field.
  static var xAPIKey: HTTPField.Name {
    .init("X-API-Key")!
  }
}
