//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

public extension SecKey {
  var data: Data? {
    SecKeyCopyExternalRepresentation(self, nil) as? Data
  }
}

#endif
