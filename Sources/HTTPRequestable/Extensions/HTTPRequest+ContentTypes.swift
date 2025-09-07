//
//  HTTPRequest+ContentTypes.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

import Foundation
import HTTPTypes

public extension HTTPRequest {
  /// The set of MIME types the request declares it accepts.
  ///
  /// If the `Accept` header is missing or empty, this property returns `nil`.
  var acceptContentTypes: Set<String>? {
    // Grab the raw header value (if any)
    guard let raw = headerFields[.accept] else { return nil }

    // Split on commas, trim whitespace, and drop empties
    let types = raw
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    return types.isEmpty ? nil : Set(types)
  }
}
