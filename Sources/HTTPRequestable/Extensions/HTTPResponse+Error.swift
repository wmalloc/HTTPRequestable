//
//  HTTPResponse+Error.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 10/24/24.
//

import Foundation
import HTTPTypes

/// Extension providing a computed property for error in HTTP responses.
public extension HTTPResponse {
  /// A computed property that returns an optional error associated with the HTTP response, if any.
  /// - Returns: An optional `Error` object. If the status of the response is successful (`status.kind != .successful`),
  /// this method returns `nil`. Otherwise, it returns a custom `URLError` based on the status code of the response.
  var error: (any Error)? {
    guard status.kind != .successful else { return nil }
    return URLError(URLError.Code(rawValue: status.code))
  }
}
