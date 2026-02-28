//
//  URLRequest+Modifier.swift
//
//  Created by Waqar Malik on 2/5/26.
//

import Foundation

public extension URLRequest {
  /// Applies an ordered collection of request modifiers and returns the resulting request.
  ///
  /// This method creates a mutable copy of `self`, iterates over the supplied collection, and
  /// invokes each modifier’s `modify(_:for:)` method in order. Because modifiers operate asynchronously,
  /// this function is `async` and propagates any thrown errors.
  ///
  /// - Parameter modifiers: A collection of types conforming to `HTTPRequestModifier`. Their order determines application order.
  /// - Returns: A new `URLRequest` instance that reflects all applied modifications.
  /// - Note: The `session` parameter is passed as `nil`. If a modifier requires session context, it should handle the absence of a session appropriately.
  ///
  func apply(_ modifiers: some Sequence<any HTTPRequestModifier>) async throws -> Self {
    var updatedRequest = self
    for modifier in modifiers {
      try await modifier.modify(&updatedRequest, for: nil)
    }
    return updatedRequest
  }
}
