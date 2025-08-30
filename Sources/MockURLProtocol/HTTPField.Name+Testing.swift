//
//  HTTPField.Name+Testing.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 4/21/25.
//

import Foundation
import HTTPTypes

extension HTTPField.Name {
  /// A predefined `HTTPField.Name` representing the `X-Test-Identifier` header field.
  static var xTestIdentifier: HTTPField.Name {
    .init(.xTestIdentifier)!
  }
}
