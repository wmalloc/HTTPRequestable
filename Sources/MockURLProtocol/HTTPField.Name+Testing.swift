//
//  HTTPField.Name+Testing.swift
//
//  Created by Waqar Malik on 4/21/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPRequestable
import HTTPTypes

public extension HTTPField.Name {
  /// The `X-Mock-Identifier` header field, which ``MockURLProtocol`` uses to find the handler for a request.
  @inlinable
  static var xMockIdentifier: HTTPField.Name {
    #HTTPFieldName("X-Mock-Identifier")
  }
}
