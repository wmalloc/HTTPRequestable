//
//  HTTPRequest+ContentTypes.swift
//
//  Created by Waqar Malik on 9/6/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPTypes

public extension HTTPRequest {
  /// The media ranges the request's `Accept` header lists, without their parameters.
  ///
  /// Commas inside quoted parameter values do not separate entries. Entries that are not valid media
  /// ranges, or whose `q` is invalid or `0` (not acceptable), are left out, so the set can be empty
  /// even though the header is set; nothing is then acceptable.
  ///
  /// Returns `nil` if the `Accept` header is missing or blank.
  var acceptContentTypes: Set<HTTPContentType>? {
    guard let raw = headerFields[.accept], !raw.trimmingCharacters(in: .whitespaces).isEmpty else {
      return nil
    }
    return Set(HTTPFieldValueSyntax.listElements(raw).compactMap(HTTPContentType.acceptedRange))
  }
}
