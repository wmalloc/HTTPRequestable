//
//  SecKey+Trust.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

public extension SecKey {
  /// Retrieves the raw data representation of the key.
  ///
  /// - Returns: A `Data` object containing the raw key data, or `nil` if the key data cannot be extracted.
  ///
  /// This property uses `SecKeyCopyExternalRepresentation` to obtain the external representation
  /// of the key. Note that not all keys support external representation, and this method may return `nil`
  /// for such keys.
  var data: Data? {
    SecKeyCopyExternalRepresentation(self, nil) as? Data
  }
}

#endif
