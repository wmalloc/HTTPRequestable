//
//  HTTPResponse+Error.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 10/24/24.
//

import Foundation
import HTTPTypes

public extension HTTPResponse {
  var error: (any Error)? {
    guard status.kind != .successful else { return nil }
    return URLError(URLError.Code(integerLiteral: status.code))
  }
}
