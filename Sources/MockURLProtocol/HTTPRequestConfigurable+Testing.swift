//
//  HTTPRequestConfigurable+Testing.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 4/21/25.
//

import Foundation
import HTTPRequestable
import HTTPTypes

/// Adds a unique test‑identifier header to an ``HTTPRequestable``.
///
/// The method injects the `X-Test-Identifier` HTTP header with a freshly generated
/// UUID string.  This is useful in unit tests where you want every request to be
/// uniquely identifiable and then intercepted by :class:`MockURLProtocol`.
///
/// ```swift
/// let original = URLRequest(url: URL(string: "https://example.com")!)
/// let requestWithId = original.byAddingTestIdentifierHeader()
/// // requestWithId.headerFields[.xTestIdentifier] now contains a UUID string
/// ```
///
/// - Returns: A new instance of the conforming type with the header added.
///   The operation is value‑semantics safe – it does not mutate the receiver.
public extension HTTPRequestConfigurable {
  /// Adds an ``X-Test-Identifier`` header containing a random UUID to this request.
  ///
  /// The header key is provided by :enum:`HTTPHeaderField.xTestIdentifier`.
  /// If the request already contains any headers, they are preserved and
  /// only the `X-Test-Identifier` field is added or overwritten.
  ///
  /// - Returns: A copy of the request with the new header set.
  func byAddingTestIdentifierHeader() -> Self {
    var request = self
    var existing = request.headerFields ?? [:]
    existing[.xTestIdentifier] = UUID().uuidString
    request.headerFields = existing
    return request
  }

  /// The value of the ``X-Test-Identifier`` header, if present.
  ///
  /// This property is used by :class:`MockURLProtocol` and other utilities to
  /// identify a request at runtime.  If the header has not been set,
  /// `nil` is returned.
  var testIdentifier: String? {
    headerFields?[.xTestIdentifier]
  }
}
