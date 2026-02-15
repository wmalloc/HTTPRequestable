//
//  URLRequest+Modifier.swift
//
//  Created by Waqar Malik on 2/5/26.
//

import Foundation

public extension URLRequest {
  /// Applies an ordered collection of request modifiers and returns the
  /// resulting request.
  ///
  /// The method creates a mutable copy of `self`, iterates over the
  /// supplied collection, and invokes each modifier’s `modify(_:for:)`
  /// method.  Because the modifiers operate asynchronously, this
  /// function is marked `async` and propagates any thrown errors.
  ///
  /// - Parameters:
  ///   - modifiers: A collection of types conforming to
  ///     `HTTPRequestModifier`.  The order in which they appear is the
  ///     order of application.
  ///
  /// - Returns: A new `URLRequest` instance that has been modified by
  ///   every element in the collection.
  ///
  /// - Note: The `for` argument of each modifier is passed as `nil`
  ///   because the modifiers in this context do not require a
  ///   `URLSession`.  If a modifier needs the session, it should ignore
  ///   this argument or provide its own default behaviour.
  ///
  func apply(_ modifiers: any Collection<any HTTPRequestModifier>) async throws -> Self {
    var updatedRequest = self
    for modifier in modifiers {
      try await modifier.modify(&updatedRequest, for: nil)
    }
    return updatedRequest
  }
}
