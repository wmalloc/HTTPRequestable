//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 4/21/25.
//

import Foundation
import HTTPTypes

extension HTTPField.Name {
  /// A predefined `HTTPField.Name` representing the `X-API-Key` header field.
  static var testIdentifier: HTTPField.Name {
    .init(.testIdentifier)!
  }
}
