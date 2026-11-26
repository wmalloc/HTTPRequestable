//
//  String+Testing.swift
//
//  Created by Waqar Malik on 4/21/25.
//

import Foundation
import HTTPTypes
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension String {
  /// The name of the `X-Mock-Identifier` header field.
  @inlinable
  static var xMockIdentifier: Self {
    HTTPField.Name.xMockIdentifier.rawName
  }
}
