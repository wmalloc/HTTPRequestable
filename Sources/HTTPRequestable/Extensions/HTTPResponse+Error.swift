//
//  HTTPResponse+Error.swift
//
//  Created by Waqar Malik on 10/24/24.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif
import HTTPTypes

/// Extension providing a computed property for error in HTTP responses.
public extension HTTPResponse {
  /// A computed property that returns an optional error associated with the HTTP response, if any.
  /// - Returns: `nil` when the response status is in the successful range; otherwise
  ///   ``HTTPError/unacceptableStatusCode(_:)`` carrying the response status.
  var error: (any Error)? {
    guard status.kind != .successful else { return nil }
    return HTTPError.unacceptableStatusCode(status)
  }
}
