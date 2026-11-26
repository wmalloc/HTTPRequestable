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
import HTTPTypes

public extension String {
  /// The name of the `X-Mock-Identifier` header field.
  @inlinable
  static var xMockIdentifier: Self {
    HTTPField.Name.xMockIdentifier.rawName
  }
}
