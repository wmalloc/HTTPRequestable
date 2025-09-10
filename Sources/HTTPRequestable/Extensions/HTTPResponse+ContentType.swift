//
//  HTTPResponse+ContentType.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

import Foundation
import HTTPTypes

public extension HTTPResponse {
  /// The MIME types declared in the response’s `Content-Type` header.
  ///
  /// Returns `nil` if the header is missing, empty, or contains only whitespace.
  var contentTypes: Set<HTTPContentType>? {
    // Grab the raw value of the Content‑Type header (if any).
    guard let raw = headerFields[.contentType] else { return nil }

    // Split on commas, trim whitespace, and discard empties.
    let types = raw
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .map(HTTPContentType.init(rawValue:))

    // If the resulting array is empty, treat it as “no content‑types”.
    return types.isEmpty ? nil : Set(types)
  }
}
