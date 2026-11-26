//
//  HTTPField.Name+Common.swift
//
//  Created by Waqar Malik on 7/14/23.
//

import Foundation
import HTTPTypes
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
