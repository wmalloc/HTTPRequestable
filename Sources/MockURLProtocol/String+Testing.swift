//
//  String+Testing.swift
//
//  Created by Waqar Malik on 4/21/25.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

public extension String {
  /// A predefined `String` representing the `X-Test-Identifier` header field.
  @inlinable
  static var xTestIdentifier: Self {
    "X-Test-Identifier"
  }
}
