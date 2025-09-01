//
//  String+Testing.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 4/21/25.
//

import Foundation

public extension String {
  /// A predefined `String` representing the `X-Test-Identifier` header field.
  @inlinable
  static var xTestIdentifier: Self {
    "X-Test-Identifier"
  }
}
