//
//  HTTPField.Name+Common.swift
//
//  Created by Waqar Malik on 7/14/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPTypes

/// Extension providing convenience properties for commonly used HTTP header fields.
public extension HTTPField.Name {
  /// A predefined `HTTPField.Name` representing the `User-Authorization` header field.
  static var userAuthorization: HTTPField.Name {
    #HTTPFieldName("User-Authorization")
  }

  /// A predefined `HTTPField.Name` representing the `X-API-Key` header field.
  static var xAPIKey: HTTPField.Name {
    #HTTPFieldName("X-API-Key")
  }
}
