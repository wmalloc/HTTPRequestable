//
//  HTTPField.Name+Testing.swift
//
//  Created by Waqar Malik on 4/21/25.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif
import HTTPTypes

public extension HTTPField.Name {
  /// A predefined `HTTPField.Name` representing the `X-Test-Identifier` header field.
  @inlinable
  static var xTestIdentifier: HTTPField.Name {
    .init(.xTestIdentifier)!
  }
}
